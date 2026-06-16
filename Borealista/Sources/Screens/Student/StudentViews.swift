import SwiftUI

enum StudentRoute: Hashable {
    case classDetail(Course)
    case justifyAbsence(AbsenceRecord)
    case confirmation(AbsenceRecord)
}

struct StudentShellView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var path: [StudentRoute] = []

    private var studentTabBinding: Binding<StudentTab> {
        Binding(
            get: { appModel.studentTab },
            set: { appModel.studentTab = $0 }
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Group {
                    switch appModel.studentTab {
                    case .identifier:
                        StudentIdentifierView()
                    case .classes:
                        StudentHomeView { route in
                            path.append(route)
                        }
                    case .absences:
                        StudentAbsencesView { route in
                            path.append(route)
                        }
                    case .profile:
                        StudentProfileView()
                    }
                }
                .toolbar(.hidden, for: .navigationBar)

                StudentTabBar(selection: studentTabBinding)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
            .navigationDestination(for: StudentRoute.self) { route in
                switch route {
                case let .classDetail(course):
                    StudentClassDetailView(course: course)
                case let .justifyAbsence(record):
                    JustifyAbsenceView(record: record) { updatedRecord in
                        path.append(.confirmation(updatedRecord))
                    }
                case let .confirmation(record):
                    JustificationConfirmationView(record: record)
                }
            }
        }
        .task {
            await appModel.ensureStudentDataLoaded()
            if let startupRoute = appModel.consumeStartupStudentRoute(), path.isEmpty {
                path = [startupRoute]
            }
        }
    }
}

struct StudentHomeView: View {
    @EnvironmentObject private var appModel: AppModel
    let navigate: (StudentRoute) -> Void

    var body: some View {
        ShellScrollView {
            HStack {
                BrandWordmark(logoWidth: 72, fontSize: 34)
                Spacer()
                IconChromeButton(systemImage: "arrow.clockwise") {
                    Task {
                        await appModel.refreshStudentData()
                    }
                }
                ProfileAvatar(initials: appModel.currentStudentProfile.initials, diameter: 54)
            }

            ScreenHeader(
                eyebrow: "Alumno",
                title: "Mis clases",
                subtitle: nil
            )

            PremiumCard(accentOpacity: 0.08, padding: 20) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appModel.currentStudentProfile.name)
                            .font(BorealistaType.heading(18))
                            .foregroundStyle(BorealistaPalette.ink)
                        Text(appModel.studentStatusSummary)
                            .font(BorealistaType.body(13))
                            .foregroundStyle(BorealistaPalette.stone)
                    }

                    Spacer()

                    BorealistaMark(width: 96)
                }
            }

            if let notice = appModel.studentCoursesNotice {
                NoticeCard(notice: notice)
            }

            SectionCaption(title: "Activas", detail: nil)

            if appModel.isLoadingStudentData, appModel.studentCourses.isEmpty {
                LoadingStateCard(
                    title: "Cargando tus clases",
                    message: "Sincronizando"
                )
            } else if appModel.studentCourses.isEmpty {
                EmptyStateCard(
                    title: "Sin clases por ahora",
                    message: "Aun no hay materias disponibles."
                )
            } else {
                ForEach(appModel.studentCourses) { course in
                    CourseCard(course: course) {
                        navigate(.classDetail(course))
                    }
                }
            }
        }
    }
}

struct StudentClassDetailView: View {
    let course: Course

