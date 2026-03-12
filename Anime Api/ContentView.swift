import SwiftUI

struct ContentView: View {
    
    @State private var entries = [Entry]()
    @State private var showingAlert = false
    @State private var showingAddScreen = false
    
    var body: some View {
        NavigationView {
            ZStack {
                
                // Dark background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Gradient header
                    headerView
                    
                    // Anime list
                    List {
                        ForEach(entries) { entry in
                            animeCard(entry)
                                .listRowBackground(Color.black)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            entries.remove(atOffsets: indexSet)
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
            .sheet(isPresented: $showingAddScreen) {
                AddAnimeView(entries: $entries)
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
            
            Text("Anime Notebook")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                showingAddScreen = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
            }
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
    
    // Anime Card
    private func animeCard(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text(entry.name)
                .font(.headline)
                .foregroundColor(.white)
            
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .shadow(radius: 8)
        )
        .padding(.vertical, 6)
    }
    
    // API Loader
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
        
        enum CodingKeys: String, CodingKey {
            case name = "title"
            case link = "url"
            case episodes
            case score
        }
    }
    
    struct Entries: Codable {
        var response: [Entry]
        
        enum CodingKeys: String, CodingKey {
            case response = "data"
        }
    }
}

// Add Anime Screen
struct AddAnimeView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var entries: [ContentView.Entry]
    
    @State private var name = ""
    @State private var episodes = ""
    @State private var score = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Anime Name", text: $name)
                TextField("Episodes", text: $episodes)
                    .keyboardType(.numberPad)
                TextField("Rating", text: $score)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Anime")
            .toolbar {
                Button("Save") {
                    let newAnime = ContentView.Entry(
                        name: name,
                        link: "",
                        episodes: Int(episodes),
                        score: Double(score)
                    )
                    entries.append(newAnime)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
