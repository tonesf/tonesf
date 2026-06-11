import SwiftUI

struct SettingsView: View {
    @AppStorage("backendURL") private var backendURL: String = "http://localhost:8000"
    @State private var draftURL: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("http://192.168.x.x:8000", text: $draftURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onAppear { draftURL = backendURL }
                        .onSubmit { saveURL() }
                    Button("Save") { saveURL() }
                } header: {
                    Text("Backend URL")
                } footer: {
                    Text("Point this at your Mac's IP when running the backend locally, e.g. http://192.168.1.10:8000")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func saveURL() {
        let trimmed = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        backendURL = trimmed
        UserDefaults(suiteName: AppGroup.identifier)?.set(trimmed, forKey: UserDefaultsKey.backendURL)
    }
}
