//
//  ViewController.swift
//  colab-session
//
//  Created by Artur Pinkevych on 01/08/2024.
//

import UIKit
import RealityKit
import ARKit
import MultipeerConnectivity

let modelNames = ["chair", "toaster", "toy", "tricycle"]
let selectedModelName =  modelNames.randomElement()

class ViewController: UIViewController, ARSessionDelegate {
    @IBOutlet var arView: ARView!
    @IBOutlet weak var restartButton: UIButton!
    
    var multiuserSession: MultiuserSession?

    var sessionIds = [MCPeerID: String]()
    var sessionIdObservation: NSKeyValueObservation?
    
    var config: ARWorldTrackingConfiguration?
    var modelMap = [String: Entity]()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            for modelName in modelNames {
                let model = try! ModelEntity.load(named: "\(modelName).usdz")

                self.modelMap[modelName] = model
            }
        }

        arView.session.delegate = self
        arView.automaticallyConfigureSession = false
        
        config = ARWorldTrackingConfiguration()

        config?.isCollaborationEnabled = true
        config?.environmentTexturing = .automatic

        arView.session.run(config!)
        
        ServerAPI.shared.getAnchors { [weak self] anchors in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.placeAnchors(anchors)
            }
        }
        
        sessionIdObservation = observe(\.arView.session.identifier, options: [.new]) { object, change in
            print("SessionID changed to: \(change.newValue!)")
            guard let multiuserSession = self.multiuserSession else { return }
            self.broadcastSessionId(to: multiuserSession.connectedUsers)
        }
        
        multiuserSession = MultiuserSession(onReceive: handleReceive, onJoin: handleJoin, onQuit: handleQuit)
        
        UIApplication.shared.isIdleTimerDisabled = true

        let click = UITapGestureRecognizer(target: self, action: #selector(handleClick(source:)))
        arView.addGestureRecognizer(click)
        
    }
    
    func placeAnchors(_ anchors: [AnchorData]?) {
        guard let anchors = anchors else { return }
        for anchorData in anchors {
            let anchor = ARAnchor(name: anchorData.name, transform: anchorData.transform)
            arView.session.add(anchor: anchor)
        }
    }
    
    
    @objc func handleClick(source: UITapGestureRecognizer) {
        let location = source.location(in: arView)
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        if let firstResult = results.first {
            let anchor = ARAnchor(name: selectedModelName!, transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
            
            ServerAPI.shared.addAnchor(anchor: anchor) { success in
                if success {
                    print("Anchor successfully sent to server.")
                } else {
                    print("Failed to send anchor to server.")
                }
            }
        } else {
            print("Warning: Object placement failed.")
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor.name != nil && modelNames.contains(anchor.name!) {
                let anchorEntity = AnchorEntity(anchor: anchor)
                let model = self.modelMap[anchor.name!]?.clone(recursive: true)
                anchorEntity.addChild(model!)
                arView.scene.addAnchor(anchorEntity)
            }
        }
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multiuserSession = multiuserSession else { return }
        if !multiuserSession.connectedUsers.isEmpty {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else { fatalError("Unexpectedly failed to encode collaboration data.") }
            let dataIsCritical = data.priority == .critical
            multiuserSession.broadcastToEveryone(encodedData, reliably: dataIsCritical)
        } else {
            print("No one in the session")
        }
    }

    func handleReceive(_ data: Data, from user: MCPeerID) {
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            arView.session.update(with: collaborationData)
            return
        }
        let sessionIdCommandString = "SessionID:"
        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIdCommandString) {
            let newSessionId = String(commandString[commandString.index(commandString.startIndex,
                                                                     offsetBy: sessionIdCommandString.count)...])
            if let oldSessionId = sessionIds[user] {
                clearAnchors(from: oldSessionId)
            }
            
            sessionIds[user] = newSessionId
        }
    }
    
    func handleJoin(_ user: MCPeerID) {
        broadcastSessionId(to: [user])
    }
        
    func handleQuit(_ user: MCPeerID) {
        if let sessionID = sessionIds[user] {
            clearAnchors(from: sessionID)
            sessionIds.removeValue(forKey: user)
        }
    }
    
    func clearAnchors(from sessionID: String) {
        if let currentFrame = arView.session.currentFrame {
            currentFrame.anchors
                .filter { $0.sessionIdentifier?.uuidString == sessionID }
                .forEach { arView.session.remove(anchor: $0) }
        }
    }
    
    func broadcastSessionId(to users: [MCPeerID]) {
        guard let multiuserSession = multiuserSession else { return }
        let sessionIdString = arView.session.identifier.uuidString
        let message = "SessionID:\(sessionIdString)"
        if let messageData = message.data(using: .utf8) {
            multiuserSession.broadcastToSpecific(messageData, reliably: true, users: users)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        self.resetTracking()
        print(error)
    }
    
    @IBAction func resetTracking() {
        guard let configuration = arView.session.configuration else { print("A configuration is required"); return }
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    

}
