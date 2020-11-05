// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable file_length
fileprivate func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case let (lValue?, rValue?):
        return compare(lValue, rValue)
    case (nil, nil):
        return true
    default:
        return false
    }
}

fileprivate func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (idx, lhsItem) in lhs.enumerated() {
        guard compare(lhsItem, rhs[idx]) else { return false }
    }

    return true
}


// MARK: - AutoEquatable for classes, protocols, structs
// MARK: - SessionServiceState AutoEquatable
extension SessionServiceState: Equatable {}
public func == (lhs: SessionServiceState, rhs: SessionServiceState) -> Bool {
    guard lhs.authState == rhs.authState else { return false }
    guard compareOptionals(lhs: lhs.identityToken, rhs: rhs.identityToken, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.authorizationCode, rhs: rhs.authorizationCode, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.state, rhs: rhs.state, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.user, rhs: rhs.user, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.fullName, rhs: rhs.fullName, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.email, rhs: rhs.email, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.realUserStatus, rhs: rhs.realUserStatus, compare: ==) else { return false }
    return true
}

// MARK: - AutoEquatable for Enums
