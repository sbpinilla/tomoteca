//
//  UIImage+CoverData.swift
//  tomoteca
//

import UIKit

extension UIImage {

    /// Longest side a stored cover is allowed to have, in pixels.
    static let coverMaxDimension: CGFloat = 1200

    /// Shrinks the image and encodes it as JPEG, ready to be stored.
    ///
    /// A camera photo runs to several megabytes at a resolution no cover ever needs: it is shown
    /// at 44 points in a list and 160 in the detail. Storing the original would bloat the store
    /// and slow down every read of the catalog, so it is capped at ``coverMaxDimension`` on the
    /// longest side, keeping its proportions.
    ///
    /// Returns `nil` only if encoding fails.
    func coverData(
        maxDimension: CGFloat = UIImage.coverMaxDimension,
        compressionQuality: CGFloat = 0.8
    ) -> Data? {
        resized(toMaxDimension: maxDimension).jpegData(compressionQuality: compressionQuality)
    }

    /// The image scaled down so its longest side is at most `maxDimension` **pixels**. Images
    /// already within the limit are returned untouched rather than re-encoded.
    ///
    /// Measured in pixels, not points: `size` is in points, and an image whose `scale` is not 1
    /// — anything rendered for the screen, or some library imports — holds far more pixels than
    /// its `size` suggests. Comparing points against a pixel budget would let those through at
    /// two or three times the intended resolution.
    private func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)
        let longestSide = max(pixelSize.width, pixelSize.height)
        guard longestSide > 0 else { return self }
        guard longestSide > maxDimension else {
            return scale == 1 ? self : redrawnAtScaleOne(pixelSize: pixelSize)
        }

        let ratio = maxDimension / longestSide
        let target = CGSize(width: pixelSize.width * ratio, height: pixelSize.height * ratio)
        return redrawnAtScaleOne(pixelSize: target)
    }

    /// Redraws at exactly the given pixel size, so what comes back out of the stored data has
    /// the dimensions this code decided on and not the screen's scale factor applied again.
    private func redrawnAtScaleOne(pixelSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: pixelSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }
}

#if DEBUG
extension UIImage {

    /// A flat colored image of exactly `size` pixels, for sample books and tests. Never shipped.
    ///
    /// Rendered at scale 1 so its pixel dimensions match what the caller asked for, instead of
    /// being multiplied by whatever screen it was created on.
    static func sampleCover(color: UIColor, size: CGSize = CGSize(width: 400, height: 560)) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
#endif
