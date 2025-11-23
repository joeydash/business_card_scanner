import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup method channel for text recognition
    let controller = window?.rootViewController as! FlutterViewController
    let textRecognitionChannel = FlutterMethodChannel(
      name: "text_recognition",
      binaryMessenger: controller.binaryMessenger
    )
    
    textRecognitionChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "recognizeText" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["path"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                            message: "Image path is required",
                            details: nil))
          return
        }
        
        self?.recognizeText(imagePath: imagePath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Setup method channel for file sharing
    let shareChannel = FlutterMethodChannel(
      name: "native_share",
      binaryMessenger: controller.binaryMessenger
    )
    
    shareChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "shareFile" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["path"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                            message: "File path is required",
                            details: nil))
          return
        }
        
        let subject = args["subject"] as? String
        let text = args["text"] as? String
        self?.shareFile(filePath: filePath, subject: subject, text: text, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func shareFile(filePath: String, subject: String?, text: String?, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: filePath)
    
    // Check if file exists
    guard FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(code: "FILE_NOT_FOUND",
                        message: "File not found at path: \(filePath)",
                        details: nil))
      return
    }
    
    var itemsToShare: [Any] = [fileURL]
    if let text = text {
      itemsToShare.insert(text, at: 0)
    }
    
    DispatchQueue.main.async {
      let controller = self.window?.rootViewController as! FlutterViewController
      let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
      
      // For iPad - set popover presentation
      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = controller.view
        popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
      }
      
      activityVC.completionWithItemsHandler = { _, completed, _, error in
        if let error = error {
          result(FlutterError(code: "SHARE_ERROR",
                            message: "Share failed: \(error.localizedDescription)",
                            details: nil))
        } else {
          result(completed)
        }
      }
      
      controller.present(activityVC, animated: true, completion: nil)
    }
  }
  
  private func recognizeText(imagePath: String, result: @escaping FlutterResult) {
    // Load image from path
    guard let image = UIImage(contentsOfFile: imagePath),
          let cgImage = image.cgImage else {
      result(FlutterError(code: "IMAGE_LOAD_ERROR",
                        message: "Failed to load image from path: \(imagePath)",
                        details: nil))
      return
    }
    
    // Create Vision text recognition request
    let request = VNRecognizeTextRequest { (request, error) in
      if let error = error {
        result(FlutterError(code: "RECOGNITION_ERROR",
                          message: "Text recognition failed: \(error.localizedDescription)",
                          details: nil))
        return
      }
      
      guard let observations = request.results as? [VNRecognizedTextObservation] else {
        result("")
        return
      }
      
      // Extract all recognized text
      let recognizedStrings = observations.compactMap { observation in
        observation.topCandidates(1).first?.string
      }
      
      let fullText = recognizedStrings.joined(separator: "\n")
      result(fullText)
    }
    
    // Configure request for better accuracy
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    
    // Perform the request
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try requestHandler.perform([request])
      } catch {
        result(FlutterError(code: "REQUEST_ERROR",
                          message: "Failed to perform text recognition: \(error.localizedDescription)",
                          details: nil))
      }
    }
  }
}
