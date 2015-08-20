import Foundation
import RxSwift
import MultipeerConnectivity

public class MockSession : Session {

  public typealias I = MockIden

  // Store all available sessions in a global
  static public var sessions: [MockSession] = [] {
    didSet { digest() }
  }

  static public let advertisingSessions: Variable<[MockSession]> = Variable([])

  static public func digest() {
      advertisingSessions.next(sessions.filter { $0.isAdvertising })
  }

  static public func findForClient(client: I) -> MockSession? {
    return filter(sessions, { o in return o.iden == client }).first
  }

  static public func reset() {
    self.sessions = []
  }

  let _iden: I
  public var iden: I { return _iden }

  let _meta: [String: String]?
  public var meta: [String: String]? { return _meta }

  public init(name: String, meta: [String: String]? = nil) {
    self._iden = I(name)
    self._meta = meta
    MockSession.sessions.append(self)
  }

  // Connection concerns
  //////////////////////////////////////////////////////////////////////////

  var _connections: [MockSession] = []

  var isAdvertising = false {
    didSet { MockSession.digest() }
  }

  var isBrowsing = false {
    didSet { MockSession.digest() }
  }

  let connectRequests: PublishSubject<(I, [String: AnyObject]?, (Bool) -> ())> = PublishSubject()

  let rx_connectedPeer: PublishSubject<I> = PublishSubject()

  public func connectedPeer() -> Observable<I> {
    return rx_connectedPeer
  }

  let rx_disconnectedPeer: PublishSubject<I> = PublishSubject()

  public func disconnectedPeer() -> Observable<I> {
    return rx_disconnectedPeer
  }

  public func nearbyPeers() -> Observable<[(I, [String: String]?)]> {
    return MockSession.advertisingSessions
           >- filter { _ in self.isBrowsing }
           >- map { $0.map { ($0.iden, $0.meta) } }
  }

  public func incomingConnections() -> Observable<(I, [String: AnyObject]?, (Bool) -> ())> {
    return connectRequests >- filter { _ in self.isAdvertising }
  }

  public func startBrowsing() {
    self.isBrowsing = true
  }

  public func stopBrowsing() {
    self.isBrowsing = false
  }

  public func startAdvertising() {
    self.isAdvertising = true
  }

  public func stopAdvertising() {
    self.isAdvertising = false
  }

  public func connect(peer: I, context: [String: AnyObject]? = nil, timeout: NSTimeInterval = 12) {
    let otherm = filter(MockSession.sessions, { return $0.iden == peer }).first
    if let other = otherm {
      // Skip if already connected
      if self._connections.filter({
        $0.iden == other.iden
      }).count > 0 { return }

      if other.isAdvertising {
        sendNext(
          other.connectRequests,
          (self.iden,
           context,
           { [weak self] (response: Bool) in
             if !response { return }
             if let this = self {
               this._connections.append(other)
               other._connections.append(this)
               sendNext(this.rx_connectedPeer, other.iden)
               sendNext(other.rx_connectedPeer, this.iden)
             }
           }) as (I, [String: AnyObject]?, (Bool) -> ()))
      }
    }
  }

  public func disconnect() {
    self._connections = []
    MockSession.sessions = MockSession.sessions.filter { $0.iden != self.iden }
    for session in MockSession.sessions {
      for c in session._connections {
        if c.iden == self.iden {
          sendNext(session.rx_disconnectedPeer, c.iden)
        }
      }
      session._connections = session._connections.filter { $0.iden != self.iden }
    }
  }

  public func connectionErrors() -> Observable<NSError> {
    return PublishSubject()
  }

  // Data reception concerns
  //////////////////////////////////////////////////////////////////////////

  let receivedData: PublishSubject<(I, NSData)> = PublishSubject()
  let receivedResources: PublishSubject<(I, String, ResourceState)> = PublishSubject()

  public func receive() -> Observable<(I, NSData)> {
    return receivedData
  }

  public func receive() -> Observable<(I, String, ResourceState)> {
    return receivedResources
  }

  // Data delivery concerns
  //////////////////////////////////////////////////////////////////////////

  func isConnected(other: MockSession) -> Bool {
    return filter(_connections, { $0.iden == other.iden }).first != nil
  }

  public func send
  (other: I,
   _ data: NSData,
   _ mode: MCSessionSendDataMode)
  -> Observable<()> {
    return create { observer in
      if let otherSession = MockSession.findForClient(other) {
        // Can't send if not connected
        if !self.isConnected(otherSession) {
          sendError(observer, UnknownError)
        } else {
          sendNext(otherSession.receivedData, (self.iden, data))
          sendCompleted(observer)
        }
      } else {
        sendError(observer, UnknownError)
      }

      return AnonymousDisposable {}
    }
  }

  public func send
  (other: I,
   name: String,
   url: NSURL,
   _ mode: MCSessionSendDataMode)
  -> Observable<()> {
    return create { observer in
      if let otherSession = MockSession.findForClient(other) {
        // Can't send if not connected
        if !self.isConnected(otherSession) {
          sendError(observer, UnknownError)
        } else {
          let c = self.iden
          sendNext(otherSession.receivedResources, (c, name, .Progress(NSProgress(totalUnitCount: 1))))
          sendNext(otherSession.receivedResources, (c, name, .Finished(url)))
          sendCompleted(observer)
        }
      } else {
        sendError(observer, UnknownError)
      }

      return AnonymousDisposable {}
    }
  }

}

public class MockIden : Equatable {

  public let string: String

  public var displayName: String {
    return string
  }

  public init(_ string: String) {
    self.string = string
  }

  convenience public init(displayName: String) {
    self.init(displayName)
  }

}

public func ==(left: MockIden, right: MockIden) -> Bool {
  return left.string == right.string
}
