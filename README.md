# simple360player_iOS
Simple 360 Video player for iOS using SceneKit. VR ready. Stereoscopic Ready.

We generate a simple scene in which we add a sphere centered on the user point of view (i.e. the cameras in (0,0,0)).
Then we project a texture displaying a SpriteKit scene showing the video on the sphere material.

We added the ability to pan through the scene with swipes.

Play with the activateStereoscopicVideo Boolean to switch between flat and 3D Stereoscopic (top/bottom) video file

Just remove the rightScene to have a non-VR video 360 Video player.

Hope this will be useful.

- Swipe up/down to move the camera
- Button to reset the position of the camera
- Cardboard on/off button
- Steroscopic Top/Bottom video compatible
- Play/Pause
- Slider to control playback position
- Perf adjusted dependant on the device CPU architecture

![alt tag](https://github.com/Aralekk/simple360player_iOS/blob/master/S1.PNG)

## Other platforms

To check how to build a HTML5 simple360Player, check out this project: https://github.com/gbentaieb/simple360Player

## Full VR Toolkit

You can find a basic VR toolkit for iOS in SceneKit Swift 2.0 here: https://github.com/Aralekk/VR_Toolkit_iOS