    var body: some View {
        ShellScrollView {
            PremiumCard(accentOpacity: 0.2) {
                Text(course.code)
                    .font(BorealistaType.code(12))
                    .tracking(2)
                    .foregroundStyle(BorealistaPalette.cedar)

                Text(course.title)
                    .font(BorealistaType.display(31))
                    .foregroundStyle(BorealistaPalette.wordmarkFill)

                Text(course.summary)
                    .font(BorealistaType.body(15))
                    .foregroundStyle(BorealistaPalette.stone)

                Divider()

                InfoRow(icon: "person.fill", title: "Profesor", value: course.instructor)
                InfoRow(icon: "calendar", title: "Periodo", value: course.term)
                InfoRow(icon: "clock.fill", title: "Horario", value: course.schedule)
                InfoRow(icon: "building.2.fill", title: "Aula", value: course.room)
            }

            PremiumCard {
                SectionCaption(title: "Detalle", detail: nil)

                HStack(spacing: 10) {
                    PillTag(title: course.team, isActive: true)
                    PillTag(title: course.code)
                    if course.studentsCount > 0 {
                        PillTag(title: "\(course.studentsCount) companeros")
                    }
                }
            }
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StudentIdentifierView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var showsExpandedQR = false

    var body: some View {
        ShellScrollView {
            ScreenHeader(
                eyebrow: "Identificador",
                title: "Mi identificador",
                subtitle: nil
            )

            PremiumCard(accentOpacity: 0.2) {
                HStack(spacing: 16) {
                    ProfileAvatar(initials: appModel.currentStudentProfile.initials)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(appModel.currentStudentProfile.name)
                            .font(BorealistaType.display(23))
                            .foregroundStyle(BorealistaPalette.wordmarkFill)
                            .lineLimit(3)
                            .minimumScaleFactor(0.82)
                        Text(appModel.currentStudentProfile.email)
                            .font(BorealistaType.body(14))
                            .foregroundStyle(BorealistaPalette.stone)
                            .lineLimit(2)
                            .minimumScaleFactor(0.84)
                        Text(appModel.currentStudentProfile.id)
                            .font(BorealistaType.code(13))
                            .foregroundStyle(BorealistaPalette.cedar)
                    }

                    Spacer()

                    BorealistaMark(width: 72)
                }

                QRCodeView(value: appModel.currentStudentQRCode)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                HStack(spacing: 10) {
                    PillTag(title: "ID digital", isActive: true)
                    PillTag(title: "Borealista")
                }

                SecondaryActionButton(title: "Ver QR") {
                    showsExpandedQR = true
                }
            }
        }
        .sheet(isPresented: $showsExpandedQR) {
            QRPreviewSheetView(profile: appModel.currentStudentProfile, qrValue: appModel.currentStudentQRCode)
        }
    }
}

struct StudentAbsencesView: View {
    @EnvironmentObject private var appModel: AppModel
    let navigate: (StudentRoute) -> Void

    var body: some View {
        ShellScrollView {
            ScreenHeader(
                eyebrow: "Asistencia",
                title: "Mis faltas",
                subtitle: nil
            )

            PremiumCard {
                InfoRow(icon: "waveform.path.ecg", title: "Asistencia", value: appModel.studentAttendanceRateLabel)
                InfoRow(icon: "exclamationmark.circle", title: "Pendientes", value: "\(appModel.studentPendingAbsenceCount)")
                InfoRow(icon: "checkmark.circle", title: "Resueltas", value: "\(appModel.studentResolvedAbsenceCount)")
            }

            if let notice = appModel.studentAbsencesNotice {
                NoticeCard(notice: notice)
            }

            if appModel.studentAbsences.isEmpty {
                EmptyStateCard(
                    title: "Sin registros por ahora",
                    message: "Cuando existan asistencias o faltas apareceran aqui."
                )
            } else {
                ForEach(appModel.studentAbsences) { record in
                    AbsenceCard(
                        record: record,
                        actionTitle: record.status == .absent ? "Justificar falta" : nil,
                        action: record.status == .absent ? { navigate(.justifyAbsence(record)) } : nil
                    )
                }
            }
        }
    }
}

struct JustifyAbsenceView: View {
    @EnvironmentObject private var appModel: AppModel
    let record: AbsenceRecord
    let onSubmit: (AbsenceRecord) -> Void

    @State private var selectedReason = "Cita medica"
    @State private var evidenceReference = ""
    @State private var notes = ""
    @State private var localErrorMessage: String?

    private let reasonOptions = [
        "Cita medica",
        "Transporte",
        "Asunto familiar",
        "Otro"
    ]

