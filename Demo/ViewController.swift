//
//  ViewController.swift
//  Demo
//
//  Created by Tommaso Rosso on 08/03/18.
//  Copyright © 2018 Tommaso Rosso. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var parentNode : SCNNode?
    
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    
    func initializeScene() {
        guard let virtualObjectScene = SCNScene(named: "art.scnassets/my_wonderful_scene.scn") else {
            return
        }
        let wrapperNode = SCNNode()
        
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            child.movabilityHint = .movable
            wrapperNode.addChildNode(child)
        }
        
        self.parentNode = wrapperNode.childNode(withName: "parent", recursively: true)
        parentNode?.isHidden = true
        sceneView.scene.rootNode.addChildNode(parentNode!)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeScene()
        setUpGesturesToSceneView()
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.antialiasingMode = .multisampling2X
        sceneView.session.run(configuration)
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        
        updateQueue.async {
            
            let plane = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)

            let planeNode = SCNNode(geometry: plane)

            planeNode.opacity = 0.1
            
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
            
            if let parentNode = self.parentNode {
                parentNode.position = planeNode.position
                parentNode.isHidden = false
                node.addChildNode(parentNode)
                
            }
            
        }
       
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // gestures
    
    var pinchGesture : UIPinchGestureRecognizer!
    var oldPinchValue = Float()
    var oldScale = SCNVector3()
    
    func setUpGesturesToSceneView() {
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(scale))
        pinchGesture.scale = 1.0;
        pinchGesture.delegate = self
        self.sceneView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func scale(_ gesture: UIPinchGestureRecognizer) {
        if let parentNode = self.parentNode {
            parentNode.scale = SCNVector3(x: CGFloat(gesture.scale), y: CGFloat(gesture.scale), z: CGFloat(gesture.scale))
        }
    }
}
