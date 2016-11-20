//
//  OSCameraAccessFrameProvider.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Ismail Bozkurt
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

//import Cocoa
import UIKit

struct DepthFrame {
    let rows : Int, cols : Int
    var depthFrame : [Float];
    
    init(rows : Int, cols : Int){
        self.rows = rows;
        self.cols = cols;
        self.depthFrame = [Float](repeating: -1.0, count: rows * cols);
    }
    
    func indexIsValidForRow(_ row: Int, col: Int) -> Bool {
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
    
    override func prepareFrames(completion: (() -> Void)!) {
        super.prepareFrames(completion: {[unowned self] () -> Void in
            let startTime = CACurrentMediaTime();

//            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("boxes1"));
            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("boxes2"));
//            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("boxes3"));
            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("boxes4"));
//            self.depthFrames.append(OSCameraFrameProviderSwift.depthFrameForFile("boxes5"));

            let elapsedTime : CFTimeInterval = CACurrentMediaTime() - startTime;
            
            print("depth frames read in \(elapsedTime) seconds")

            DispatchQueue.main.async(execute: { () -> Void in
                completion();
            })
        });
    }
    
    func startSimulatingFrameCaptures() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async(execute: { () -> Void in
            self.broadcastFrameAtIndex(0, toIndex: self.depthFrames.count - 1, completion: nil);
        });
    }
    
// MARK: Utilities
    
    func broadcastFrameAtIndex(_ index : Int, toIndex : Int, completion: (() -> Void)?)
    {
        DispatchQueue.main.sync(execute: { () -> Void in
            self.delegate?.didCapturedFrame(self.images[index] as! UIImage, depthFrame: self.depthFrames[index].depthFrame);
        });
        
        Thread.sleep(forTimeInterval: 32.6 / 1000);//30 fps
        
        if (index == toIndex)
        {
            completion?();
        }
        else
        {
            self.broadcastFrameAtIndex(index+1, toIndex: toIndex, completion: completion);
        }
    }
    
    class fileprivate func stringForFile(_ fileName:String, fileExtension:String) -> String?{
        let pathToFile : String! = Bundle.main.path(forResource: fileName, ofType: fileExtension);
        var fileString  : String?
        do {
            fileString = try String(contentsOfFile: pathToFile, encoding: String.Encoding.utf8)
        } catch _ {
            fileString = nil
        };

        return fileString;
    }
    
    class fileprivate func depthFrameForFile (_ prefix:String) -> DepthFrame{
        let resourceFileName:String = String(format: "%@Depth", prefix);
        let fileString = self.stringForFile(resourceFileName, fileExtension: "csv");
        
        if (fileString == nil)
        {
            NSLog("Error reading file");
        }
    
        let depthValues : [String] = fileString!.components(separatedBy: CharacterSet(charactersIn:"\n;"));

        let count = (imageSize.height.rawValue * imageSize.width.rawValue);
        
        var df : DepthFrame = DepthFrame(rows: imageSize.height.rawValue, cols: imageSize.width.rawValue);
        assert(count == depthValues.count , "depthFile and image size must be equal");
        
        var x: Int, y : Int, depth :Float;
        for i in 0..<count {
            x = i % imageSize.width.rawValue;
            y = i / imageSize.width.rawValue;
            depth = (depthValues[i] as NSString).floatValue;
            df[y, x] = depth;
        }
        
        return df;
    }
    
// MARK: OSContentLoadingProtocol
    
    static func loadContent(_ completionHandler : (() -> Void)!)
    {
        self.sharedInstance.prepareFrames(completion: completionHandler);
    }
}
