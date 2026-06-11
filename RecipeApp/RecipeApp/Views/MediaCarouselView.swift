import AVKit
import SwiftUI

struct MediaCarouselView: View {
    let media: [MediaItemDTO]

    var body: some View {
        if media.isEmpty { EmptyView() }
        else if media.count == 1 {
            MediaItemView(item: media[0])
                .frame(maxWidth: .infinity)
                .clipped()
        } else {
            TabView {
                ForEach(media, id: \.url) { item in
                    MediaItemView(item: item)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 280)
        }
    }
}

private struct MediaItemView: View {
    let item: MediaItemDTO

    var body: some View {
        if item.type == "video", let url = URL(string: item.url) {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(height: 280)
        } else if let url = URL(string: item.url) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "photo").foregroundStyle(.secondary)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipped()
        }
    }
}
