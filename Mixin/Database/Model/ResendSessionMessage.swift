import Foundation
import WCDBSwift

struct ResendSessionMessage: BaseCodable {

    static var tableName: String = "resend_session_messages"

    let messageId: String
    let userId: String
    let sessionId: String
    let status: Int

    enum CodingKeys: String, CodingTableKey {
        typealias Root = ResendSessionMessage
        case messageId = "message_id"
        case userId = "user_id"
        case sessionId = "session_id"
        case status

        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        static var tableConstraintBindings: [TableConstraintBinding.Name: TableConstraintBinding]? {
            return  [
                "_multi_primary": MultiPrimaryBinding(indexesBy: messageId, userId, sessionId)
            ]
        }
    }
}
