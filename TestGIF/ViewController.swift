//
//  ViewController.swift
//  TestGIF
//
//  Created by kkkelicheng on 2022/5/20.
//

import UIKit
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

class ViewController: UIViewController {

    @IBAction func doClipGif(_ sender: UIButton) {
        readGifImage()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    func readGifImage(){
        guard
        let bunder = Bundle.main.path(forResource: "test2", ofType: "gif"),
        let gifData = try? Data.init(contentsOf: URL.init(fileURLWithPath: bunder))
        else {
            print("get gif data error")
            return
        }
        guard let imageRefSource = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            print("create gif image source error")
            return
        }
        let gifFrameCount = CGImageSourceGetCount(imageRefSource)
        var container : [UIImage] = []
        for index in 0..<gifFrameCount {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let destinationPath = documentsPath + "/image\(index).jpg"
            if let cgImage = CGImageSourceCreateImageAtIndex(imageRefSource, index, nil) {
                let uiImage = UIImage.init(cgImage: cgImage)
                if let clipedUIImage = clipImage(uiImage,path: destinationPath) {
                    container.append(clipedUIImage)
                }
                else {
                    print("create clipd image error")
                }
            }
            else {
                print("create cgImage error")
            }
        }
        print("content of images : \(container.count)")
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let destinationPath = documentsPath + "/imageAnimated.gif"
        print("gif path : \(destinationPath)")
        let url = URL.init(fileURLWithPath: destinationPath)
        generateGifFromImages(imagesArray: container, frameDelay: 1.0 / 20, destinationURL: url) { data, error in
            if error != nil {
                print("\(String(describing: error?.localizedDescription))")
            }
        }
        
    }
    
    func clipImage(_ image:UIImage,path:String) -> UIImage? {
        let size = CGSize.init(width: 120, height: 120)
        let offset : CGFloat = 0
        let originRect = CGRect.init(origin: .zero, size: size)
        let insetRect = originRect.inset(by: UIEdgeInsets.init(top: offset, left: offset, bottom: offset, right: offset))
        UIGraphicsBeginImageContext(size)
        let b = UIBezierPath.init(ovalIn: insetRect)
        b.addClip()
        image.draw(in: originRect)
        let clipedImage = UIGraphicsGetImageFromCurrentImageContext()
        let data = clipedImage?.jpegData(compressionQuality: 1)
        let url = URL.init(fileURLWithPath: path)
        try? data?.write(to: url)
        UIGraphicsEndImageContext()
        return clipedImage
    }
    
    open func generateGifFromImages(imagesArray:[UIImage], repeatCount: Int = 0, frameDelay: TimeInterval, destinationURL: URL, callback:@escaping (_ data: Data?, _ error: NSError?) -> ()) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async { () -> Void in
            
            if let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypeGIF , imagesArray.count, nil) {
                
                let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: frameDelay]] as CFDictionary
                let gifProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: repeatCount]] as CFDictionary
                CGImageDestinationSetProperties(imageDestination, gifProperties)
                for image in imagesArray {
                    CGImageDestinationAddImage(imageDestination, image.cgImage!, frameProperties)
                }
                
                if CGImageDestinationFinalize(imageDestination) {
                    
                    do {
                        let data = try Data(contentsOf: destinationURL)
                        callback(data, nil)
                    } catch {
                        callback(nil, error as NSError)
                    }

                } else {
                    callback(nil, self.errorFromString("Couldn't create the final image"))
                }
            }
        }
    }

    fileprivate func errorFromString(_ string: String, code: Int = -1) -> NSError {
        let dict = [NSLocalizedDescriptionKey: string]
        return NSError(domain: "org.cocoapods.GIFGenerator", code: code, userInfo: dict)
    }
}

