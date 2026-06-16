import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

enum Palette {
    static let espresso = Color(nsColor: NSColor(srgbRed: 0.33, green: 0.17, blue: 0.16, alpha: 1))
    static let cedar = Color(nsColor: NSColor(srgbRed: 0.53, green: 0.21, blue: 0.19, alpha: 1))
    static let ember = Color(nsColor: NSColor(srgbRed: 0.68, green: 0.13, blue: 0.09, alpha: 1))
    static let blush = Color(nsColor: NSColor(srgbRed: 0.86, green: 0.61, blue: 0.61, alpha: 1))
    static let sand = Color(nsColor: NSColor(srgbRed: 0.85, green: 0.80, blue: 0.77, alpha: 1))
    static let mist = Color(nsColor: NSColor(srgbRed: 0.93, green: 0.90, blue: 0.89, alpha: 1))
    static let line = Color(nsColor: NSColor(srgbRed: 0.85, green: 0.80, blue: 0.78, alpha: 1))
    static let stone = Color(nsColor: NSColor(srgbRed: 0.66, green: 0.56, blue: 0.54, alpha: 1))
    static let paper = Color(nsColor: NSColor(srgbRed: 0.98, green: 0.97, blue: 0.96, alpha: 1))
    static let porcelain = Color(nsColor: NSColor(srgbRed: 1.0, green: 0.99, blue: 0.99, alpha: 1))
    static let forest = Color(nsColor: NSColor(srgbRed: 0.31, green: 0.48, blue: 0.38, alpha: 1))
    static let gold = Color(nsColor: NSColor(srgbRed: 0.82, green: 0.60, blue: 0.32, alpha: 1))

    static let canvas = LinearGradient(
        colors: [porcelain, paper, Color(nsColor: NSColor(srgbRed: 0.96, green: 0.94, blue: 0.93, alpha: 1))],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonFill = LinearGradient(
        colors: [Color(nsColor: NSColor(srgbRed: 0.80, green: 0.73, blue: 0.71, alpha: 1)), sand],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct ScreenShell<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Palette.canvas
                .ignoresSafeArea()

            Circle()
                .fill(Palette.blush.opacity(0.12))
                .frame(width: 210, height: 210)
                .blur(radius: 30)
                .offset(x: -110, y: -300)

            Circle()
                .fill(Palette.cedar.opacity(0.06))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: 140, y: 320)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
        }
        .frame(width: 390, height: 844)
    }
}

struct BrandMark: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + size.width * 0.10, y: rect.midY + size.height * 0.18))
            path.addCurve(
                to: CGPoint(x: rect.midX - size.width * 0.10, y: rect.midY - size.height * 0.18),
                control1: CGPoint(x: rect.minX + size.width * 0.02, y: rect.midY - size.height * 0.34),
                control2: CGPoint(x: rect.midX - size.width * 0.32, y: rect.minY + size.height * 0.12)
            )
            path.addCurve(
                to: CGPoint(x: rect.midX + size.width * 0.10, y: rect.midY - size.height * 0.18),
                control1: CGPoint(x: rect.midX - size.width * 0.02, y: rect.midY - size.height * 0.30),
                control2: CGPoint(x: rect.midX + size.width * 0.02, y: rect.midY - size.height * 0.30)
            )
            path.addCurve(
                to: CGPoint(x: rect.maxX - size.width * 0.10, y: rect.midY + size.height * 0.18),
                control1: CGPoint(x: rect.midX + size.width * 0.32, y: rect.minY + size.height * 0.12),
                control2: CGPoint(x: rect.maxX - size.width * 0.02, y: rect.midY - size.height * 0.34)
            )

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [Palette.espresso, Palette.cedar, Palette.blush]),
                    startPoint: CGPoint(x: 0, y: size.height / 2),
                    endPoint: CGPoint(x: size.width, y: size.height / 2)
                ),
                style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: 120, height: 72)
    }
}

struct Wordmark: View {
    var body: some View {
        HStack(spacing: 10) {
            BrandMark()
                .frame(width: 38, height: 22)
            Text("Borealista")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Palette.espresso)
        }
    }
}

struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Palette.mist.opacity(0.82),
                            Palette.blush.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Palette.line.opacity(0.8), lineWidth: 1)
        )
    }
}

struct PrimaryButton: View {
    let title: String

    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(Palette.buttonFill)
        )
    }
}

struct SecondaryButton: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.espresso)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.82))
            )
            .overlay(
                Capsule()
                    .stroke(Palette.line, lineWidth: 1)
            )
    }
}

struct Field: View {
    let title: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.cedar.opacity(0.84))
            Text(placeholder)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.stone)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.94))
                )
                .overlay(
                    Capsule()
                        .stroke(Palette.line.opacity(0.86), lineWidth: 1)
                )
        }
    }
}

struct HeaderBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Palette.stone)
            Text(title)
                .font(.system(size: 31, weight: .bold))
                .foregroundStyle(Palette.espresso)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.stone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TagView: View {
    let title: String
    var active = false

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(active ? Color.white : Palette.stone)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(active ? AnyShapeStyle(Palette.cedar) : AnyShapeStyle(Color.white.opacity(0.78)))
            )
    }
}

struct TabBar: View {
    let selectedIndex: Int

    let icons = ["qrcode.viewfinder", "books.vertical", "exclamationmark.bubble", "person.crop.circle"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(icons.enumerated()), id: \.offset) { item in
                VStack(spacing: 6) {
                    Image(systemName: item.element)
                        .font(.system(size: 18, weight: .semibold))
                    Circle()
                        .fill(selectedIndex == item.offset ? Palette.cedar : Color.clear)
                        .frame(width: 4, height: 4)
                }
                .foregroundStyle(selectedIndex == item.offset ? Palette.cedar : Palette.stone)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(selectedIndex == item.offset ? Palette.mist.opacity(0.95) : Color.clear)
                )
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Palette.line.opacity(0.88), lineWidth: 1)
        )
    }
}

struct MiniCourseCard: View {
    let title: String
    let subject: String
    let detail: String
    let code: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.cedar.opacity(0.12))
                Text(String(code.prefix(3)))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.cedar)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.espresso)
                Text(subject)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.stone)
                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.cedar.opacity(0.8))
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.cedar)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Palette.line.opacity(0.86), lineWidth: 1)
        )
    }
}

struct NoticeView: View {
    let title: String
    let message: String
    let tint: Color
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.espresso)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.stone)
            }
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(tint.opacity(0.24), lineWidth: 1)
        )
    }
}

struct ProfileAvatar: View {
    let initials: String
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.cedar)
            Text(initials)
                .font(.system(size: size * 0.30, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct LoginScreen: View {
    var body: some View {
        ScreenShell {
            VStack(spacing: 18) {
                BrandMark()
                    .padding(.top, 28)
                HStack(spacing: 8) {
                    Text("Alumno")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(Palette.cedar))
                    Text("Profesor")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.stone)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .padding(6)
                .background(Capsule().fill(Color.white.opacity(0.84)))
                .overlay(Capsule().stroke(Palette.line.opacity(0.86), lineWidth: 1))

                Text("Bienvenido de vuelta")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Palette.espresso)
                Text("Consulta tus clases, tu identificador digital y el historial de faltas desde una sola app.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.stone)
                    .multilineTextAlignment(.center)
            }

            Card {
                Text("Iniciar sesion")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Palette.espresso)
                Field(title: "Correo institucional", placeholder: "codex.90615015754@test.com")
                Field(title: "Contrasena", placeholder: "Password123")
                PrimaryButton(title: "Iniciar sesion")
            }

            Card {
                Text("Pruebas rapidas")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.espresso)
                Text("Si el backend no tiene materias o faltas para tu matricula, puedes abrir el flujo completo del alumno en modo demo.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.stone)
                SecondaryButton(title: "Entrar en modo demo")
            }

            Text("Aun no tienes cuenta? Registrate")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.espresso.opacity(0.78))
        }
    }
}

