import SwiftUI

/// A helper class for managing photo library saving operations that require Objective-C compatibility
class PhotoLibraryDelegate: NSObject {
    var onSuccess: () -> Void
    var onFailure: (Error) -> Void
    
    init(onSuccess: @escaping () -> Void, onFailure: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        super.init()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            onFailure(error)
        } else {
            onSuccess()
        }
    }
} 