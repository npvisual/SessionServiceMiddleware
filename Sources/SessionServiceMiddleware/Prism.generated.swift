// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import AuthenticationServices
extension SessionRequestAction {
    public var login: Void? {
        get {
            guard case .login = self else { return nil }
            return ()
        }
    }

    public var isLogin: Bool {
        self.login != nil
    }

    public var logout: Void? {
        get {
            guard case .logout = self else { return nil }
            return ()
        }
    }

    public var isLogout: Bool {
        self.logout != nil
    }

    public var reset: Void? {
        get {
            guard case .reset = self else { return nil }
            return ()
        }
    }

    public var isReset: Bool {
        self.reset != nil
    }

}
extension SessionServiceAction {
    public var request: SessionRequestAction? {
        get {
            guard case let .request(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .request = self, let newValue = newValue else { return }
            self = .request(newValue)
        }
    }

    public var isRequest: Bool {
        self.request != nil
    }

    public var status: SessionStatusAction? {
        get {
            guard case let .status(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .status = self, let newValue = newValue else { return }
            self = .status(newValue)
        }
    }

    public var isStatus: Bool {
        self.status != nil
    }

}
extension SessionStatusAction {
    public var valid: Void? {
        get {
            guard case .valid = self else { return nil }
            return ()
        }
    }

    public var isValid: Bool {
        self.valid != nil
    }

    public var terminated: Void? {
        get {
            guard case .terminated = self else { return nil }
            return ()
        }
    }

    public var isTerminated: Bool {
        self.terminated != nil
    }

    public var undefined: Void? {
        get {
            guard case .undefined = self else { return nil }
            return ()
        }
    }

    public var isUndefined: Bool {
        self.undefined != nil
    }

    public var registered: Void? {
        get {
            guard case .registered = self else { return nil }
            return ()
        }
    }

    public var isRegistered: Bool {
        self.registered != nil
    }

    public var error: Error? {
        get {
            guard case let .error(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .error = self, let newValue = newValue else { return }
            self = .error(newValue)
        }
    }

    public var isError: Bool {
        self.error != nil
    }

}
