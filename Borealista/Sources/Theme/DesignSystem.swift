import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

enum BorealistaPalette {
    static let espresso = Color(hex: "#542C29")
    static let cedar = Color(hex: "#863630")
    static let ember = Color(hex: "#AD2218")
    static let blush = Color(hex: "#DB9C98")
    static let sand = Color(hex: "#D8CBC5")
    static let mist = Color(hex: "#EEE6E2")
    static let line = Color(hex: "#D9CCC7")
    static let stone = Color(hex: "#A88F89")
    static let paper = Color(hex: "#FBF7F4")
    static let porcelain = Color(hex: "#FFFDFC")
    static let ink = Color(hex: "#2B1716")
    static let cocoa = Color(hex: "#6D413D")
    static let pearl = Color(hex: "#F7F2EF")
    static let cloud = Color(hex: "#F2E9E5")
    static let forest = Color(hex: "#4E7B61")
    static let gold = Color(hex: "#D29952")

    static let canvas = LinearGradient(
        colors: [
            porcelain,
            paper,
            Color(hex: "#F5ECE8")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonFill = LinearGradient(
        colors: [cedar, espresso],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let wordmarkFill = LinearGradient(
        colors: [ink, espresso, cedar],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func courseGradient(_ accent: String) -> LinearGradient {
        switch accent {
        case "sunrise":
            LinearGradient(colors: [cedar, blush], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "forest":
            LinearGradient(colors: [forest, sand], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            LinearGradient(colors: [espresso, blush], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    static func courseTint(_ accent: String) -> Color {
        switch accent {
        case "sunrise":
            blush
        case "forest":
            forest
        default:
            cedar
        }
    }
}

enum BorealistaType {
    static func display(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Bold", size: size)
    }

    static func heading(_ size: CGFloat) -> Font {
        .custom("AvenirNext-DemiBold", size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Medium", size: size)
    }

    static func label(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Medium", size: size)
    }

    static func code(_ size: CGFloat) -> Font {
        .custom("AvenirNext-DemiBold", size: size)
    }
}

extension Color {
    init(hex: String) {
        let rawValue = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: rawValue).scanHexInt64(&int)
        let red = Double((int >> 16) & 0xFF) / 255.0
        let green = Double((int >> 8) & 0xFF) / 255.0
        let blue = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

private enum BorealistaBrandAsset {
    static var image: UIImage? {
        if let named = UIImage(named: "BorealistaMark") {
            return named
        }

        guard let url = Bundle.main.url(forResource: "borealista-logo", withExtension: "png") else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
    }
}

private struct BorealistaBrandImage: View {
    var body: some View {
        Group {
            if let image = BorealistaBrandAsset.image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .renderingMode(.original)
            } else {
                Image("BorealistaMark")
                    .resizable()
                    .renderingMode(.original)
            }
        }
    }
}

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            BorealistaPalette.canvas
                .ignoresSafeArea()

            BorealistaBrandImage()
                .scaledToFit()
                .frame(width: 420)
                .opacity(0.09)
                .blur(radius: 0.2)
                .offset(x: 38, y: -290)

            RoundedRectangle(cornerRadius: 180, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BorealistaPalette.blush.opacity(0.20),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 360, height: 520)
                .blur(radius: 16)
                .rotationEffect(.degrees(18))
                .offset(x: -120, y: -220)

            Circle()
                .fill(BorealistaPalette.cedar.opacity(0.11))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 150, y: -240)

            Circle()
                .fill(BorealistaPalette.blush.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 78)
                .offset(x: -150, y: 140)

            Circle()
                .fill(BorealistaPalette.espresso.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 88)
                .offset(x: 170, y: 380)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .ignoresSafeArea()
        }
    }
}

struct BorealistaMark: View {
    var width: CGFloat = 70

    var body: some View {
        BorealistaBrandImage()
            .scaledToFit()
            .frame(width: width)
            .shadow(color: BorealistaPalette.espresso.opacity(0.16), radius: 14, y: 6)
    }
}

struct BrandWordmark: View {
    var logoWidth: CGFloat = 72
    var fontSize: CGFloat = 34

    var body: some View {
        HStack(spacing: 14) {
            BorealistaMark(width: logoWidth)

            Text("Borealista")
                .font(BorealistaType.display(fontSize))
                .foregroundStyle(BorealistaPalette.wordmarkFill)
                .tracking(-1)
        }
    }
}

struct BrandHero: View {
    var body: some View {
        VStack(spacing: 12) {
            BorealistaMark(width: 210)
            Text("Borealista")
                .font(BorealistaType.display(42))
                .foregroundStyle(BorealistaPalette.wordmarkFill)
                .tracking(-1.2)
        }
    }
}

struct IconChromeButton: View {
    let systemImage: String
    var action: () -> Void = { }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(BorealistaPalette.cedar)
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.22))
                        Circle()
                            .fill(.ultraThinMaterial)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.72), BorealistaPalette.blush.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
                .shadow(color: BorealistaPalette.espresso.opacity(0.10), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct PremiumCard<Content: View>: View {
    var accentOpacity: Double = 0.10
    var padding: CGFloat = 22
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.16))

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.74),
                                BorealistaPalette.pearl.opacity(0.62),
                                BorealistaPalette.blush.opacity(accentOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(BorealistaPalette.line.opacity(0.30), lineWidth: 0.8)
        )
        .shadow(color: BorealistaPalette.espresso.opacity(0.06), radius: 22, y: 12)
        .shadow(color: Color.white.opacity(0.30), radius: 10, y: -2)
    }
}

struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(eyebrow.uppercased())
                    .font(BorealistaType.label(11))
                    .tracking(3)
                    .foregroundStyle(BorealistaPalette.stone.opacity(0.95))

