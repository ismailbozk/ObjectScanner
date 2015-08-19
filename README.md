Purpose
--------------

Object Scanner is a portion of [my thesis](https://github.com/ismailbozk/kinectObjectScanner) project, written in C++, Objective-C and Swift. 

The whole purpose of this project is exploring the GPGPU and graphics programming on Metal Api.

Summary
----------------

The following steps are followed in this project.

  * Calibrating the rgb-depth frame and creating point cloud by using Metal compute shader.
  * Creating the transformation matrix on consecutive frames (No error management.)
  * Presenting the consecutive point clouds on the screen by using the Metal vertex and fragment shaders.

![Main screen](https://github.com/ismailbozk/ObjectScanner/blob/screenshots/screenshots/IMG_0070.PNG)
 
Acknowledgements
----------------

This project is portion of my Master Thesis project, you can check the whole project in [here](https://github.com/ismailbozk/kinectObjectScanner).

This project is developed by using the following articles/projects and the Computer Vision algorithms that I used in the master thesis.

* [MetalByExample](http://metalbyexample.com/)
* [Apple Matel Docs](https://developer.apple.com/metal/)
* [iOS-OpenCV-FaceRec](https://github.com/ekurutepe/iOS-OpenCV-FaceRec)

Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 8.2,  Xcode 7 beta 5
* iOS Devices with A7 or higher chip. (Metal doesn't work on simulators)

Data Types
--------------

This project simulates the and RGB-Depth camera and provides and UIImage as an rgb frame and a float array as an depth frame. (Array indices are corresponds to [y * image.width + x])
Test data can be found under the [!TestData directory](https://github.com/ismailbozk/ObjectScanner/tree/master/ObjectScanner/ObjectScanner/Resources/TestData).
