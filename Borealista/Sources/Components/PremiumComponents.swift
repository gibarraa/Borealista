import SwiftUI

struct ShellScrollView<Content: View>: View {
    var showsIndicators = false
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            PremiumBackground()

            ScrollView(showsIndicators: showsIndicators) {
                VStack(spacing: 24) {
                    content
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 132)
            }
        }
    }
}

struct ProfileAvatar: View {
    let initials: String
    var diameter: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(BorealistaPalette.buttonFill)
            Circle()
                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
            Text(initials)
                .font(BorealistaType.heading(diameter * 0.31))
                .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: BorealistaPalette.espresso.opacity(0.14), radius: 16, y: 10)
    }
}

struct ProfileDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BorealistaType.label(12))
                .foregroundStyle(BorealistaPalette.stone)
            Text(value)
                .font(BorealistaType.body(15))
                .foregroundStyle(BorealistaPalette.ink)
        }
        .padding(.vertical, 4)
    }
}

struct AbsenceCard: View {
    let record: AbsenceRecord
    var actionTitle: String?
    var action: (() -> Void)? = nil

    var body: some View {
        PremiumCard {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(record.status.tint.opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "calendar")
                            .foregroundStyle(record.status.tint)
                    )

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(record.courseTitle)
                            .font(BorealistaType.heading(19))
                            .foregroundStyle(BorealistaPalette.ink)
                        Spacer()
                        StatusBadge(title: record.status.rawValue, tint: record.status.tint)
                    }

                    Text("\(record.date) · \(record.time)")
                        .font(BorealistaType.code(13))
                        .foregroundStyle(BorealistaPalette.cocoa)

                    Text(record.reason)
                        .font(BorealistaType.body(14))
                        .foregroundStyle(BorealistaPalette.stone)

                    if let actionTitle, let action {
                        Button(actionTitle, action: action)
                            .font(BorealistaType.heading(14))
                            .foregroundStyle(BorealistaPalette.ember)
                    }
                }
            }
        }
    }
}

struct StudentRecordRow: View {
    let record: StudentRecord
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 14) {
            ProfileAvatar(initials: String(record.name.prefix(2)).uppercased(), diameter: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(BorealistaType.heading(16))
                    .foregroundStyle(BorealistaPalette.ink)
                Text(record.idCode)
                    .font(BorealistaType.body(13))
                    .foregroundStyle(BorealistaPalette.stone)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                StatusBadge(title: record.attendance.rawValue, tint: record.attendance.tint)
                Text("\(record.streak) sesiones")
                    .font(BorealistaType.code(11))
                    .foregroundStyle(BorealistaPalette.stone)
            }

            trailing
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
    }
}

struct JustificationCard: View {
    let record: JustificationRecord
    var showActions = false

    var body: some View {
        PremiumCard {
            HStack(alignment: .top, spacing: 14) {
                ProfileAvatar(initials: String(record.studentName.prefix(2)).uppercased(), diameter: 50)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.studentName)
                                .font(BorealistaType.heading(19))
                                .foregroundStyle(BorealistaPalette.ink)
                            Text(record.courseTitle)
                                .font(BorealistaType.code(13))
                                .foregroundStyle(BorealistaPalette.cocoa)
                        }
                        Spacer()
                        StatusBadge(title: record.status.rawValue, tint: record.status.tint)
                    }

                    Text(record.date)
                        .font(BorealistaType.code(13))
                        .foregroundStyle(BorealistaPalette.stone)

                    Text(record.summary)
                        .font(BorealistaType.body(14))
                        .foregroundStyle(BorealistaPalette.stone)

                    if showActions {
                        HStack(spacing: 12) {
                            Button("Approve") { }
                                .font(BorealistaType.heading(14))
                                .foregroundStyle(BorealistaPalette.forest)
                            Button("Request update") { }
                                .font(BorealistaType.heading(14))
                                .foregroundStyle(BorealistaPalette.ember)
                        }
                    }
                }
            }
        }
    }
}

struct NoticeCard: View {
    let notice: ScreenNotice

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: notice.tone.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(notice.tone.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text(notice.title)
                    .font(BorealistaType.heading(17))
                    .foregroundStyle(BorealistaPalette.ink)

                Text(notice.message)
                    .font(BorealistaType.body(13))
                    .foregroundStyle(BorealistaPalette.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.82),
                                notice.tone.tint.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(notice.tone.tint.opacity(0.16), lineWidth: 0.8)
        )
    }
}

struct LoadingStateCard: View {
    let title: String
    let message: String

    var body: some View {
        PremiumCard {
            HStack(spacing: 14) {
                ProgressView()
                    .tint(BorealistaPalette.cedar)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(BorealistaType.heading(18))
                        .foregroundStyle(BorealistaPalette.ink)
                    Text(message)
                        .font(BorealistaType.body(14))
                        .foregroundStyle(BorealistaPalette.stone)
                }
            }
        }
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String

    var body: some View {
        PremiumCard(accentOpacity: 0.12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(BorealistaType.display(23))
                    .foregroundStyle(BorealistaPalette.wordmarkFill)

                Text(message)
                    .font(BorealistaType.body(14))
                    .foregroundStyle(BorealistaPalette.stone)
            }
        }
    }
}

struct MultilineField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(BorealistaType.label(12))
                .foregroundStyle(BorealistaPalette.cocoa)

            ZStack(alignment: .topLeading) {
                if text.trimmed.isEmpty {
                    Text(prompt)
                        .font(BorealistaType.body(16))
                        .foregroundStyle(BorealistaPalette.stone.opacity(0.72))
                        .padding(.top, 14)
                        .padding(.leading, 42)
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BorealistaPalette.stone)
                        .frame(width: 16)
                        .padding(.top, 15)

                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .foregroundStyle(BorealistaPalette.espresso)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.88), BorealistaPalette.pearl.opacity(0.62)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(BorealistaPalette.line.opacity(0.28), lineWidth: 0.8)
            )
        }
    }
}