struct SignUpScreen: View {
    var body: some View {
        ScreenShell {
            VStack(spacing: 18) {
                BrandMark()
                    .padding(.top, 28)
                Text("Crea tu cuenta")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Palette.espresso)
                Text("Registra tu cuenta como alumno usando tu matricula institucional.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.stone)
                    .multilineTextAlignment(.center)
            }

            Card {
                Text("Registro")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Palette.espresso)
                Field(title: "Nombre completo", placeholder: "Codex Tester")
                Field(title: "Correo institucional", placeholder: "codex.90615015754@test.com")
                Field(title: "Matricula", placeholder: "90615015754")
                Field(title: "Contrasena", placeholder: "Password123")
                Field(title: "Confirmar contrasena", placeholder: "Password123")
                PrimaryButton(title: "Registrarme")
            }
        }
    }
}

struct ClassesScreen: View {
    var body: some View {
        ScreenShell {
            HStack {
                Wordmark()
                Spacer()
                Circle().fill(Color.white.opacity(0.8)).frame(width: 38, height: 38).overlay(Image(systemName: "arrow.clockwise").foregroundStyle(Palette.cedar))
                ProfileAvatar(initials: "CT", size: 54)
            }

            HeaderBlock(
                eyebrow: "Alumno",
                title: "Mis clases",
                subtitle: "Consulta tus materias, abre el detalle y sigue probando aunque el backend aun no tenga todos los campos."
            )

            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Codex Tester")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Palette.espresso)
                        Text("3 clases activas · 94% asistencia")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.stone)
                    }
                    Spacer()
                    TagView(title: "Alumno", active: true)
                }
            }

            NoticeView(
                title: "Clases en modo demo",
                message: "La matricula de prueba aun no tiene materias en backend. Se muestran tarjetas mock para completar el flujo visual.",
                tint: Palette.gold,
                icon: "exclamationmark.triangle.fill"
            )

            MiniCourseCard(title: "Matematicas avanzadas", subject: "Calculo y modelado", detail: "Lun/Mie/Vie · 8:00 - 10:00 · Aula 204", code: "MAT-402")
            MiniCourseCard(title: "Fisica experimental", subject: "Laboratorio y mecanica", detail: "Mar/Jue · 11:00 - 12:30 · Laboratorio 5", code: "PHY-210")
            MiniCourseCard(title: "Diseno de sistemas", subject: "Arquitectura de producto", detail: "Vie · 15:00 - 18:00 · Studio 3", code: "SYS-301")

            Spacer(minLength: 6)
            TabBar(selectedIndex: 1)
        }
    }
}

struct IdentifierScreen: View {
    var body: some View {
        ScreenShell {
            HeaderBlock(
                eyebrow: "Identificador",
                title: "Mi identificador",
                subtitle: "Tu QR se genera localmente con la matricula para que el flujo del alumno se pueda probar hoy mismo."
            )

            Card {
                HStack(spacing: 16) {
                    ProfileAvatar(initials: "CT")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Codex Tester")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Palette.espresso)
                        Text("codex.90615015754@test.com")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Palette.espresso.opacity(0.68))
                        Text("90615015754")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.cedar)
                    }
                }

                QRImageView(value: "90615015754")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                HStack(spacing: 10) {
                    TagView(title: "QR local", active: true)
                    TagView(title: "Listo para demo")
                }

                SecondaryButton(title: "Ver QR en grande")
            }

            NoticeView(
                title: "Flujo mock controlado",
                message: "Como el backend aun no expone un endpoint para generar el QR del alumno, esta vista construye el codigo usando la matricula disponible en sesion o demo.",
                tint: Palette.cedar,
                icon: "info.circle.fill"
            )

            Spacer(minLength: 6)
            TabBar(selectedIndex: 0)
        }
    }
}

