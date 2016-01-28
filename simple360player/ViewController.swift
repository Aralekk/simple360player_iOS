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
    
    @IBOutlet weak var leftSceneView : SCNView!
    @IBOutlet weak var rightSceneView : SCNView!
    @IBOutlet weak var playButton : UIButton!
    @IBOutlet weak var playerSlideBar : UISlider!
    
    var scene : SCNScene?
    
    var videoNode : SCNNode?
    var videoSpriteKitNode : SKVideoNode?
    var player : AVPlayer!
    
    var camerasNode : SCNNode?
    var cameraRollNode : SCNNode?
    var cameraPitchNode : SCNNode?
    var cameraYawNode : SCNNode?
    
    var recognizer : UITapGestureRecognizer?
    var panRecognizer: UIPanGestureRecognizer?
    var motionManager : CMMotionManager?
    
    var playingVideo : Bool = false
    
    var currentAngleX : Float?
    var currentAngleY : Float?
    
    var progressObserver : AnyObject?
    
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
        
        let camerasNodeAngles = getCamerasNodeAngle()
        camerasNode!.eulerAngles = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
        
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
        
        // Add gestures on screen
        recognizer = UITapGestureRecognizer(target: self, action:Selector("tapTheScreen"))
        recognizer!.delegate = self
        view.addGestureRecognizer(recognizer!)
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: "panGesture:")
        view.addGestureRecognizer(panRecognizer!)
        currentAngleX = 0
        currentAngleY = 0
        
        play()
    }

    
    //MARK: Camera Orientation methods
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let camerasNodeAngles = getCamerasNodeAngle()
        camerasNode!.eulerAngles = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
    }
    
    func getCamerasNodeAngle() -> [Double] {
        var camerasNodeAngle1: Double! = 0.0
        var camerasNodeAngle2: Double! = 0.0
        let orientation = UIApplication.sharedApplication().statusBarOrientation.rawValue
        if orientation == 1 {
            camerasNodeAngle1 = -M_PI_2
        } else if orientation == 2 {
            camerasNodeAngle1 = M_PI_2
        } else if orientation == 3 {
            camerasNodeAngle1 = 0.0
            camerasNodeAngle2 = M_PI
        }
        
        return [ -M_PI_2, camerasNodeAngle1, camerasNodeAngle2 ]
    }
    
    
    //Mark: video player methods
    func play(){
        
        //let fileURL: NSURL? = NSURL(string: "http://www.kolor.com/360-videos-files/noa-neal-graffiti-360-music-video-full-hd.mp4")
        let fileURL: NSURL? = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("vr", ofType: "mp4")!)
        
        if (fileURL != nil){
            
            player = AVPlayer(URL: fileURL!)
            
            videoSpriteKitNode =  SKVideoNode(AVPlayer: player)
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
            
            progressObserver = player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC)),
                queue: nil,
                usingBlock: { [unowned self] (time) -> Void in
                    self.updateSliderProgression()
                })
            
            playPausePlayer()
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
    
    @IBAction func playPausePlayer() {
        if true == playingVideo {
            videoSpriteKitNode!.pause()
        } else {
            videoSpriteKitNode!.play()
        }
        
        playingVideo = !playingVideo
        playButton.setImage(UIImage(named: (true == playingVideo) ? "pause@3x.png" : "play@3x.png"), forState: .Normal)
    }
    
    //Mark: action methods
    func tapTheScreen(){
        // Action when the screen is tapped
        stopPlay()
    }
    
    func panGesture(sender: UIPanGestureRecognizer){
        //getting the CGpoint at the end of the pan
        let translation = sender.translationInView(sender.view!)
        
        var newAngleX = Float(translation.x)
        
        //current angle is an instance variable so i am adding the newAngle to it
        newAngleX = newAngleX + currentAngleX!
        videoNode!.eulerAngles.y = -newAngleX/100
        
        //getting the end angle of the swipe put into the instance variable
        if(sender.state == UIGestureRecognizerState.Ended) {
            currentAngleX = newAngleX
        }
    }
    
    
    //Mark: Render the scenes
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval){
        
        // Render the scene
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let mm = self.motionManager, let motion = mm.deviceMotion {
                let currentAttitude = motion.attitude
                
                var roll : Double = currentAttitude.roll
                if(UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight){ roll = -1.0 * (-M_PI - roll)}
                
                self.cameraRollNode!.eulerAngles.x = Float(roll)
                self.cameraPitchNode!.eulerAngles.z = Float(currentAttitude.pitch)
                self.cameraYawNode!.eulerAngles.y = Float(currentAttitude.yaw)
                
            }
        }
    }
    
    // MARK: Slider method
    private func updateSliderProgression() {
        let playerDuration = self.playerItemDuration()
        if CMTIME_IS_INVALID(playerDuration) {
            playerSlideBar.minimumValue = 0.0
            return;
        }
        
        let duration = Float(CMTimeGetSeconds(playerDuration))
        if isfinite(duration) && (duration > 0) {
            let minValue            = playerSlideBar.minimumValue
            let maxValue            = playerSlideBar.maximumValue
            let time                = Float(CMTimeGetSeconds(player.currentTime()))
            
            playerSlideBar.value    = (maxValue - minValue) * time / duration + minValue
        }
    }
    
    private func playerItemDuration() -> CMTime {
        let thePlayerItem = player.currentItem
        
        if AVPlayerItemStatus.ReadyToPlay == thePlayerItem?.status {
            return thePlayerItem?.duration ?? kCMTimeInvalid
        }
        
        return kCMTimeInvalid
    }
    
    @IBAction func sliderChangeProgression(sender: UISlider) {
        let playerDuration = self.playerItemDuration()
        
        if CMTIME_IS_INVALID(playerDuration) {
            return;
        }
        
        let duration = Float(CMTimeGetSeconds(playerDuration))
        if isfinite(duration) && (duration > 0) {
            print(duration,Float64(duration) * Float64(playerSlideBar.value))
            player.seekToTime(CMTimeMakeWithSeconds(Float64(duration) * Float64(playerSlideBar.value), 60000))
            playPausePlayer()
        }
    }
    
    @IBAction func sliderStartSliding(sender: AnyObject) {
        videoSpriteKitNode!.pause()
        playingVideo = false
        playButton.setImage(UIImage(named: (true == playingVideo) ? "pause@3x.png" : "play@3x.png"), forState: .Normal)
    }
    
    //MARK: Clean Methods
    
    deinit {
        motionManager?.stopDeviceMotionUpdates()
        motionManager = nil
        
        if let observer = progressObserver {
            player.removeTimeObserver(observer)
        }
        
        playingVideo = false
        
        self.videoSpriteKitNode?.removeFromParent()
        
        for node in scene!.rootNode.childNodes {
            removeNode(node)
        }
    }
    
    func removeNode(node : SCNNode) {
        for node in node.childNodes {
            removeNode(node)
        }
        
        if 0 == node.childNodes.count {
            node.removeFromParentNode()
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

