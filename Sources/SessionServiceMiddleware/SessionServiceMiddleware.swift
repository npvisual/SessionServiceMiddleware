import Foundation
import os.log
import SwiftRex

// MARK: - ACTIONS

//sourcery: Prism
public enum SessionServiceAction {
    case request(SessionRequestAction)
    case status(SessionServiceState)
}

//sourcery: Prism
public enum SessionRequestAction {
    case start(String)
    case validate
    case stop
    case refresh
    case reset
}

// MARK: - STATE
public struct SessionServiceState: Equatable {

    public var status: SessionStatus
    public var uid: String?
    public var start: Date?
    public var refresh: Date?

    public enum SessionStatus: Equatable {
        case valid
        case terminated
        case undefined
    }
    
    public static let empty: SessionServiceState = .init(status: .undefined)

}

// MARK: - MIDDLEWARE
public final class SessionServiceMiddleware: Middleware {
    public typealias InputActionType = SessionServiceAction
    public typealias OutputActionType = SessionServiceAction
    public typealias StateType = SessionServiceState

    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SessionServicesMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    private var getState: GetState<StateType> = { StateType(status: .undefined) }
    
    public init() { }
    
    public func receiveContext(getState: @escaping GetState<StateType>, output: AnyActionHandler<OutputActionType>) {
        self.output = output
        self.getState = getState
    }

    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer : inout AfterReducer
    ) {
        // Actions to be handled BEFORE the reducer pipeline gets to mutate the global state.
        os_log(
            "Handling actions before the reducer...",
            log: SessionServiceMiddleware.logger,
            type: .debug
        )
        switch action {
            case .request(.validate):
                var state = getState()
                if state.uid != nil {
                    state.status = .valid
                    state.start = Date()
                } else {
                    state = SessionServiceState(status: .undefined)
                }
                output?.dispatch(.status(state))
            case .request(.refresh):
                var state = getState()
                state.refresh = Date()
                output?.dispatch(.status(state))
            case .request(.stop):
                output?.dispatch(.status(SessionServiceState(status: .terminated)))
            case .request(.reset):
                output?.dispatch(.status(SessionServiceState(status: .undefined)))
            default: break
        }
    }
}

// MARK: - REDUCER
extension Reducer where ActionType == SessionServiceAction, StateType == SessionServiceState {
    public static let session = Reducer { action, state in
        var state = state
        switch action {
            case let .request(.start(id)):
                state.uid = id
            case let .status(value):
                state = value
            default: break
        }
        return state
    }
}
