import UIKit

class SignalLoadingViewController: UIViewController {
    
    class func instance() -> SignalLoadingViewController {
        return Storyboard.home.instantiateViewController(withIdentifier: "signal") as! SignalLoadingViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FileManager.default.writeLog(log: "SignalLoadingView...")
        let startTime = Date()
        DispatchQueue.global().async {
            try! SignalDatabase.shared.initDatabase()

            self.syncSignalKeys()
            self.syncSession()

            DispatchQueue.main.async {
                let time = Date().timeIntervalSince(startTime)
                if time < 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (2 - time), execute: {
                        self.dismiss()
                    })
                } else {
                    self.dismiss()
                }
            }
        }
    }

    private func syncSignalKeys() {
        guard !CryptoUserDefault.shared.isLoaded else {
            return
        }

        IdentityDAO.shared.saveLocalIdentity()

        repeat {
            guard AccountAPI.shared.didLogin else {
                return
            }
            switch SignalKeyAPI.shared.pushSignalKeys(key: try! PreKeyUtil.generateKeys()) {
            case .success:
                CryptoUserDefault.shared.isLoaded = true
                DispatchQueue.main.async {
                    MixinWebView.clearCookies()
                }
                return
            case let .failure(error):
                guard error.code != 401 else {
                    return
                }
                Thread.sleep(forTimeInterval: 2)
                UIApplication.traceError(error)
            }
        } while true
    }

    private func syncSession() {
        guard !CryptoUserDefault.shared.isSyncSession else {
            return
        }

        AccountUserDefault.shared.extensionSession = nil
        JobDAO.shared.clearSessionJob()
        let sessions = SessionDAO.shared.syncGetSessionAddress()
        let userIds = sessions.compactMap { $0.address }

        repeat {
            guard AccountAPI.shared.didLogin else {
                return
            }

            switch UserAPI.shared.fetchSessions(userIds: userIds) {
            case let .success(remoteSessions):
                defer {
                    CryptoUserDefault.shared.isSyncSession = true
                }
                var sessionMap = [String: Int32]()
                var userSessionMap = [String: String]()
                remoteSessions.forEach { (session) in
                    if session.platform == "Android" || session.platform == "iOS" {
                        sessionMap[session.userId] = SignalProtocol.convertSessionIdToDeviceId(session.sessionId)
                        userSessionMap[session.userId] = session.sessionId
                    }
                }

                guard sessionMap.count > 0 else {
                    return
                }

                var newSession = [Session]()
                sessions.forEach { (session) in
                    if let deviceId = sessionMap[session.address] {
                        newSession.append(Session(address: session.address, device: Int(deviceId), record: session.record, timestamp: session.timestamp))
                    }
                }
                SignalDatabase.shared.insertOrReplace(objects: newSession)

                let senderKeys = SenderKeyDAO.shared.syncGetSenderKeys()
                senderKeys.forEach { (key) in
                    if key.senderId.hasSuffix(":1") {
                        let userId = String(key.senderId.prefix(key.senderId.count - 2))
                        if let deviceId = sessionMap[userId] {
                            SenderKeyDAO.shared.insertOrReplace(obj: SenderKey(groupId: key.groupId, senderId: "\(userId):\(deviceId)", record: key.record))
                        }
                    }
                }

                let participants = ParticipantDAO.shared.getAllParticipants()
                let participantSessions: [ParticipantSession] = participants.compactMap {
                    guard let sessionId = userSessionMap[$0.userId] else {
                        return nil
                    }
                    return ParticipantSession(conversationId: $0.conversationId, userId: $0.userId, sessionId: sessionId, sentToServer: nil, createdAt: Date().toUTCString())
                }
                MixinDatabase.shared.insertOrReplace(objects: participantSessions)
                return
            case let .failure(error):
                guard error.code != 401 else {
                    return
                }
                Thread.sleep(forTimeInterval: 2)
                UIApplication.traceError(error)
            }
        } while true
    }
    
    private func dismiss() {
        AppDelegate.current.window.rootViewController = makeInitialViewController()
    }
    
}
