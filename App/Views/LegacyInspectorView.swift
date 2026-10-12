import SwiftUI

/// Shows what each of the client's Windows files appears to be (week-1 inventory).
struct LegacyInspectorView: View {
    let reports: [LegacyFileReport]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Windows data files").font(.title2.weight(.semibold))
            List(reports) { report in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(report.url.lastPathComponent).font(.headline)
                        Spacer()
                        Text(report.format.rawValue).foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: Int64(report.byteCount), countStyle: .file))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ForEach(report.details, id: \.self) { detail in
                        Text(detail)
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 4)
            }
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 420)
    }
}
