//
//  ContentView.swift
//  Anime Api
//
//  Created by joseph phillips on 3/10/26.
//
import SwiftUI
struct ContentView: View {
    @State private var entries = [Entry]()
    @State private var showingAlert = false
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerView
                    List {
                        ForEach(entries) { entry in
                            
                            NavigationLink(destination: AnimeDetailView(entry: entry)) {
                                animeCard(entry)
                            }
                            .listRowBackground(Color.black)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadData()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Loading Error"),
                      message: Text("There was a problem loading the anime"))
            }
        }
    }
    // Header
    private var headerView: some View {
        HStack {
            
            Text("To Watch List")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple, Color.blue, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .padding()
    }
    // Anime
    private func animeCard(_ entry: Entry) -> some View {
        HStack(spacing: 15) {
            // Cover Image
            AsyncImage(url: URL(string: entry.image)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 70, height: 100)
            .cornerRadius(10)
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.name)
                    .font(.headline)
                    .foregroundColor(.white)
                AnimeInfo(entry: entry)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .shadow(radius: 8)
        )
        .padding(.vertical, 6)
    }
    func loadData() async {
        let query = "https://api.jikan.moe/v4/anime"
        if let url = URL(string: query) {
            if let (data, _) = try? await URLSession.shared.data(from: url) {
                if let decodedResponse = try? JSONDecoder().decode(Entries.self, from: data) {
                    entries = decodedResponse.response
                    return
                }
            }
        }
        showingAlert = true
    }
    struct Entry: Identifiable, Codable {
        var id = UUID()
        var name: String
        var link: String
        var episodes: Int?
        var score: Double?
        var image: String
        enum CodingKeys: String, CodingKey {
            case name = "title"
            case link = "url"
            case episodes
            case score
            case images
        }
        enum ImageKeys: String, CodingKey {
            case jpg
        }
        enum JPGKeys: String, CodingKey {
            case image_url
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            link = try container.decode(String.self, forKey: .link)
            episodes = try container.decodeIfPresent(Int.self, forKey: .episodes)
            score = try container.decodeIfPresent(Double.self, forKey: .score)
            let imagesContainer = try container.nestedContainer(keyedBy: ImageKeys.self, forKey: .images)
            let jpgContainer = try imagesContainer.nestedContainer(keyedBy: JPGKeys.self, forKey: .jpg)
            image = try jpgContainer.decode(String.self, forKey: .image_url)
        }
    }
    struct Entries: Codable {
        var response: [Entry]
        
        enum CodingKeys: String, CodingKey {
            case response = "data"
        }
    }
}
struct AnimeInfo: View {
    let entry: ContentView.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let episodes = entry.episodes {
                Text("📺 Episodes: \(episodes)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if let score = entry.score {
                Text("⭐ Rating: \(score, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
    }
}
struct AnimeDetailView: View {
    let entry: ContentView.Entry
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: entry.image)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 300)
                .cornerRadius(20)
                
                Text(entry.name)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                AnimeInfo(entry: entry)
                Link("More Information",
                     destination: URL(string: entry.link)!)
                .font(.headline)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
                .foregroundColor(.white)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Anime Details")
    }
}


#Preview {
    ContentView()
}