                Text(title)
                    .font(BorealistaType.display(34))
                    .foregroundStyle(BorealistaPalette.wordmarkFill)
                    .tracking(-0.8)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(BorealistaType.body(15))
                        .foregroundStyle(BorealistaPalette.stone)
                }
            }

            Spacer(minLength: 0)

            trailing
        }
    }
}

struct RolePicker: View {
    @Binding var selectedRole: AppRole

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppRole.allCases) { role in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selectedRole = role
                    }
                } label: {
                    Text(role.rawValue)
                        .font(BorealistaType.heading(15))
                        .foregroundStyle(selectedRole == role ? Color.white : BorealistaPalette.stone)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    selectedRole == role
                                    ? AnyShapeStyle(BorealistaPalette.buttonFill)
                                    : AnyShapeStyle(Color.clear)
                                )
                        )
                        .shadow(color: selectedRole == role ? BorealistaPalette.cedar.opacity(0.22) : .clear, radius: 12, y: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.14))
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.72), BorealistaPalette.mist.opacity(0.84)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
        )
        .overlay(
            Capsule()
                .stroke(BorealistaPalette.line.opacity(0.34), lineWidth: 0.8)
        )
        .shadow(color: BorealistaPalette.espresso.opacity(0.08), radius: 18, y: 10)
    }
}

struct FormField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var prompt: String
    var secure = false
    var autocapitalization: TextInputAutocapitalization = .never
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(BorealistaType.label(12))
                .foregroundStyle(BorealistaPalette.cocoa)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BorealistaPalette.stone)
                    .frame(width: 16)

                if secure {
                    SecureField(prompt, text: $text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(keyboardType)
                } else {
                    TextField(prompt, text: $text)
                        .textInputAutocapitalization(autocapitalization)
                        .keyboardType(keyboardType)
                }
            }
            .font(BorealistaType.body(17))
            .foregroundStyle(BorealistaPalette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .background(
                ZStack {
                    Capsule()
                        .fill(Color.white.opacity(0.20))
                    Capsule()
                        .fill(.ultraThinMaterial)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.92), BorealistaPalette.pearl.opacity(0.62)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.76), lineWidth: 1)
            )
            .overlay(
                Capsule()
                    .stroke(BorealistaPalette.line.opacity(0.28), lineWidth: 0.8)
            )
        }
    }
}

