import Foundation
import RxSwift
import MultipeerConnectivity

// The protocol that adapters must adhere to.
// We want a concise common interface for p2p related operations.
public protocol Session {

  typealias I

  var iden: I { get }
  var meta: [String: String]? { get }

  // Connection concerns
  //////////////////////////////////////////////////////////////////////////

  func connectedPeer() -> Observable<I>
  func disconnectedPeer() -> Observable<I>
  func incomingConnections() -> Observable<(I, [String: AnyObject]?, (Bool) -> ())>
  func nearbyPeers() -> Observable<[(I, [String: String]?)]>
  func startAdvertising()
  func stopAdvertising()
  func startBrowsing()
  func stopBrowsing()
  func connect(peer: I, context: [String: AnyObject]?, timeout: NSTimeInterval)
  func disconnect()
  func connectionErrors() -> Observable<NSError>

  // Data reception concerns
  //////////////////////////////////////////////////////////////////////////

  func receive() -> Observable<(I, NSData)>
  func receive() -> Observable<(I, String, ResourceState)>

  // Data delivery concerns
  //////////////////////////////////////////////////////////////////////////

  func send
  (other: I,
   _ data: NSData,
   _ mode: MCSessionSendDataMode)
  -> Observable<()>

  func send
  (other: I,
   name: String,
   url: NSURL,
   _ mode: MCSessionSendDataMode)
  -> Observable<()>

}
