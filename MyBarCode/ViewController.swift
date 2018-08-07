

import UIKit
import AVFoundation

class ViewController: UIViewController , AVCaptureMetadataOutputObjectsDelegate , AVCapturePhotoCaptureDelegate{

    @IBOutlet weak var ImageView: UIImageView!
    
    let supportedType: [AVMetadataObject.ObjectType] =
    [.qr, .code128 , .code39, .code93, .upce, .pdf417 , .ean13, .aztec]
    
    var session : AVCaptureSession?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var cameraOutput : AVCapturePhotoOutput?
    
    
    
    @IBAction func scanBtnPressed(_ sender: UIButton) {
        
        // Prepare Input       輸入的裝置是video
        guard let captureDevice = AVCaptureDevice.default(for: .video) else{
            print("Fail to create captureDevice.")
            return
        }//捕捉裝置
        
        guard let inputDevice = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Fail ti create inoutDevice")
            return  }//設為輸入裝置
        
        // Prepare Session
        session = AVCaptureSession()
        session?.addInput(inputDevice)  //輸入可以有好幾個      添加
        // Prepare output
        let metadateOutput = AVCaptureMetadataOutput()
        session?.addOutput(metadateOutput)
        
        metadateOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        //加入後面會回報給self
        metadateOutput.metadataObjectTypes = supportedType //指定型態
        
        cameraOutput = AVCapturePhotoOutput()
        session?.addOutput(cameraOutput!)
        
        // Prepare preview  還沒掃到東西 相機的預覽畫面
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)//session 所收到的影像
        previewLayer?.videoGravity = .resizeAspectFill  // 改掉原本的4:3
        previewLayer?.frame = CGRect(origin: .zero, size: ImageView.frame.size)//佔滿
        ImageView.layer.addSublayer(previewLayer!)
        
        // Sart Capture.
        session?.startRunning()
        ImageView.image = nil   //避免瞬間的重疊
        
    }
    
    
    // mark AVCaptureMetadataOutputObjectsDelegate protocol Methods.
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        //metadataObjects: [AVMetadataObject] 輸出是多組  但通常只掃一組
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
//            assertionFailure("Invalid mtadataObject")
            return  }
        
        guard let content = metadataObject.stringValue else {
            print("metadataObject.stringValue is nil")
            return  }
        
        output.setMetadataObjectsDelegate(nil, queue: nil)//停止回報  避免重複 跳出alert
        
        //Output image
        let settings = AVCapturePhotoSettings()
        settings.isAutoDualCameraFusionEnabled = true
        cameraOutput?.capturePhoto(with: settings, delegate: self)

        //Show Alert with cotent.       放的位置可以改
        
        let alert = UIAlertController(title: metadataObject.type.rawValue, message: content, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(ok)
        present(self, animated: true, completion: nil)
        
    }
    
    
    //AVCapturePhotoCaptureDelegate protocol Methods.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {//didFinishProcessingPhotoSampleBuffer 10之前 用的方法
        
        defer {   //函數執行完後 開始清除 狀態      多處出口都會清除狀態
            //Clean up!
            session?.stopRunning()
            session = nil
            
            previewLayer?.removeFromSuperlayer()//不移除掉 會佔記憶體
            previewLayer = nil
            
            cameraOutput = nil
        }
        
        
        if let error = error {
            print("didFinishProcessingPhoto error: \(error)")
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            assertionFailure("Fail to get photo data")
            return  }
        
        ImageView.image = UIImage(data: data)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

