// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

extension SessionRequestAction {
    public var start: Void? {
        get {
            guard case .start = self else { return nil }
            return ()
        }
    }

    public var isStart: Bool {
        self.start != nil
    }

    public var stop: Void? {
        get {
            guard case .stop = self else { return nil }
            return ()
        }
    }

    public var isStop: Bool {
        self.stop != nil
    }

    public var refresh: Void? {
        get {
            guard case .refresh = self else { return nil }
            return ()
        }
    }

    public var isRefresh: Bool {
        self.refresh != nil
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

    public var status: SessionServiceState? {
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