struct AbsencesScreen: View {
    var body: some View {
        ScreenShell {
            HeaderBlock(
                eyebrow: "Asistencia",
                title: "Mis faltas",
                subtitle: "Consulta el historial actual y prueba el flujo de justificantes aun cuando el backend siga incompleto."
            )

            Card {
                StatRow(title: "Asistencia", value: "94%")
                StatRow(title: "Pendientes", value: "1")
                StatRow(title: "Resueltas", value: "1")
            }

            NoticeView(
                title: "Faltas en modo demo",
                message: "El backend aun no expone el historial de faltas del alumno ni attendance_id validos para todas las incidencias.",
                tint: Palette.gold,
                icon: "exclamationmark.triangle.fill"
            )

            AbsenceCard(title: "Matematicas avanzadas", date: "10 nov 2026 · 8:00 - 10:00", reason: "Justificante medico aprobado en demo", status: "Justificada", tint: Palette.forest, action: nil)
            AbsenceCard(title: "Fisica experimental", date: "3 nov 2026 · 11:00 - 12:30", reason: "Pendiente de justificar", status: "Falta", tint: Palette.ember, action: "Justificar falta")
            AbsenceCard(title: "Diseno de sistemas", date: "28 oct 2026 · 15:00 - 18:00", reason: "Llegada tarde por trafico", status: "Retardo", tint: Palette.gold, action: nil)

            Spacer(minLength: 6)
            TabBar(selectedIndex: 2)
        }
    }
}

struct ProfileScreen: View {
    var body: some View {
        ScreenShell {
            HeaderBlock(
                eyebrow: "Perfil",
                title: "Mi perfil",
                subtitle: "Informacion principal del alumno y acceso rapido para cerrar la sesion actual."
            )

            Card {
                HStack(spacing: 18) {
                    ProfileAvatar(initials: "CT", size: 88)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Codex Tester")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Palette.espresso)
                        Text("Alumno")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.cedar)
                        Text("Tablero academico Borealista")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Palette.espresso.opacity(0.7))
                    }
                }

                Divider()
                StatRow(title: "Correo institucional", value: "codex.90615015754@test.com")
                StatRow(title: "Matricula", value: "90615015754")
                StatRow(title: "Fuente actual", value: "Sesion almacenada")
            }

            NoticeView(
                title: "Clases en modo demo",
                message: "La experiencia del alumno ya puede probarse incluso cuando el backend no entrega todos los datos.",
                tint: Palette.gold,
                icon: "exclamationmark.triangle.fill"
            )

            PrimaryButton(title: "Cerrar sesion")

            Spacer(minLength: 6)
            TabBar(selectedIndex: 3)
        }
    }
}

struct AbsenceCard: View {
    let title: String
    let date: String
    let reason: String
    let status: String
    let tint: Color
    let action: String?

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "calendar").foregroundStyle(tint))

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Palette.espresso)
                        Spacer()
                        Text(status)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(tint.opacity(0.10)))
                    }
                    Text(date)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.cedar)
                    Text(reason)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Palette.stone)
                    if let action {
                        Text(action)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.ember)
                    }
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.stone)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.espresso)
        }
    }
}

struct QRImageView: View {
    let value: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Group {
            if let image = generate() {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Palette.line.opacity(0.75), lineWidth: 1)
                    )
            }
        }
        .frame(height: 270)
    }

    private func generate() -> NSImage? {
        filter.setValue(Data(value.utf8), forKey: "inputMessage")
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 11, y: 11))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let image = NSImage(size: size)
        image.addRepresentation(NSBitmapImageRep(cgImage: cgImage))
        return image
    }
}

@MainActor
func export<V: View>(_ view: V, to path: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3

    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fputs("No se pudo exportar \(path)\n", stderr)
        return
    }

    try? pngData.write(to: URL(fileURLWithPath: path))
}

@main
struct RenderStudentScreens {
    static func main() async {
        let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let outputURL = baseURL.appendingPathComponent("output/screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: outputURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        export(LoginScreen(), to: outputURL.appendingPathComponent("login.png").path)
        export(SignUpScreen(), to: outputURL.appendingPathComponent("signup.png").path)
        export(ClassesScreen(), to: outputURL.appendingPathComponent("classes.png").path)
        export(IdentifierScreen(), to: outputURL.appendingPathComponent("identifier.png").path)
        export(AbsencesScreen(), to: outputURL.appendingPathComponent("absences.png").path)
        export(ProfileScreen(), to: outputURL.appendingPathComponent("profile.png").path)
    }
}
