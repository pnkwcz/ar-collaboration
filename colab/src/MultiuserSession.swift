//
//  MultiuserSession.swift
//  colab-session
//
//  Created by Artur Pinkevych on 01/08/2024.
//

import MultipeerConnectivity

class MultiuserSession: NSObject {
    static let serviceType = "my-cool-app"
    
    private let id = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession!
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    private let onReceive: (Data, MCPeerID) -> Void
    private let onJoin: (MCPeerID) -> Void
    private let onQuit: (MCPeerID) -> Void

    init(onReceive: @escaping (Data, MCPeerID) -> Void,
         onJoin: @escaping (MCPeerID) -> Void,
         onQuit: @escaping (MCPeerID) -> Void) {
        self.onReceive = onReceive
        self.onJoin = onJoin
        self.onQuit = onQuit
        
        super.init()
        
        session = MCSession(peer: id, securityIdentity: nil, encryptionPreference: .required)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: id, discoveryInfo: nil, serviceType: MultiuserSession.serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: id, serviceType: MultiuserSession.serviceType)
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    func broadcastToEveryone(_ data: Data, reliably: Bool) {
        broadcastToSpecific(data, reliably: reliably, users: connectedUsers)
    }
    
    func broadcastToSpecific(_ data: Data, reliably: Bool, users: [MCPeerID]) {
        guard !users.isEmpty else { return }
        do {
            try session.send(data, toPeers: users, with: reliably ? .reliable : .unreliable)
        } catch {
            print("error occured")
        }
    }
    
    var connectedUsers: [MCPeerID] {
        return session.connectedPeers
    }
}

extension MultiuserSession: MCSessionDelegate {
    
    func session(_ session: MCSession, peer userId: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            onJoin(userId)
        } else if state == .notConnected {
            onQuit(userId)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer userId: MCPeerID) {
        onReceive(data, userId)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
}

extension MultiuserSession: MCNearbyServiceBrowserDelegate {
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer userId: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(userId, to: session, withContext: nil, timeout: 10)
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer userId: MCPeerID) {
        // noop
    }
    
}

extension MultiuserSession: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer userId: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
}
