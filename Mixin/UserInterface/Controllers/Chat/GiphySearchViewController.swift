import UIKit
import GiphyCoreSDK

class GiphySearchViewController: UIViewController {
    
    @IBOutlet weak var keywordTextField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewLayout: GiphyCollectionViewFlowLayout!
    
    weak var dataSource: ConversationDataSource?
    
    var onDisappear: (() -> Void)?
    
    private let limit = 24
    
    private var status = Status.loading
    private var images = [GiphyImage]()
    private var isLoadingMore = false
    private var animated: Bool = false {
        didSet {
            for case let cell as AnimatedImageCollectionViewCell in collectionView.visibleCells {
                cell.imageView.autoPlayAnimatedImage = animated
                if animated {
                    cell.imageView.startAnimating()
                } else {
                    cell.imageView.stopAnimating()
                }
            }
        }
    }
    
    private weak var lastGiphyOperation: Operation?
    
    private lazy var reloadHandler = { [weak self] (response: GPHListMediaResponse?, error: Error?) in
        guard let weakSelf = self, let data = response?.data else {
            return
        }
        let images = data.compactMap(GiphyImage.init)
        DispatchQueue.main.async {
            weakSelf.status = images.isEmpty ? .noResult : .loading
            weakSelf.images = images
            weakSelf.collectionView.reloadData()
        }
    }
    
    private lazy var loadMoreHandler = { [weak self] (response: GPHListMediaResponse?, error: Error?) in
        guard let weakSelf = self, let data = response?.data else {
            return
        }
        let images = data.compactMap(GiphyImage.init)
        DispatchQueue.main.async {
            if images.isEmpty {
                weakSelf.status = .noMoreResult
                weakSelf.collectionView.reloadData()
            } else {
                let indexPaths = (weakSelf.images.count..<(weakSelf.images.count + images.count))
                    .map({ IndexPath(row: $0, section: 0) })
                weakSelf.images.append(contentsOf: images)
                weakSelf.collectionView.insertItems(at: indexPaths)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        transitioningDelegate = PopupPresentationManager.shared
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePreferredContentSizeHeight()
        keywordTextField.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(AnimatedImageCollectionViewCell.self,
                                forCellWithReuseIdentifier: ReuseId.cell)
        collectionView.register(UINib(nibName: "LoadingIndicatorFooterView", bundle: .main),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: ReuseId.Footer.loading)
        collectionView.register(UINib(nibName: "NoResultFooterView", bundle: .main),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: ReuseId.Footer.noResult)
        collectionView.register(UINib(nibName: "GiphyPoweredFooterView", bundle: .main),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: ReuseId.Footer.giphyPowered)
        collectionView.dataSource = self
        collectionView.delegate = self
        reload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.animated = true
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lastGiphyOperation?.cancel()
        self.animated = false
        onDisappear?()
    }
    
    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updatePreferredContentSizeHeight()
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension GiphySearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        lastGiphyOperation?.cancel()
        if let keyword = keywordTextField.text, !keyword.isEmpty {
            search(keyword)
        } else {
            reload()
        }
        return false
    }
    
}

extension GiphySearchViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseId.cell, for: indexPath) as! AnimatedImageCollectionViewCell
        cell.imageView.contentMode = .scaleAspectFill
        let url = images[indexPath.row].previewUrl
        cell.imageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerReuseId, for: indexPath)
    }
    
}

extension GiphySearchViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = images[indexPath.row]
        let cell = collectionView.cellForItem(at: indexPath) as? AnimatedImageCollectionViewCell
        dataSource?.send(image: image, thumbnail: cell?.imageView.image)
        dismissAction(collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AnimatedImageCollectionViewCell else {
            return
        }
        if animated {
            cell.imageView.autoPlayAnimatedImage = true
            cell.imageView.startAnimating()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AnimatedImageCollectionViewCell else {
            return
        }
        cell.imageView.autoPlayAnimatedImage = false
        cell.imageView.stopAnimating()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        guard !images.isEmpty && elementKind == UICollectionView.elementKindSectionFooter && lastGiphyOperation == nil else {
            return
        }
        if let keyword = keywordTextField.text, !keyword.isEmpty {
            lastGiphyOperation = GiphyCore.shared.search(keyword, offset: images.count, limit: limit, lang: .current, completionHandler: loadMoreHandler)
        } else {
            lastGiphyOperation = GiphyCore.shared.trending(offset: images.count, limit: limit, completionHandler: loadMoreHandler)
        }
    }
    
}

extension GiphySearchViewController {
    
    enum Status {
        case noResult
        case loading
        case noMoreResult
    }
    
    enum ReuseId {
        
        static let cell = "cell"
        
        enum Footer {
            static let loading = "loading"
            static let noResult = "no_result"
            static let giphyPowered = "giphy"
        }
        
    }
    
    private var footerReuseId: String {
        switch status {
        case .noResult:
            return ReuseId.Footer.noResult
        case .loading:
            return ReuseId.Footer.loading
        case .noMoreResult:
            return ReuseId.Footer.giphyPowered
        }
    }
    
    private func updatePreferredContentSizeHeight() {
        guard let window = AppDelegate.current.window else {
            return
        }
        preferredContentSize.height = window.bounds.height - window.compatibleSafeAreaInsets.top - 56
    }
    
    private func prepareCollectionViewForReuse() {
        status = .loading
        collectionView.setContentOffset(.zero, animated: false)
        images = []
        collectionView.reloadData()
    }
    
    private func reload() {
        prepareCollectionViewForReuse()
        lastGiphyOperation = GiphyCore.shared.trending(limit: limit, completionHandler: reloadHandler)
    }
    
    private func search(_ keyword: String) {
        prepareCollectionViewForReuse()
        lastGiphyOperation = GiphyCore.shared.search(keyword, limit: limit, lang: .current, completionHandler: reloadHandler)
    }
    
}
