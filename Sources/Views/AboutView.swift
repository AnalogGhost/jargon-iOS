import SwiftUI

struct AboutView: View {
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "Version \(version)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Jargon")
                    .font(.title)
                Text(versionString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(
                    "A fully offline reader for the Jargon File — the hacker culture " +
                    "dictionary that gave the word \"hacker\" its original meaning. " +
                    "Nothing in this app ever touches the network."
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("App license").font(.headline)
                    Text(
                        "This app's source code is licensed under the GNU General Public " +
                        "License v3.0 or later. See the LICENSE file in the source repository " +
                        "for the full text."
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dictionary content").font(.headline)
                    Text(
                        "Entries are drawn from the Jargon File, originally compiled by Eric S. " +
                        "Raymond and Guy L. Steele, and continued today as the Community Edition " +
                        "at github.com/agiacalone/jargonfile. Content is licensed under " +
                        "Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)."
                    )
                }
            }
            .font(.body)
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
