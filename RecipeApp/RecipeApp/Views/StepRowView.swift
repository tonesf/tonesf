import SwiftUI

struct StepRowView: View {
    let step: StepModel
    let displayedTemp: String?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(step.index)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(step.instruction)
                    .font(.body)

                HStack(spacing: 12) {
                    if let mins = step.durationMinutes {
                        Label("\(mins) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let temp = displayedTemp {
                        Label(temp, systemImage: "thermometer.medium")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
