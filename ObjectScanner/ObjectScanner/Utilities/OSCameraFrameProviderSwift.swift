//
//  OSCameraAccessFrameProvider.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

//import Cocoa
import UIKit

struct DepthFrame {
    let rows : Int, cols : Int
    var depthFrame : [Float];
    
    init(rows : Int, cols : Int){
        self.rows = rows;
        self.cols = cols;
        self.depthFrame = [Float](count: rows * cols, repeatedValue: -1.0);
    }
    
    func indexIsValidForRow(row: Int, col: Int) -> Bool {
        return row >= 0 && row < rows && col >= 0 && col < cols
    }
    
    subscript(row : Int, col : Int) -> Float{
        get {
            assert(indexIsValidForRow(row, col: col), "Index out of range")
            return self.depthFrame[(row * cols) + col];
        }
        set(newValue) {
            assert(indexIsValidForRow(row, col: col), "Index out of range")
            self.depthFrame[(row * cols) + col] = newValue;
        }
    }
}

class OSCameraFrameProviderSwift : OSCameraFrameProvider, OSContentLoadingProtocol{
    
    static let sharedInstance = OSCameraFrameProviderSwift();
    
    weak var delegate : OS3DFrameConsumerProtocol?;
    
    var depthFrames : [DepthFrame] = [DepthFrame]();

    enum imageSize:Int{
        case width = 640
        case height = 480
    }
    
// MARK: Publics
    
    override func prepareFramesWithCompletion(completion: (() -> Void)!) {
        super.prepareFramesWithCompletion({[unowned self] () -> Void in
            let startTime = CACurrentMediaTime();

            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("father1"));
            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("father2"));
            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("father3"));
            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("father4"));
            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("father5"));

            let elapsedTime : CFTimeInterval = CACurrentMediaTime() - startTime;
            
            print("depth frames read in \(elapsedTime) seconds")

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion();
            })
        });
    }
    
    func startSimulatingFrameCaptures() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), { () -> Void in
            self.broadcastFrameAtIndex(0, toIndex: self.depthFrames.count - 1, completion: nil);
        });
    }
    
// MARK: Utilities
    
    func broadcastFrameAtIndex(index : Int, toIndex : Int, completion: (() -> Void)?)
    {
        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
            self.delegate?.didCapturedFrame(self.images[index] as! UIImage, depthFrame: self.depthFrames[index].depthFrame);
        });
        
        NSThread.sleepForTimeInterval(32.6 / 1000);//30 fps
        
        if (index == toIndex)
        {
            completion?();
        }
        else
        {
            self.broadcastFrameAtIndex(index+1, toIndex: toIndex, completion: completion);
        }
    }
    
    class private func stringForFile(fileName:String, fileExtension:String) -> String?{
        let pathToFile : String! = NSBundle.mainBundle().pathForResource(fileName, ofType: fileExtension);
        var fileString  : String?
        do {
            fileString = try String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        } catch _ {
            fileString = nil
        };

        return fileString;
    }
    
    class private func depthFrameForFile (prefix:String) -> DepthFrame{
        let resourceFileName:String = String(format: "%@Depth", prefix);
        let fileString = self.stringForFile(resourceFileName, fileExtension: "csv");
        
        if (fileString == nil)
        {
            NSLog("Error reading file");
        }
    
        let depthValues : [String] = fileString!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString:"\n;"));

        let count = (imageSize.height.rawValue * imageSize.width.rawValue);
        
        var df : DepthFrame = DepthFrame(rows: imageSize.height.rawValue, cols: imageSize.width.rawValue);
        assert(count == depthValues.count , "depthFile and image size must be equal");
        
        var x: Int, y : Int, depth :Float;
        for (var i : Int = 0; i < count; i++)
        {
            x = i % imageSize.width.rawValue;
            y = i / imageSize.width.rawValue;
            depth = (depthValues[i] as NSString).floatValue;
            df[y, x] = depth;
        }
        
        return df;
    }
    
// MARK: OSContentLoadingProtocol
    
    static func loadContent(completionHandler : (() -> Void)!)
    {
        self.sharedInstance.prepareFramesWithCompletion(completionHandler);
    }
}