    var body: some View {
        ShellScrollView {
            ScreenHeader(
                eyebrow: "Justificante",
                title: "Justificar falta",
                subtitle: nil
            )

            PremiumCard {
                InfoRow(icon: "book.closed.fill", title: "Clase", value: record.courseTitle)
                InfoRow(icon: "calendar", title: "Fecha", value: record.date)
                InfoRow(icon: "clock.fill", title: "Horario", value: record.time)
            }

            PremiumCard(accentOpacity: 0.18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Motivo")
                        .font(BorealistaType.label(12))
                        .foregroundStyle(BorealistaPalette.cedar.opacity(0.8))

                    Picker("Motivo", selection: $selectedReason) {
                        ForEach(reasonOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                FormField(
                    title: "Referencia del comprobante",
                    icon: "paperclip",
                    text: $evidenceReference,
                    prompt: "Ej. constancia-medica.pdf"
                )

                MultilineField(
                    title: "Descripcion",
                    icon: "square.and.pencil",
                    text: $notes,
                    prompt: "Agrega detalles utiles para revisar el justificante."
                )

                if let localErrorMessage {
                    Text(localErrorMessage)
                        .font(BorealistaType.heading(13))
                        .foregroundStyle(BorealistaPalette.ember)
                }

                PrimaryActionButton(
                    title: appModel.isSubmittingJustification ? "Enviando..." : "Enviar justificante",
                    systemImage: "checkmark",
                    isDisabled: appModel.isSubmittingJustification
                ) {
                    Task {
                        await submitJustification()
                    }
                }
            }
        }
        .navigationTitle("Justificar falta")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submitJustification() async {
        localErrorMessage = nil

        let enrichedReason: String
        if evidenceReference.trimmed.isEmpty {
            enrichedReason = selectedReason
        } else {
            enrichedReason = "\(selectedReason) · Evidencia: \(evidenceReference.trimmed)"
        }

        do {
            let updatedRecord = try await appModel.submitJustification(
                for: record,
                reason: enrichedReason,
                notes: notes
            )
            onSubmit(updatedRecord)
        } catch {
            localErrorMessage = error.localizedDescription
        }
    }
}

struct JustificationConfirmationView: View {
    @EnvironmentObject private var appModel: AppModel
    let record: AbsenceRecord

    var body: some View {
        ShellScrollView {
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(BorealistaPalette.courseGradient("sunrise"))
                        .frame(width: 108, height: 108)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 36)

                Text("Justificante enviado")
                    .font(BorealistaType.display(34))
                    .foregroundStyle(BorealistaPalette.wordmarkFill)

                Text("En revision")
                    .font(BorealistaType.body(15))
                    .foregroundStyle(BorealistaPalette.stone)
                    .multilineTextAlignment(.center)

                PremiumCard {
                    InfoRow(icon: "book.closed.fill", title: "Clase", value: record.courseTitle)
                    InfoRow(icon: "calendar", title: "Fecha", value: record.date)
                    InfoRow(icon: "checkmark.seal.fill", title: "Estado", value: record.status.rawValue)
                }
            }
        }
        .navigationTitle("Confirmacion")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StudentProfileView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ShellScrollView {
            ScreenHeader(
                eyebrow: "Perfil",
                title: "Mi perfil",
                subtitle: nil
            )

            PremiumCard(accentOpacity: 0.18) {
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 18) {
                        ProfileAvatar(initials: appModel.currentStudentProfile.initials, diameter: 88)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(appModel.currentStudentProfile.name)
                                .font(BorealistaType.display(24))
                                .foregroundStyle(BorealistaPalette.wordmarkFill)
                                .lineLimit(2)
                                .minimumScaleFactor(0.76)
                            Text(appModel.currentStudentProfile.role)
                                .font(BorealistaType.code(14))
                                .foregroundStyle(BorealistaPalette.cedar)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    BorealistaMark(width: 80)
                        .padding(.top, 2)
                }

                Divider()

                ProfileDetailRow(title: "Correo institucional", value: appModel.currentStudentProfile.email)
                ProfileDetailRow(title: "Matricula", value: appModel.currentStudentProfile.id)
            }

            PrimaryActionButton(title: "Cerrar sesion", systemImage: "rectangle.portrait.and.arrow.right") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    appModel.signOut()
                }
            }
        }
    }
}

private struct QRPreviewSheetView: View {
    let profile: UserProfile
    let qrValue: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                VStack(spacing: 24) {
                    BorealistaMark(width: 120)
                    ProfileAvatar(initials: profile.initials, diameter: 96)

                    VStack(spacing: 6) {
                        Text(profile.name)
                            .font(BorealistaType.display(26))
                            .foregroundStyle(BorealistaPalette.wordmarkFill)
                        Text(profile.id)
                            .font(BorealistaType.code(14))
                            .foregroundStyle(BorealistaPalette.cedar)
                    }

                    QRCodeView(value: qrValue)
                        .frame(maxWidth: 320)

                    Text("ID digital")
                        .font(BorealistaType.body(15))
                        .foregroundStyle(BorealistaPalette.stone)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(BorealistaPalette.cedar)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
