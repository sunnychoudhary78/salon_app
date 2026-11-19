import Flutter
import GoogleMaps
import Photos
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let galleryChannelName = "com.imt.catchy/gallery_saver"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBQyfnZPU8BIunPr4nmD48xn02norr6Agc")
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: galleryChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "saveImageToGallery" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let args = call.arguments as? [String: Any],
          let typedData = args["bytes"] as? FlutterStandardTypedData,
          let image = UIImage(data: typedData.data)
        else {
          result(
            FlutterError(
              code: "INVALID_BYTES",
              message: "Invalid image data",
              details: nil
            )
          )
          return
        }
        self?.saveImageToPhotoLibrary(image: image, result: result)
      }
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveImageToPhotoLibrary(image: UIImage, result: @escaping FlutterResult) {
    let performSave = {
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(true)
          } else {
            result(
              FlutterError(
                code: "SAVE_FAILED",
                message: error?.localizedDescription ?? "Failed to save photo",
                details: nil
              )
            )
          }
        }
      }
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        if status == .authorized || status == .limited {
          performSave()
        } else {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "PERMISSION_DENIED",
                message: "Photo library permission denied",
                details: nil
              )
            )
          }
        }
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          performSave()
        } else {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "PERMISSION_DENIED",
                message: "Photo library permission denied",
                details: nil
              )
            )
          }
        }
      }
    }
  }
}
