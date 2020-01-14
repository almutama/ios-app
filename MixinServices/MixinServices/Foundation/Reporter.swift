import Foundation
import Bugsnag

open class Reporter {
    
    public typealias UserInfo = [String: Any]
    
    public enum Event {
        case signUp
        case login
        case sendSticker
        case openApp
        
        public var name: String {
            switch self {
            case .signUp:
                return "sign_up"
            case .login:
                return "login"
            case .sendSticker:
                return "send_sticker"
            case .openApp:
                return "open_app"
            }
        }
    }
    
    public var basicUserInfo: UserInfo {
        ["last_update_or_install_date": AppGroupUserDefaults.User.lastUpdateOrInstallDate,
         "client_time": DateFormatter.filename.string(from: Date())]
    }
    
    public required init() {
        #if RELEASE
        if let path = Bundle.mixinServicesResource.path(forResource: "ApiKeys", ofType: "plist"), let keys = NSDictionary(contentsOfFile: path) as? [String: Any], let key = keys["Bugsnag"] as? String {
            Bugsnag.start(withApiKey: key)
        }
        #endif
    }
    
    open func registerUserInformation() {
        guard let account = LoginManager.shared.account else {
            return
        }
        Bugsnag.configuration()?.setUser(account.user_id, withName: account.full_name , andEmail: account.identity_number)
    }
    
    open func report(event: Event, userInfo: UserInfo? = nil) {
        
    }
    
    open func report(error: Error) {
        Bugsnag.notifyError(error)
    }
    
    open func reportErrorToFirebase(_ error: Error) {
        
    }
    
}
