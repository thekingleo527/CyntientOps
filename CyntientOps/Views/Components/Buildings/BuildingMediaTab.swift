import SwiftUI
import AVKit

struct BuildingMediaTab: View {
    let buildingId: String
    let buildingName: String
    let container: ServiceContainer
    @ObservedObject var viewModel: BuildingDetailViewModel

    @State private var isLoading = true
    @State private var mediaItems: [CoreTypes.ProcessedPhoto] = []
    @State private var selectedCategory: CoreTypes.CyntientOpsPhotoCategory? = nil
    @State private var selectedMediaType: String = "all" // all | image | video
    @State private var selectedSpaceId: String? = nil
    @State private var latestBySpace: [String: CoreTypes.ProcessedPhoto] = [:]
    @State private var showPairs: Bool = false
    @State private var showViewer: Bool = false
    @State private var viewerItem: CoreTypes.ProcessedPhoto? = nil

    private var photosDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos")
    }
    private var videosDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Media", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Spacer()
                Menu {
                    Button("All Categories") { selectedCategory = nil; Task { await loadMedia() } }
                    ForEach(CoreTypes.CyntientOpsPhotoCategory.allCases, id: \.self) { cat in
                        Button(cat.displayName) { selectedCategory = cat; Task { await loadMedia(selectedSpaceId) } }
                    }
                } label: {
                    Label(selectedCategory?.displayName ?? "All", systemImage: "line.3.horizontal.decrease.circle")
                }
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            // Media type filter
            Picker("Type", selection: $selectedMediaType) {
                Text("All").tag("all")
                Text("Images").tag("image")
                Text("Videos").tag("video")
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedMediaType) { _, _ in
                Task { await loadMedia(selectedSpaceId) }
            }

            // Location chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: { selectedSpaceId = nil; Task { await loadMedia(nil) } }) {
                        Label("All Locations", systemImage: "square.grid.2x2").font(.caption)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background((selectedSpaceId == nil ? CyntientOpsDesign.DashboardColors.secondaryAction : Color.clear).opacity(0.2))
                    .cornerRadius(8)
                    ForEach(viewModel.spaces) { space in
                        Button(action: { selectedSpaceId = space.id; Task { await loadMedia(space.id) } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "key.fill").font(.caption2)
                                Text(space.name).font(.caption)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background((selectedSpaceId == space.id ? CyntientOpsDesign.DashboardColors.secondaryAction : Color.clear).opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading media...")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
            } else if mediaItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    Text("No media found")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .glassCard()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle(isOn: $showPairs) { Text("Show Before/After") }
                            .tint(CyntientOpsDesign.DashboardColors.secondaryAction)
                        Spacer()
                        Text("\(mediaItems.count) items")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }

                    if showPairs {
                        pairedView(items: mediaItems)
                    } else {
                        mediaGrid(items: mediaItems)
                    }
                }
            }
        }
        .task { await loadMedia(); await loadLatestForSpaces() }
        .sheet(isPresented: $showViewer) {
            if let item = viewerItem {
                MediaViewer(item: item, photosDirectory: photosDirectory, videosDirectory: videosDirectory)
            }
        }
    }

    private func thumbnailView(for item: CoreTypes.ProcessedPhoto) -> some View {
        let thumbURL = photosDirectory.appendingPathComponent(item.thumbnailPath)
        if let image = UIImage(contentsOfFile: thumbURL.path) {
            return AnyView(
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                    if item.mediaType == "video" {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
            )
        } else {
            return AnyView(
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            )
        }
    }

    private func loadMedia(_ spaceId: String? = nil) async {
        isLoading = true
        let cat = selectedCategory
        do {
            let mt = (selectedMediaType == "all") ? nil : selectedMediaType
            let items = try await container.photos.getRecentMedia(buildingId: buildingId, category: cat, spaceId: spaceId, mediaType: mt, limit: 50)
            await MainActor.run {
                self.mediaItems = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.mediaItems = []
                self.isLoading = false
            }
        }
    }

    private func loadLatestForSpaces() async {
        var map: [String: CoreTypes.ProcessedPhoto] = [:]
        for space in viewModel.spaces {
            if let latest = try? await container.photos.getLatestMediaForSpace(buildingId: buildingId, spaceId: space.id) {
                map[space.id] = latest
            }
        }
        await MainActor.run { self.latestBySpace = map }
    }

    private func mediaGrid(items: [CoreTypes.ProcessedPhoto]) -> some View {
        let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items, id: \.id) { item in
                    Button {
                        viewerItem = item
                        showViewer = true
                    } label: {
                        VStack(spacing: 6) {
                            thumbnailView(for: item)
                                .frame(width: 100, height: 100)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(8)
                            Text(item.category)
                                .font(.caption2)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard()
    }

    private func pairedView(items: [CoreTypes.ProcessedPhoto]) -> some View {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var buckets: [String: (before: [CoreTypes.ProcessedPhoto], after: [CoreTypes.ProcessedPhoto])] = [:]
        for item in items {
            let day = df.string(from: item.timestamp)
            if buckets[day] == nil { buckets[day] = ([], []) }
            if item.category == CoreTypes.CyntientOpsPhotoCategory.beforeWork.rawValue {
                buckets[day]?.before.append(item)
            } else if item.category == CoreTypes.CyntientOpsPhotoCategory.afterWork.rawValue {
                buckets[day]?.after.append(item)
            }
        }
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(buckets.keys.sorted(by: >), id: \.self) { day in
                VStack(alignment: .leading, spacing: 6) {
                    Text(day).font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    let before = buckets[day]?.before.first
                    let after = buckets[day]?.after.first
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text("Before").font(.caption2).foregroundColor(.gray)
                            if let b = before { thumbnailView(for: b).frame(width: 110, height: 110).cornerRadius(8) } else { placeholderThumb }
                        }
                        VStack(spacing: 4) {
                            Text("After").font(.caption2).foregroundColor(.gray)
                            if let a = after { thumbnailView(for: a).frame(width: 110, height: 110).cornerRadius(8) } else { placeholderThumb }
                        }
                    }
                }
                .glassCard()
            }
        }
    }

    private var placeholderThumb: some View {
        ZStack { Color.gray.opacity(0.1); Image(systemName: "photo").foregroundColor(.gray) }.frame(width: 110, height: 110).cornerRadius(8)
    }

    private struct MediaViewer: View {
        let item: CoreTypes.ProcessedPhoto
        let photosDirectory: URL
        let videosDirectory: URL
        @State private var player: AVPlayer? = nil

        var body: some View {
            Group {
                if item.mediaType == "video" {
                    if let url = urlForVideo() {
                        VideoPlayer(player: AVPlayer(url: url))
                            .onAppear { player?.play() }
                            .onDisappear { player?.pause() }
                    } else {
                        unsupportedView
                    }
                } else {
                    if let image = loadImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .background(Color.black)
                    } else {
                        unsupportedView
                    }
                }
            }
        }

        private func loadImage() -> UIImage? {
            let path = photosDirectory.appendingPathComponent(item.filePath).path
            return UIImage(contentsOfFile: path)
        }

        private func urlForVideo() -> URL? {
            let url = videosDirectory.appendingPathComponent(item.filePath)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }

        private var unsupportedView: some View {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.yellow)
                Text("Unable to load media")
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black)
        }
    }
}

