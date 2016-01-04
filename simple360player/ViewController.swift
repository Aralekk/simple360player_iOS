//
//  ViewController.swift
//  simple360player
//
//  Created by Arthur Swiniarski on 04/01/16.
//  Copyright © 2016 Arthur Swiniarski. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import SpriteKit
import AVFoundation
import Foundation
import Darwin
import CoreGraphics

// utility functions
func degreesToRadians(degrees: Float) -> Float {
    return (degrees * Float(M_PI)) / 180.0
}

// ViewController
class ViewController: UIViewController, SCNSceneRendererDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var leftSceneView: SCNView!
    @IBOutlet weak var rightSceneView: SCNView!
    
    var scene : SCNScene?
    
    var videoNode : SCNNode?
    var videoSpriteKitNode : SKVideoNode?
    
    var camerasNode : SCNNode?
    var cameraRollNode : SCNNode?
    var cameraPitchNode : SCNNode?
    var cameraYawNode : SCNNode?
    
    var recognizer : UITapGestureRecognizer?
    var panRecognizer: UIPanGestureRecognizer?
    var motionManager : CMMotionManager?
    
    var playingVideo:Bool = false
    
    var currentAngleX:Float?
    var currentAngleY:Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leftSceneView?.backgroundColor = UIColor.blackColor()
        rightSceneView?.backgroundColor = UIColor.whiteColor()
        
        // Create Scene
        scene = SCNScene()
        leftSceneView?.scene = scene
        rightSceneView?.scene = scene
        
        // Create cameras
        let camX = 0.0 as Float
        let camY = 0.0 as Float
        let camZ = 0.0 as Float
        let zFar = 50.0
        
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        
        leftCamera.zFar = zFar
        rightCamera.zFar = zFar
        
        let leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: camX - 0.5, y: camY, z: camZ)
        
        let rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: camX + 0.5, y: camY, z: camZ)
        
        camerasNode = SCNNode()
        camerasNode!.position = SCNVector3(x: camX, y:camY, z:camZ)
        camerasNode!.addChildNode(leftCameraNode)
        camerasNode!.addChildNode(rightCameraNode)
        
        camerasNode!.eulerAngles = SCNVector3Make(degreesToRadians(-90.0), 0, 0)
        
        cameraRollNode = SCNNode()
        cameraRollNode!.addChildNode(camerasNode!)
        
        cameraPitchNode = SCNNode()
        cameraPitchNode!.addChildNode(cameraRollNode!)
        
        cameraYawNode = SCNNode()
        cameraYawNode!.addChildNode(cameraPitchNode!)
        
        scene!.rootNode.addChildNode(cameraYawNode!)
        
        leftSceneView?.pointOfView = leftCameraNode
        rightSceneView?.pointOfView = rightCameraNode
        
        // Respond to user head movement. Refreshes the position of the camera 60 times per second.
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical)
        
        leftSceneView?.delegate = self
        
        leftSceneView?.playing = true
        rightSceneView?.playing = true
        
        // Add gesture on screen
        recognizer = UITapGestureRecognizer(target: self, action:Selector("tapTheScreen"))
        recognizer!.delegate = self
        view.addGestureRecognizer(recognizer!)
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: "panGesture:")
        view.addGestureRecognizer(panRecognizer!)
        currentAngleX = 0
        currentAngleY = 0
        
        play()
        
    }
    
    func play(){
        
        //let fileURL: NSURL? = NSURL(string: "http://www.kolor.com/360-videos-files/noa-neal-graffiti-360-music-video-full-hd.mp4")
        let fileURL: NSURL? = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("vr", ofType: "mp4")!)
        
        if (fileURL != nil){
            videoSpriteKitNode =  SKVideoNode(AVPlayer: AVPlayer(URL: fileURL!))
            videoNode = SCNNode()
            videoNode!.geometry = SCNSphere(radius: 30)
            
            let spriteKitScene = SKScene(size: CGSize(width: 2500, height: 2500))
            spriteKitScene.scaleMode = .AspectFit
            
            videoSpriteKitNode!.position = CGPoint(x: spriteKitScene.size.width / 2.0, y: spriteKitScene.size.height / 2.0)
            videoSpriteKitNode!.size = spriteKitScene.size
            
            spriteKitScene.addChild(videoSpriteKitNode!)
            
            videoNode!.geometry?.firstMaterial?.diffuse.contents = spriteKitScene
            videoNode!.geometry?.firstMaterial?.doubleSided = true
            
            // Flip video upside down, so that it's shown in the right position
            var transform = SCNMatrix4MakeRotation(Float(M_PI), 0.0, 0.0, 1.0)
            transform = SCNMatrix4Translate(transform, 1.0, 1.0, 0.0)
            
            videoNode!.pivot = SCNMatrix4MakeRotation(Float(M_PI_2), 0.0, -1.0, 0.0)
            videoNode!.geometry?.firstMaterial?.diffuse.contentsTransform = transform
            videoNode!.position = SCNVector3(x: 0, y: 0, z: 0)
            
            scene!.rootNode.addChildNode(videoNode!)
            videoSpriteKitNode!.play()
            
            playingVideo = true
            
        }
        
    }
    
    func stopPlay(){
        
        if (playingVideo){
            videoSpriteKitNode!.pause()
        }else{
            
            videoSpriteKitNode!.play()
        }
        
        playingVideo = !playingVideo
        
    }
    
    func tapTheScreen(){
        // Action when the screen is tapped
    }
    
    func panGesture(sender: UIPanGestureRecognizer){
        //getting the CGpoint at the end of the pan
        let translation = sender.translationInView(sender.view!)
        
        var newAngleX = Float(translation.x)
        
        //current angle is an instance variable so i am adding the newAngle to the newAngle to it
        newAngleX = newAngleX + currentAngleX!
        videoNode!.eulerAngles.y = -newAngleX/100
        
        //getting the end angle of the swipe put into the instance variable
        if(sender.state == UIGestureRecognizerState.Ended) {
            currentAngleX = newAngleX
        }
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval){
        
        // Render the scene
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let mm = self.motionManager, let motion = mm.deviceMotion {
                let currentAttitude = motion.attitude
                
                var orientationMultiplier = 1.0
                if(UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight){ orientationMultiplier = -1.0}
                
                self.cameraRollNode!.eulerAngles.x = Float(currentAttitude.roll * orientationMultiplier)
                self.cameraPitchNode!.eulerAngles.z = Float(currentAttitude.pitch)
                self.cameraYawNode!.eulerAngles.y = Float(currentAttitude.yaw)
                
            }
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

