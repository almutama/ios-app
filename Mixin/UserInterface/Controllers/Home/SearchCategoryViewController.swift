import UIKit

class SearchCategoryViewController: UIViewController, SearchableViewController {
    
    enum Category {
        case asset
        case user
        case group
        case conversation
        
        var title: String {
            switch self {
            case .asset:
                return R.string.localizable.search_section_title_asset()
            case .user:
                return R.string.localizable.search_section_title_user()
            case .group:
                return R.string.localizable.search_section_title_group()
            case .conversation:
                return R.string.localizable.search_section_title_conversation()
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    let cancelButton = SearchCancelButton()
    
    var category = Category.asset
    var inheritedKeyword: Keyword?
    
    var wantsNavigationSearchBox: Bool {
        return true
    }
    
    var navigationSearchBoxInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: backButtonWidth, bottom: 0, right: cancelButton.frame.width + cancelButtonRightMargin)
    }
    
    private let queue = OperationQueue()
    
    private var lastKeyword: Keyword?
    private var models = [[Any]]()
    
    deinit {
        queue.cancelAllOperations()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.maxConcurrentOperationCount = 1
        navigationItem.title = " "
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        searchTextField.text = inheritedKeyword?.raw
        searchTextField.addTarget(self, action: #selector(searchAction(_:)), for: .editingChanged)
        searchTextField.delegate = self
        switch category {
        case .asset:
            tableView.register(R.nib.assetCell)
        case .user, .group, .conversation:
            tableView.register(R.nib.searchResultCell)
        }
        let headerView = SearchHeaderView()
        headerView.label.text = category.title
        headerView.button.isHidden = true
        headerView.isFirstSection = true
        headerView.frame.size = CGSize(width: tableView.bounds.width, height: 36)
        tableView.tableHeaderView = headerView
        tableView.dataSource = self
        tableView.delegate = self
        searchAction(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchTextField.addTarget(self, action: #selector(searchAction(_:)), for: .editingChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.text = lastKeyword?.raw
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
        searchTextField.removeTarget(self, action: #selector(searchAction(_:)), for: .editingChanged)
    }
    
    @objc func searchAction(_ sender: Any) {
        queue.cancelAllOperations()
        guard let keyword = self.keyword else {
            models = []
            tableView.reloadData()
            lastKeyword = nil
            return
        }
        guard keyword != lastKeyword else {
            return
        }
        let category = self.category
        let op = BlockOperation()
        op.addExecutionBlock { [unowned op, weak self] in
            let trimmedKeyword = keyword.trimmed
            let models: [Any]
            switch category {
            case .asset:
                models = AssetDAO.shared.getAssets(keyword: trimmedKeyword, limit: nil)
                    .map { AssetSearchResult(asset: $0, keyword: trimmedKeyword) }
            case .user:
                models = UserDAO.shared.getUsers(keyword: trimmedKeyword, limit: nil)
                    .map { SearchResult(user: $0, keyword: trimmedKeyword) }
            case .group:
                models = ConversationDAO.shared.getGroupConversation(nameLike: trimmedKeyword, limit: nil)
                    .map { SearchResult(group: $0, keyword: trimmedKeyword) }
            case .conversation:
                models = ConversationDAO.shared.getConversation(withMessageLike: trimmedKeyword, limit: nil)
            }
            guard !op.isCancelled, self != nil else {
                return
            }
            DispatchQueue.main.sync {
                guard !op.isCancelled, let weakSelf = self else {
                    return
                }
                weakSelf.models = [models]
                weakSelf.tableView.reloadData()
                weakSelf.lastKeyword = keyword
            }
        }
        queue.addOperation(op)
    }
    
    @objc func cancelAction() {
        navigationController?.popViewController(animated: true)
    }
    
}

extension SearchCategoryViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}

extension SearchCategoryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if models.isEmpty {
            return 0
        } else {
            return models[section].count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section][indexPath.row]
        switch category {
        case .asset:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.asset, for: indexPath)!
            let asset = (model as! AssetSearchResult).asset
            cell.render(asset: asset)
            return cell
        case .user, .group, .conversation:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.search_result, for: indexPath)!
            let result = model as! SearchResult
            cell.render(result: result)
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }
    
}

extension SearchCategoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = models[indexPath.section][indexPath.row]
        switch category {
        case .asset:
            let asset = (model as! AssetSearchResult).asset
            pushAssetViewController(asset: asset)
        case .user, .group, .conversation:
            pushViewController(keyword: keyword, result: model as! SearchResult)
        }
    }
    
}