struct DateFormField: View {
		let title: String
		let icon: String
		@Binding var date: Date
		var components: DatePickerComponents

		var body: some View {
				VStack(alignment: .leading, spacing: 10) {
						Text(title)
								.font(BorealistaType.label(12))
								.foregroundStyle(BorealistaPalette.cocoa)

						HStack(spacing: 12) {
								Image(systemName: icon)
										.font(.system(size: 15, weight: .semibold))
										.foregroundStyle(BorealistaPalette.stone)
										.frame(width: 16)

								DatePicker(
										"",
										selection: $date,
										displayedComponents: components
								)
								.labelsHidden()
								.colorScheme(.light)
								
								Spacer()
						}
						.padding(.horizontal, 18)
						.padding(.vertical, 13)
						.background(
								ZStack {
										Capsule()
												.fill(Color.white.opacity(0.20))
										Capsule()
												.fill(.ultraThinMaterial)
										Capsule()
												.fill(
														LinearGradient(
																colors: [Color.white.opacity(0.92), BorealistaPalette.pearl.opacity(0.62)],
																startPoint: .topLeading,
																endPoint: .bottomTrailing
														)
												)
								}
						)
						.overlay(
								Capsule()
										.stroke(Color.white.opacity(0.76), lineWidth: 1)
						)
						.overlay(
								Capsule()
										.stroke(BorealistaPalette.line.opacity(0.28), lineWidth: 0.8)
						)
				}
		}
}

struct PrimaryActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Spacer()
                Text(title)
                    .font(BorealistaType.heading(16))
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 17)
            .background(
                Capsule()
                    .fill(BorealistaPalette.buttonFill)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.34), lineWidth: 1)
            )
            .shadow(color: BorealistaPalette.cedar.opacity(0.24), radius: 20, y: 12)
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.65 : 1)
        .disabled(isDisabled)
    }
}

struct SecondaryActionButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BorealistaType.heading(15))
                .foregroundStyle(BorealistaPalette.ink)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        Capsule()
                            .fill(Color.white.opacity(0.16))
                        Capsule()
                            .fill(.ultraThinMaterial)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.86), BorealistaPalette.mist.opacity(0.82)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.80), lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .stroke(BorealistaPalette.line.opacity(0.34), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }
}

struct MetricTile: View {
    let metric: InsightMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: metric.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BorealistaPalette.cedar)

            Text(metric.value)
                .font(BorealistaType.display(25))
                .foregroundStyle(BorealistaPalette.wordmarkFill)

            Text(metric.title)
                .font(BorealistaType.body(12))
                .foregroundStyle(BorealistaPalette.stone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
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

struct CourseCard: View {
    let course: Course
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(BorealistaPalette.courseGradient(course.accent))
                        .opacity(0.22)
                    Circle()
                        .stroke(Color.white.opacity(0.82), lineWidth: 1)
                    Text(String(course.code.prefix(3)))
                        .font(BorealistaType.code(12))
                        .foregroundStyle(BorealistaPalette.cedar)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 7) {
                    Text(course.title)
                        .font(BorealistaType.heading(20))
                        .foregroundStyle(BorealistaPalette.ink)
                        .multilineTextAlignment(.leading)

                    Text(course.subject)
                        .font(BorealistaType.body(13))
                        .foregroundStyle(BorealistaPalette.stone)

                    HStack(spacing: 8) {
                        Label(course.schedule, systemImage: "clock")
                        Text("•")
                        Text(course.room)
                    }
                    .font(BorealistaType.body(12))
                    .foregroundStyle(BorealistaPalette.cocoa)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 10) {
                    Text(course.code)
                        .font(BorealistaType.code(11))
                        .foregroundStyle(BorealistaPalette.stone)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BorealistaPalette.cedar)
                }
            }
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.18))

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.82),
                                    BorealistaPalette.courseTint(course.accent).opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(BorealistaPalette.line.opacity(0.26), lineWidth: 0.8)
            )
            .shadow(color: BorealistaPalette.espresso.opacity(0.06), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(BorealistaType.code(11))
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.18), lineWidth: 0.8)
            )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BorealistaPalette.cedar)
                .frame(width: 16)

            Text(title)
                .font(BorealistaType.body(14))
                .foregroundStyle(BorealistaPalette.stone)

            Spacer()

            Text(value)
                .font(BorealistaType.heading(15))
                .foregroundStyle(BorealistaPalette.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SoftSearchBar: View {
    @Binding var text: String
    var prompt: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(BorealistaPalette.stone)
            TextField(prompt, text: $text)
                .textInputAutocapitalization(.words)
        }
        .font(BorealistaType.body(15))
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1)
        )
    }
}

