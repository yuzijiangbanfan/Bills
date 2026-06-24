import Foundation
import UIKit
import Photos

class ScreenshotHandler: ObservableObject {
    @Published var isProcessing = false
    @Published var lastRecognizedAmount: Double?
    @Published var error: String?
    
    let appGroupID = "group.com.example.bills"
    
    /// Process screenshot from Photo Library (used by the Shortcut flow)
    /// Shortcut: Take Screenshot → Open App → App reads latest photo → OCR → Delete → Popup
    func processFromPhotoLibrary() async -> Double? {
        await MainActor.run { self.isProcessing = true; self.error = nil }
        defer { Task { await MainActor.run { self.isProcessing = false } } }
        
        // 1. Request photo library permission
        let status = await requestPhotoPermission()
        guard status == .authorized || status == .limited else {
            await MainActor.run { self.error = "需要相册权限才能自动识别截图" }
            return nil
        }
        
        // 2. Fetch most recent photo
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let latestAsset = result.firstObject else {
            await MainActor.run { self.error = "没有找到截图" }
            return nil
        }
        
        // 3. Check if the photo was taken recently (within 15 seconds)
        guard let creationDate = latestAsset.creationDate else {
            await MainActor.run { self.error = "无法确定截图时间" }
            return nil
        }
        
        let timeSinceCreation = Date().timeIntervalSince(creationDate)
        guard timeSinceCreation < 15 else {
            await MainActor.run { self.error = "没有找到最近的截图" }
            return nil
        }
        
        // 4. Get image data from the asset
        guard let imageData = await requestImageData(from: latestAsset) else {
            await MainActor.run { self.error = "无法读取截图" }
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            await MainActor.run { self.error = "无法读取截图" }
            return nil
        }
        
        // 5. OCR the image
        guard let recognizedText = await OCRService.recognizeText(from: image) else {
            await MainActor.run { self.error = "无法识别截图中的文字" }
            return nil
        }
        
        // 6. Parse amount
        guard let amount = AmountParser.parse(from: recognizedText) else {
            await MainActor.run { self.error = "无法识别金额" }
            return nil
        }
        
        // 7. Delete the screenshot from photo library
        await deletePhoto(latestAsset)
        
        await MainActor.run {
            self.lastRecognizedAmount = amount
        }
        
        return amount
    }
    
    // MARK: - Helpers
    
    private func requestPhotoPermission() async -> PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        } else {
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        }
    }
    
    private func requestImageData(from asset: PHAsset) async -> Data? {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image?.pngData())
            }
        }
    }
    
    private func deletePhoto(_ asset: PHAsset) async {
        try? await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }
    }
}
