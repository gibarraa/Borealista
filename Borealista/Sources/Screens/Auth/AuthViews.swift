import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject private var appModel: AppModel

    private var selectedRole: Binding<AppRole> {
        Binding(
            get: { appModel.selectedRole },
            set: { appModel.selectedRole = $0 }
        )
    }

    var body: some View {
        ZStack {
            PremiumBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    VStack(spacing: 18) {
                        BrandHero()
                            .padding(.top, 34)

                        RolePicker(selectedRole: selectedRole)
                            .padding(.top, 8)

                        VStack(spacing: 10) {
                            Text(appModel.authMode == .signIn ? "Bienvenido de vuelta" : "Crea tu cuenta")
                                .font(BorealistaType.display(32))
                                .foregroundStyle(BorealistaPalette.wordmarkFill)
                                .tracking(-0.8)

                            if !appModel.selectedRole.subtitle.isEmpty {
                                Text(appModel.selectedRole.subtitle)
                                    .font(BorealistaType.body(15))
                                    .foregroundStyle(BorealistaPalette.stone)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    PremiumCard(accentOpacity: 0.16, padding: 26) {
                        if appModel.authMode == .signIn {
                            signInFields
                        } else {
                            signUpFields
                        }
                    }

                    authFooter
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
        .alert(item: $appModel.alertContext) { context in
            Alert(
                title: Text(context.title),
                message: Text(context.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }

    private var signInFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Acceso")
                .font(BorealistaType.display(25))
                .foregroundStyle(BorealistaPalette.wordmarkFill)

            FormField(
                title: "Correo institucional",
                icon: "envelope.fill",
                text: Binding(
                    get: { appModel.loginEmail },
                    set: { appModel.loginEmail = $0 }
                ),
                prompt: "nombre@borealista.edu",
                keyboardType: .emailAddress
            )

            FormField(
                title: "Contrasena",
                icon: "lock.fill",
                text: Binding(
                    get: { appModel.loginPassword },
                    set: { appModel.loginPassword = $0 }
                ),
                prompt: "Tu contrasena",
                secure: true
            )

            PrimaryActionButton(
                title: "Iniciar sesion",
                systemImage: "arrow.right",
                isDisabled: appModel.isAuthenticating
            ) {
                Task {
                    await appModel.signIn()
                }
            }
            .overlay(alignment: .center) {
                if appModel.isAuthenticating {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }

    private var signUpFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Registro")
                .font(BorealistaType.display(25))
                .foregroundStyle(BorealistaPalette.wordmarkFill)

            FormField(
                title: "Nombre completo",
                icon: "person.fill",
                text: Binding(
                    get: { appModel.registerName },
                    set: { appModel.registerName = $0 }
                ),
                prompt: "Tu nombre y apellido",
                autocapitalization: .words
            )

            FormField(
                title: "Correo institucional",
                icon: "envelope.fill",
                text: Binding(
                    get: { appModel.registerEmail },
                    set: { appModel.registerEmail = $0 }
                ),
                prompt: "nombre@borealista.edu",
                keyboardType: .emailAddress
            )

            if appModel.selectedRole == .student {
                FormField(
                    title: "Matricula",
                    icon: "number.square.fill",
                    text: Binding(
                        get: { appModel.registerID },
                        set: { appModel.registerID = $0 }
                    ),
                    prompt: "Tu matricula",
                    keyboardType: .numberPad
                )
            }

            FormField(
                title: "Contrasena",
                icon: "lock.fill",
                text: Binding(
                    get: { appModel.registerPassword },
                    set: { appModel.registerPassword = $0 }
                ),
                prompt: "Crea una contrasena",
                secure: true
            )

            FormField(
                title: "Confirmar contrasena",
                icon: "checkmark.shield.fill",
                text: Binding(
                    get: { appModel.registerConfirmPassword },
                    set: { appModel.registerConfirmPassword = $0 }
                ),
                prompt: "Confirma tu contrasena",
                secure: true
            )

            PrimaryActionButton(
                title: "Registrarme",
                systemImage: "arrow.right",
                isDisabled: appModel.isAuthenticating
            ) {
                Task {
                    await appModel.register()
                }
            }
            .overlay(alignment: .center) {
                if appModel.isAuthenticating {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }

    private var authFooter: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appModel.authMode = appModel.authMode == .signIn ? .signUp : .signIn
            }
        } label: {
            HStack(spacing: 4) {
                Text(appModel.authMode == .signIn ? "Aun no tienes cuenta?" : "Ya tienes cuenta?")
                Text(appModel.authMode == .signIn ? "Registrate" : "Inicia sesion")
                    .fontWeight(.bold)
            }
            .font(BorealistaType.body(14))
            .foregroundStyle(BorealistaPalette.ink.opacity(0.78))
        }
        .buttonStyle(.plain)
    }
}
