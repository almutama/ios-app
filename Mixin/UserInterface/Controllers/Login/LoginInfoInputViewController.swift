import UIKit

class LoginInfoInputViewController: ContinueButtonViewController {
    
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var trimmedText: String {
        return textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    convenience init() {
        self.init(nib: R.nib.loginInfoInputView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if ScreenSize.current == .inch3_5 {
            contentStackView.spacing = 30
        }
        textField.becomeFirstResponder()
        editingChangedAction(self)
    }
    
    @IBAction func editingChangedAction(_ sender: Any) {
        continueButton.isHidden = trimmedText.isEmpty
    }
    
}
