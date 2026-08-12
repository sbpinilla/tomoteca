//
//  CoverPicker.swift
//  tomoteca
//

import PhotosUI
import SwiftUI

/// Presents the whole "where does this cover come from" flow: a menu, then the camera or the
/// photo library, and hands back image data already reduced for storage.
///
/// Shared by the add form and the detail screen, which is the point — a cover can be added at
/// any moment in a book's life, not only when it is first registered.
private struct CoverPickerModifier: ViewModifier {

    @Binding var isPresented: Bool
    let hasCover: Bool
    let onPick: (Data) -> Void
    let onRemove: () -> Void

    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var libraryItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .confirmationDialog("", isPresented: $isPresented, titleVisibility: .hidden) {
                // Hidden rather than disabled on a device without one, which is every simulator.
                if CameraPicker.isAvailable {
                    Button { isShowingCamera = true } label: { Text(.coverSourceCamera) }
                }

                Button { isShowingLibrary = true } label: { Text(.coverSourceLibrary) }

                if hasCover {
                    Button(role: .destructive, action: onRemove) { Text(.coverRemove) }
                }

                Button(role: .cancel) {} label: { Text(.commonCancel) }
            }
            // The photo picker runs out of process, so choosing a photo needs no permission
            // and shows no prompt. Only the camera does.
            .photosPicker(isPresented: $isShowingLibrary, selection: $libraryItem, matching: .images)
            .onChange(of: libraryItem) { item in
                guard let item else { return }
                Task { await load(item) }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker { image in
                    if let data = image.coverData() { onPick(data) }
                }
                .ignoresSafeArea()
            }
    }

    private func load(_ item: PhotosPickerItem) async {
        defer { libraryItem = nil }

        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let cover = image.coverData()
        else {
            return
        }

        onPick(cover)
    }
}

extension View {

    /// Attaches the cover source menu, driven by `isPresented`.
    func coverPicker(
        isPresented: Binding<Bool>,
        hasCover: Bool,
        onPick: @escaping (Data) -> Void,
        onRemove: @escaping () -> Void
    ) -> some View {
        modifier(
            CoverPickerModifier(
                isPresented: isPresented,
                hasCover: hasCover,
                onPick: onPick,
                onRemove: onRemove
            )
        )
    }
}
