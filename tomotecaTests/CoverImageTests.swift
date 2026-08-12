//
//  CoverImageTests.swift
//  tomotecaTests
//

import Testing
import UIKit
@testable import tomoteca

struct CoverImageTests {

    @Test("A large photo is scaled down to the storage limit")
    func shrinksLargePhotos() throws {
        let photo = UIImage.sampleCover(color: .red, size: CGSize(width: 4032, height: 3024))

        let data = try #require(photo.coverData())
        let stored = try #require(UIImage(data: data))

        #expect(max(stored.size.width, stored.size.height) == UIImage.coverMaxDimension)
    }

    @Test("Scaling keeps the photo's proportions")
    func keepsAspectRatio() throws {
        let photo = UIImage.sampleCover(color: .red, size: CGSize(width: 4000, height: 2000))

        let data = try #require(photo.coverData())
        let stored = try #require(UIImage(data: data))

        #expect(stored.size.width / stored.size.height == 2)
    }

    @Test("An image already within the limit is not enlarged")
    func doesNotUpscaleSmallImages() throws {
        let small = UIImage.sampleCover(color: .red, size: CGSize(width: 300, height: 400))

        let data = try #require(small.coverData())
        let stored = try #require(UIImage(data: data))

        #expect(stored.size == CGSize(width: 300, height: 400))
    }

    @Test("The limit counts pixels, not points, on an image with a scale factor")
    func measuresInPixelsNotPoints() throws {
        // 600×800 points at scale 3 is 1800×2400 pixels: well over the limit even though its
        // `size` looks small. Measuring points would have stored it at full resolution.
        let base = UIImage.sampleCover(color: .blue, size: CGSize(width: 1800, height: 2400))
        let scaled = UIImage(cgImage: try #require(base.cgImage), scale: 3, orientation: .up)
        #expect(scaled.size == CGSize(width: 600, height: 800))

        let data = try #require(scaled.coverData())
        let stored = try #require(UIImage(data: data))

        #expect(max(stored.size.width, stored.size.height) == UIImage.coverMaxDimension)
    }

    @Test("The stored cover weighs far less than the original photo")
    func storedCoverIsSmallerThanTheOriginal() throws {
        let photo = UIImage.sampleCover(color: .red, size: CGSize(width: 4032, height: 3024))
        let original = try #require(photo.pngData())

        let stored = try #require(photo.coverData())

        #expect(stored.count < original.count / 4)
    }
}