struct PillTag: View {
    let title: String
    var isActive = false

    var body: some View {
        Text(title)
            .font(BorealistaType.code(12))
            .foregroundStyle(isActive ? Color.white : BorealistaPalette.stone)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(
                        isActive
                        ? AnyShapeStyle(BorealistaPalette.buttonFill)
                        : AnyShapeStyle(Color.white.opacity(0.62))
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.white.opacity(0.14) : BorealistaPalette.line.opacity(0.36), lineWidth: 0.8)
            )
    }
}

struct StudentTabBar: View {
    @Binding var selection: StudentTab

    var body: some View {
        HStack(spacing: 8) {
            StudentTabButton(icon: "qrcode.viewfinder", label: "ID", tab: .identifier, selection: $selection)
            StudentTabButton(icon: "books.vertical", label: "Clases", tab: .classes, selection: $selection)
            StudentTabButton(icon: "exclamationmark.bubble", label: "Faltas", tab: .absences, selection: $selection)
            StudentTabButton(icon: "person.crop.circle", label: "Perfil", tab: .profile, selection: $selection)
        }
        .padding(8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.84), BorealistaPalette.pearl.opacity(0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(BorealistaPalette.line.opacity(0.30), lineWidth: 0.8)
        )
        .shadow(color: BorealistaPalette.espresso.opacity(0.10), radius: 24, y: 12)
    }
}

struct StudentTabButton: View {
    let icon: String
    let label: String
    let tab: StudentTab
    @Binding var selection: StudentTab

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Circle()
                    .fill(selection == tab ? BorealistaPalette.cedar : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .foregroundStyle(selection == tab ? BorealistaPalette.cedar : BorealistaPalette.stone)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selection == tab ? BorealistaPalette.blush.opacity(0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct TeacherTabBar: View {
    @Binding var selection: TeacherTab

    var body: some View {
        HStack(spacing: 8) {
            TeacherTabButton(icon: "rectangle.stack", label: "Clases", tab: .classes, selection: $selection)
            TeacherTabButton(icon: "checklist", label: "Justificantes", tab: .justifications, selection: $selection)
            TeacherTabButton(icon: "person.crop.circle", label: "Perfil", tab: .profile, selection: $selection)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.80), lineWidth: 1)
        )
        .shadow(color: BorealistaPalette.espresso.opacity(0.10), radius: 24, y: 12)
    }
}

struct TeacherTabButton: View {
    let icon: String
    let label: String
    let tab: TeacherTab
    @Binding var selection: TeacherTab

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Circle()
                    .fill(selection == tab ? BorealistaPalette.cedar : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .foregroundStyle(selection == tab ? BorealistaPalette.cedar : BorealistaPalette.stone)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selection == tab ? BorealistaPalette.blush.opacity(0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct QRCodeView: View {
    let value: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Group {
            if let image = generateQRCode() {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.90), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(BorealistaPalette.line.opacity(0.44), lineWidth: 0.8)
                    )
                    .shadow(color: BorealistaPalette.espresso.opacity(0.08), radius: 18, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white)
            }
        }
    }

    private func generateQRCode() -> UIImage? {
        filter.setValue(Data(value.utf8), forKey: "inputMessage")
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

struct SectionCaption: View {
    let title: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(BorealistaType.display(24))
                .foregroundStyle(BorealistaPalette.wordmarkFill)
                .tracking(-0.6)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(BorealistaType.body(14))
                    .foregroundStyle(BorealistaPalette.stone)
            }
        }
    }
}
