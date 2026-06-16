import Foundation
import SwiftUI

enum AppRole: String, CaseIterable, Identifiable {
    case student = "Alumno"
    case teacher = "Profesor"

    var id: Self { self }

    var title: String {
        switch self {
        case .student:
            "Borealista Alumno"
        case .teacher:
            "Borealista Profesor"
        }
    }

    var subtitle: String {
        switch self {
        case .student:
            ""
        case .teacher:
            ""
        }
    }

    var apiRole: APIUserRole {
        switch self {
        case .student:
            .student
        case .teacher:
            .teacher
        }
    }
}

enum AuthMode {
    case signIn
    case signUp
}

enum SessionState {
    case student
    case teacher
}

enum StudentTab: Hashable {
    case identifier
    case classes
    case absences
    case profile
}

enum TeacherTab: Hashable {
    case classes
    case justifications
    case profile
}

enum ScreenshotMode: String {
    case login
    case signUp = "signup"
    case classes
    case identifier
    case absences
    case profile
    case classDetail = "class-detail"
    case justify
    case confirmation
    case teacherClasses = "teacher-classes"
    case teacherJustifications = "teacher-justifications"
    case teacherProfile = "teacher-profile"
    case teacherClassDetail = "teacher-class-detail"
    case teacherRoster = "teacher-roster"
    case teacherAttendance = "teacher-attendance"
}

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedRole: AppRole = .student
    @Published var authMode: AuthMode = .signIn
    @Published var sessionState: SessionState?
    @Published var studentTab: StudentTab = .classes
    @Published var teacherTab: TeacherTab = .classes

    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var registerName = ""
    @Published var registerEmail = ""
    @Published var registerID = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""

    @Published private(set) var activeSession: StudentSession?
    @Published private(set) var studentCourses: [Course]
    @Published private(set) var studentAbsences: [AbsenceRecord]
    @Published private(set) var studentCoursesNotice: ScreenNotice?
    @Published private(set) var studentAbsencesNotice: ScreenNotice?
    @Published private(set) var isStudentDataLoaded = false

    @Published private(set) var teacherCourses: [TeacherManagedCourse]
    @Published private(set) var teacherJustifications: [JustificationRecord]
    @Published private(set) var teacherProfile: UserProfile
    @Published private(set) var isTeacherDataLoaded = false

    @Published var isAuthenticating = false
    @Published var isLoadingStudentData = false
    @Published var isLoadingTeacherData = false
    @Published var isSubmittingJustification = false
    @Published var alertContext: AlertContext?
    @Published var lastJustificationContext: JustificationSubmissionContext?
    @Published var startupStudentRoute: StudentRoute?
    @Published var startupTeacherRoute: TeacherRoute?
    @Published private(set) var activeScreenshotMode: ScreenshotMode?

    private let screenshotStore = MockDataStore()
    private let api = BorealistaAPI()
    private let sessionStorage = BorealistaSessionStorage()
    private let courseAccents = ["sunrise", "forest", "cedar"]

    init() {
        studentCourses = []
        studentAbsences = []
        studentCoursesNotice = nil
        studentAbsencesNotice = nil
        teacherCourses = []
        teacherJustifications = []
        teacherProfile = AppModel.placeholderTeacherProfile

        restorePersistedSession()
        applyScreenshotModeIfNeeded()
    }

    var currentStudentProfile: UserProfile {
        guard let activeSession, activeSession.role == .student else {
            return AppModel.placeholderStudentProfile
        }

        return .student(from: activeSession)
    }

    var currentStudentQRCode: String {
        activeSession?.code ?? currentStudentProfile.id
    }

    var currentTeacherProfile: UserProfile {
        if let activeSession, activeSession.role == .teacher {
            return .teacher(from: activeSession, detail: teacherDetailSummary)
        }

        return teacherProfile
    }

    var studentStatusSummary: String {
        guard !studentCourses.isEmpty else {
            return "Sin clases activas"
        }

        if studentAbsences.isEmpty {
            return "\(studentCourses.count) clases activas · Sin incidencias"
        }

        return "\(studentCourses.count) clases activas · \(studentPendingAbsenceCount) incidencias"
    }

    var studentAttendanceRateLabel: String {
        guard !studentAbsences.isEmpty else {
            return "--"
        }

        let successfulStatuses: Set<AttendanceState> = [.present, .late, .justified]
        let successfulCount = studentAbsences.filter { successfulStatuses.contains($0.status) }.count
        let percentage = Int(round((Double(successfulCount) / Double(studentAbsences.count)) * 100))
        return "\(percentage)%"
    }

    var studentPendingAbsenceCount: Int {
        studentAbsences.filter { $0.status == .pending || $0.status == .absent }.count
    }

    var studentResolvedAbsenceCount: Int {
        studentAbsences.filter { $0.status == .justified }.count
    }

    var teacherPendingJustificationCount: Int {
        teacherJustifications.filter { $0.status == .pending }.count
    }

    var teacherStudentCount: Int {
        teacherCourses.reduce(0) { partialResult, course in
            partialResult + course.students.count
        }
    }

    var isScreenshotPreview: Bool {
        activeScreenshotMode != nil
    }

    func ensureStudentDataLoaded(force: Bool = false) async {
        guard sessionState == .student else {
            return
        }

        if !force, isStudentDataLoaded {
            return
        }

        await loadStudentExperience()
    }

    func ensureTeacherDataLoaded(force: Bool = false) async {
        guard sessionState == .teacher else {
            return
        }

        if !force, isTeacherDataLoaded {
            return
        }

        await loadTeacherExperience()
    }

    func signIn() async {
        alertContext = nil

        guard !loginEmail.trimmed.isEmpty, !loginPassword.trimmed.isEmpty else {
            alertContext = AlertContext(
                title: "Datos incompletos",
                message: "Escribe tu correo institucional y tu contraseña para continuar."
            )
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let session = try await api.login(
                email: loginEmail.trimmed,
                password: loginPassword.trimmed,
                role: selectedRole.apiRole
            )

            completeAuthentication(session, persist: true)

            switch session.role {
            case .student:
                await loadStudentExperience()
            case .teacher:
                await loadTeacherExperience()
            }
        } catch {
            alertContext = AlertContext(
                title: "No fue posible iniciar sesion",
                message: error.localizedDescription
            )
        }
    }

    func register() async {
        alertContext = nil

        let fullName = registerName.trimmed
        let email = registerEmail.trimmed
        let identifier = registerID.trimmed
        let password = registerPassword.trimmed
        let confirmPassword = registerConfirmPassword.trimmed

        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertContext = AlertContext(
                title: "Datos incompletos",
                message: selectedRole == .student
                    ? "Completa tu nombre, correo, matricula y contraseña antes de registrarte."
                    : "Completa tu nombre, correo y contraseña antes de registrarte."
            )
            return
        }

        if selectedRole == .student, identifier.isEmpty {
            alertContext = AlertContext(
                title: "Matricula requerida",
                message: "Escribe tu matricula para registrar al alumno."
            )
            return
        }

        guard password == confirmPassword else {
            alertContext = AlertContext(
                title: "Contraseñas distintas",
                message: "La confirmacion de contraseña no coincide. Corrigela para continuar."
            )
            return
        }

        guard let splitName = splitName(fullName) else {
            alertContext = AlertContext(
                title: "Nombre incompleto",
                message: "Escribe al menos nombre y apellido para registrarte."
            )
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            try await api.register(
                role: selectedRole.apiRole,
                studentCode: selectedRole == .student ? identifier : nil,
                firstName: splitName.firstName,
                lastName: splitName.lastName,
                email: email,
                password: password
            )

            loginEmail = email
            loginPassword = password
            authMode = .signIn

            let session = try await api.login(
                email: email,
                password: password,
                role: selectedRole.apiRole
            )

            completeAuthentication(session, persist: true)

            switch session.role {
            case .student:
                await loadStudentExperience()
            case .teacher:
                await loadTeacherExperience()
            }
        } catch {
            alertContext = AlertContext(
                title: "No fue posible registrarte",
                message: error.localizedDescription
            )
        }
    }

    func continueWithDemoSession() {
        let parts = screenshotStore.studentProfile.name
            .split(separator: " ")
            .map(String.init)
        let firstName = parts.dropLast().joined(separator: " ").trimmed
        let lastName = parts.last?.trimmed ?? "Alumno"

        let session = StudentSession(
            id: 0,
            code: screenshotStore.studentProfile.id,
            firstName: firstName.isEmpty ? "Alumno" : firstName,
            lastName: lastName,
            email: screenshotStore.studentProfile.email,
            role: .student
        )

        completeAuthentication(session, persist: false)
        configureStudentDemoData()
        isStudentDataLoaded = true
        loginEmail = session.email
    }

    func continueWithTeacherScreenshotSession() {
        let parts = screenshotStore.teacherProfile.name
            .split(separator: " ")
            .map(String.init)
        let firstName = parts.dropLast().joined(separator: " ").trimmed
        let lastName = parts.last?.trimmed ?? "Profesor"

        let session = StudentSession(
            id: 1,
            code: screenshotStore.teacherProfile.id,
            firstName: firstName.isEmpty ? "Profesor" : firstName,
            lastName: lastName,
            email: screenshotStore.teacherProfile.email,
            role: .teacher
        )

        completeAuthentication(session, persist: false)
        configureTeacherScreenshotData()
        isTeacherDataLoaded = true
        loginEmail = session.email
    }

    func refreshStudentData() async {
        await ensureStudentDataLoaded(force: true)
    }

    func refreshTeacherData() async {
        await ensureTeacherDataLoaded(force: true)
    }

    func teacherCourse(id: UUID) -> TeacherManagedCourse? {
        teacherCourses.first(where: { $0.id == id })
    }

    func addTeacherCourse(from draft: TeacherCourseDraft) async throws {
        let teacherSession = try validatedTeacherSession()
        let request = try makeTeacherCourseRequest(
            from: draft,
            suggestedCourseCode: generatedCourseCode(
                from: draft.name,
                classroom: draft.classroom,
                groupName: draft.groupName,
                seed: teacherCourses.count + 1
            ),
            teacherID: teacherSession.id
        )

        let remoteCourse = try await api.createTeacherCourse(request)
        teacherCourses.insert(
            remoteCourse.asTeacherManagedCourse(accent: draft.accent),
            at: 0
        )
    }

    func updateTeacherCourse(id: UUID, with draft: TeacherCourseDraft) async throws {
        guard let index = teacherCourses.firstIndex(where: { $0.id == id }) else {
            throw BorealistaAPIError.invalidInput("No se encontro la clase que intentas editar.")
        }

        let existingCourse = teacherCourses[index]
        let request = try makeTeacherCourseRequest(
            from: draft,
            suggestedCourseCode: generatedCourseCode(
                from: draft.name,
                classroom: draft.classroom,
                groupName: draft.groupName,
                seed: existingCourse.courseID
            ),
            teacherID: try validatedTeacherSession().id
        )

        let remoteCourse = try await api.updateTeacherCourse(
            courseID: existingCourse.courseID,
            request: request
        )

        teacherCourses[index] = remoteCourse.asTeacherManagedCourse(
            accent: draft.accent.isEmpty ? existingCourse.accent : draft.accent
        )
    }

    func deleteTeacherCourse(id: UUID) async throws {
        guard let index = teacherCourses.firstIndex(where: { $0.id == id }) else {
            throw BorealistaAPIError.invalidInput("No se encontro la clase que intentas eliminar.")
        }

        let course = teacherCourses[index]
        try await api.deleteTeacherCourse(courseID: course.courseID)
        teacherCourses.remove(at: index)
    }

    func addStudent(studentCode: String, to courseID: UUID) async throws {
        let normalizedCode = studentCode.trimmed

        guard !normalizedCode.isEmpty else {
            throw BorealistaAPIError.invalidInput("Escribe la matricula del alumno antes de agregarlo.")
        }

        guard let index = teacherCourses.firstIndex(where: { $0.id == courseID }) else {
            throw BorealistaAPIError.invalidInput("No se encontro el grupo al que intentas agregar el alumno.")
        }

        if teacherCourses[index].students.contains(where: { $0.idCode == normalizedCode }) {
            throw BorealistaAPIError.invalidInput("Ese alumno ya existe dentro del grupo actual.")
        }

        let student = try await api.addStudentToCourse(
            courseID: teacherCourses[index].courseID,
            studentCode: normalizedCode
        )

        teacherCourses[index].students.append(student.asStudentRecord())
    }

    func removeStudent(_ studentID: UUID, from courseID: UUID) async throws {
        guard let courseIndex = teacherCourses.firstIndex(where: { $0.id == courseID }) else {
            throw BorealistaAPIError.invalidInput("No se encontro el grupo.")
        }

        guard let studentIndex = teacherCourses[courseIndex].students.firstIndex(where: { $0.id == studentID }) else {
            throw BorealistaAPIError.invalidInput("No se encontro el alumno que intentas eliminar.")
        }

        let studentCode = teacherCourses[courseIndex].students[studentIndex].idCode
        try await api.removeStudentFromCourse(
            courseID: teacherCourses[courseIndex].courseID,
            studentCode: studentCode
        )
        teacherCourses[courseIndex].students.remove(at: studentIndex)
    }

    func updateAttendance(for studentID: UUID, in courseID: UUID, state: AttendanceState) {
        guard let courseIndex = teacherCourses.firstIndex(where: { $0.id == courseID }),
              let studentIndex = teacherCourses[courseIndex].students.firstIndex(where: { $0.id == studentID }) else {
            return
        }

        let existing = teacherCourses[courseIndex].students[studentIndex]
        teacherCourses[courseIndex].students[studentIndex] = StudentRecord(
            id: existing.id,
            name: existing.name,
            idCode: existing.idCode,
            attendance: state,
            streak: existing.streak
        )
    }

    func startAttendanceSession(for courseID: UUID) async throws -> APITeacherAttendanceSession {
        let teacherSession = try validatedTeacherSession()

        guard let course = teacherCourses.first(where: { $0.id == courseID }) else {
            throw BorealistaAPIError.invalidInput("No se encontro la clase seleccionada para tomar asistencia.")
        }

        return try await api.startTeacherAttendanceSession(
            teacherID: teacherSession.id,
            courseID: course.courseID
        )
    }

    func registerAttendanceScan(studentCode: String, in courseID: UUID, sessionID: Int) async throws -> StudentRecord {
        let normalizedCode = studentCode.trimmed

        guard !normalizedCode.isEmpty else {
            throw BorealistaAPIError.invalidInput("Escanea o escribe una matricula valida para registrar la asistencia.")
        }

        guard let courseIndex = teacherCourses.firstIndex(where: { $0.id == courseID }) else {
            throw BorealistaAPIError.invalidInput("No se encontro la clase seleccionada para tomar asistencia.")
        }

        guard let studentIndex = teacherCourses[courseIndex].students.firstIndex(where: { $0.idCode == normalizedCode }) else {
            throw BorealistaAPIError.invalidInput("La matricula \(normalizedCode) no pertenece a este grupo.")
        }

        _ = try await api.scanTeacherAttendance(
            sessionID: sessionID,
            studentCode: normalizedCode
        )

        let existing = teacherCourses[courseIndex].students[studentIndex]
        let updated = StudentRecord(
            id: existing.id,
            name: existing.name,
            idCode: existing.idCode,
            attendance: .present,
            streak: existing.streak + 1
        )

        teacherCourses[courseIndex].students[studentIndex] = updated
        return updated
    }

    func approveJustification(_ justificationID: UUID) async throws {
        guard let index = teacherJustifications.firstIndex(where: { $0.id == justificationID }) else {
            throw BorealistaAPIError.invalidInput("No se encontro el justificante seleccionado.")
        }

        guard let excuseID = teacherJustifications[index].excuseID else {
            throw BorealistaAPIError.invalidInput("El justificante no tiene un identificador valido.")
        }

        try await api.approveJustification(excuseID: excuseID)
        teacherJustifications.remove(at: index)
    }

    func rejectJustification(_ justificationID: UUID) async throws {
        guard let index = teacherJustifications.firstIndex(where: { $0.id == justificationID }) else {
            throw BorealistaAPIError.invalidInput("No se encontro el justificante seleccionado.")
        }

        guard let excuseID = teacherJustifications[index].excuseID else {
            throw BorealistaAPIError.invalidInput("El justificante no tiene un identificador valido.")
        }

        try await api.rejectJustification(excuseID: excuseID)
        teacherJustifications.remove(at: index)
    }

    func updateTeacherPassword(current: String, new: String, confirmation: String) async throws {
        guard !current.trimmed.isEmpty, !new.trimmed.isEmpty, !confirmation.trimmed.isEmpty else {
            throw BorealistaAPIError.invalidInput("Completa los tres campos de contraseña para continuar.")
        }

        guard new.trimmed == confirmation.trimmed else {
            throw BorealistaAPIError.invalidInput("La nueva contraseña y su confirmacion no coinciden.")
        }

        guard new.trimmed.count >= 8 else {
            throw BorealistaAPIError.invalidInput("La nueva contraseña debe tener al menos 8 caracteres.")
        }

        _ = try validatedTeacherSession()
        _ = try await api.updateTeacherPassword(
            email: currentTeacherProfile.email,
            currentPassword: current.trimmed,
            newPassword: new.trimmed,
            confirmation: confirmation.trimmed
        )
    }

    func submitJustification(for record: AbsenceRecord, reason: String, notes: String) async throws -> AbsenceRecord {
        let normalizedReason = reason.trimmed
        let normalizedNotes = notes.trimmed
        let fullReason = normalizedNotes.isEmpty ? normalizedReason : "\(normalizedReason): \(normalizedNotes)"

        guard !fullReason.isEmpty else {
            throw BorealistaAPIError.invalidInput("Escribe el motivo del justificante antes de enviarlo.")
        }

        guard let attendanceID = record.attendanceID else {
            throw BorealistaAPIError.invalidInput("No se pudo identificar la falta para enviar el justificante.")
        }

        isSubmittingJustification = true
        defer { isSubmittingJustification = false }

        let message = try await api.submitExcuse(attendanceID: attendanceID, reason: fullReason)
        lastJustificationContext = JustificationSubmissionContext(message: message, isRemote: true)

        let updatedRecord = record.updating(status: .pending, reason: fullReason)
        replaceAbsence(record, with: updatedRecord)
        return updatedRecord
    }

    func signOut() {
        sessionStorage.clear()
        activeSession = nil
        sessionState = nil
        selectedRole = .student
        authMode = .signIn
        studentTab = .classes
        teacherTab = .classes
        isStudentDataLoaded = false
        isTeacherDataLoaded = false
        isLoadingStudentData = false
        isLoadingTeacherData = false
        studentCourses = []
        studentAbsences = []
        teacherCourses = []
        teacherJustifications = []
        teacherProfile = AppModel.placeholderTeacherProfile
        studentCoursesNotice = nil
        studentAbsencesNotice = nil
        lastJustificationContext = nil
        loginEmail = ""
        loginPassword = ""
    }

    func consumeStartupStudentRoute() -> StudentRoute? {
        defer { startupStudentRoute = nil }
        return startupStudentRoute
    }

    func consumeStartupTeacherRoute() -> TeacherRoute? {
        defer { startupTeacherRoute = nil }
        return startupTeacherRoute
    }

    private func restorePersistedSession() {
        guard let storedSession = sessionStorage.load() else {
            return
        }

        activeSession = storedSession
        loginEmail = storedSession.email

        switch storedSession.role {
        case .student:
            selectedRole = .student
            sessionState = .student
        case .teacher:
            selectedRole = .teacher
            sessionState = .teacher
            teacherProfile = .teacher(from: storedSession, detail: teacherDetailSummary)
        }
    }

    private func completeAuthentication(_ session: StudentSession, persist: Bool) {
        activeSession = session
        loginEmail = session.email
        selectedRole = session.role == .student ? .student : .teacher
        authMode = .signIn
        lastJustificationContext = nil

        switch session.role {
        case .student:
            sessionState = .student
            studentTab = .classes
            isStudentDataLoaded = false
            isTeacherDataLoaded = false
        case .teacher:
            sessionState = .teacher
            teacherTab = .classes
            isTeacherDataLoaded = false
            isStudentDataLoaded = false
            teacherProfile = .teacher(from: session, detail: teacherDetailSummary)
        }

        if persist {
            sessionStorage.save(session)
        } else {
            sessionStorage.clear()
        }
    }

    private func loadStudentExperience() async {
        guard let activeSession, activeSession.role == .student else {
            clearStudentData()
            return
        }

        isLoadingStudentData = true
        defer {
            isLoadingStudentData = false
            isStudentDataLoaded = true
        }

        do {
            async let remoteCourses = api.fetchCourses(studentCode: activeSession.code)
            async let remoteAttendances = api.fetchStudentAttendances(studentCode: activeSession.code)

            let (courses, attendances) = try await (remoteCourses, remoteAttendances)

            studentCourses = courses.enumerated().map { index, course in
                course.asDisplayCourse(accent: courseAccents[index % courseAccents.count])
            }

            studentAbsences = attendances.map { $0.asAbsenceRecord() }

            studentCoursesNotice = nil
            studentAbsencesNotice = nil
        } catch {
            clearStudentData()
            studentCoursesNotice = ScreenNotice(
                title: "No se pudieron cargar tus clases",
                message: error.localizedDescription,
                tone: .warning
            )
            studentAbsencesNotice = ScreenNotice(
                title: "No se pudo cargar tu asistencia",
                message: error.localizedDescription,
                tone: .warning
            )
        }
    }

    private func loadTeacherExperience() async {
        guard let activeSession, activeSession.role == .teacher else {
            clearTeacherData()
            return
        }

        isLoadingTeacherData = true
        defer {
            isLoadingTeacherData = false
            isTeacherDataLoaded = true
        }

        do {
            async let remoteCourses = api.fetchTeacherCourses(teacherID: activeSession.id)
            async let remoteJustifications = api.fetchPendingJustifications()

            let courses = try await remoteCourses
            let courseIDs = Set(courses.map(\.courseId))
            let allJustifications = try await remoteJustifications
            let justifications = allJustifications.filter { courseIDs.contains($0.courseID) }

            teacherCourses = courses.enumerated().map { index, course in
                course.asTeacherManagedCourse(accent: courseAccents[index % courseAccents.count])
            }
            teacherJustifications = justifications.map { $0.asJustificationRecord() }
            teacherProfile = .teacher(from: activeSession, detail: teacherDetailSummary)
        } catch {
            clearTeacherData()
            teacherProfile = .teacher(from: activeSession, detail: "Docente Borealista")
            throwAwayTeacherLoadError(error)
        }
    }

    private func throwAwayTeacherLoadError(_ error: Error) {
        alertContext = AlertContext(
            title: "No se pudo cargar el panel docente",
            message: error.localizedDescription
        )
    }

    private func clearStudentData() {
        studentCourses = []
        studentAbsences = []
    }

    private func clearTeacherData() {
        teacherCourses = []
        teacherJustifications = []
    }

    private func configureStudentDemoData() {
        studentCourses = screenshotStore.courses
        studentAbsences = screenshotStore.absences
        studentCoursesNotice = nil
        studentAbsencesNotice = nil
    }

    private func configureTeacherScreenshotData() {
        teacherCourses = screenshotStore.teacherCourses
        teacherJustifications = screenshotStore.justifications
        teacherProfile = screenshotStore.teacherProfile
        isTeacherDataLoaded = true
        isLoadingTeacherData = false
    }

    private func replaceAbsence(_ currentRecord: AbsenceRecord, with updatedRecord: AbsenceRecord) {
        guard let index = studentAbsences.firstIndex(of: currentRecord) else {
            studentAbsences.insert(updatedRecord, at: 0)
            return
        }

        studentAbsences[index] = updatedRecord
    }

    private func splitName(_ fullName: String) -> (firstName: String, lastName: String)? {
        let parts = fullName
            .split(separator: " ")
            .map(String.init)
            .map(\.trimmed)
            .filter { !$0.isEmpty }

        guard parts.count >= 2 else {
            return nil
        }

        return (parts.dropLast().joined(separator: " "), parts.last ?? "")
    }

    private func validatedTeacherSession() throws -> StudentSession {
        guard let activeSession, activeSession.role == .teacher else {
            throw BorealistaAPIError.invalidInput("Debes iniciar sesion como profesor para continuar.")
        }

        return activeSession
    }

    private func makeTeacherCourseRequest(
        from draft: TeacherCourseDraft,
        suggestedCourseCode: String,
        teacherID: Int
    ) throws -> TeacherCourseRequest {
        let normalizedName = draft.name.trimmed
        let normalizedClassroom = draft.classroom.trimmed
        let normalizedCareer = draft.career.trimmed
        let normalizedGroup = draft.groupName.trimmed
        let normalizedStart = draft.periodStart.trimmed
        let normalizedEnd = draft.periodEnd.trimmed

        guard !normalizedName.isEmpty,
              !normalizedClassroom.isEmpty,
              !normalizedCareer.isEmpty,
              !normalizedGroup.isEmpty,
              !normalizedStart.isEmpty,
              !normalizedEnd.isEmpty else {
            throw BorealistaAPIError.invalidInput("Completa todos los campos de la clase antes de guardarla.")
        }

        guard let absenceLimit = Int(draft.absenceLimit.trimmed), absenceLimit > 0 else {
            throw BorealistaAPIError.invalidInput("El numero de faltas debe ser un entero mayor a cero.")
        }

        guard !draft.scheduleBlocks.isEmpty else {
            throw BorealistaAPIError.invalidInput("Agrega por lo menos un bloque de horario para continuar.")
        }

        guard let startDate = Self.isoDate(from: normalizedStart, isEndDate: false),
              let endDate = Self.isoDate(from: normalizedEnd, isEndDate: true) else {
            throw BorealistaAPIError.invalidInput("Escribe fechas validas para el periodo. Puedes usar 2026-08-01 o 1 ago 2026.")
        }

        return TeacherCourseRequest(
            courseName: normalizedName,
            courseCode: suggestedCourseCode,
            teacherID: teacherID,
            classroom: normalizedClassroom,
            career: normalizedCareer,
            groupName: normalizedGroup,
            startDate: startDate,
            endDate: endDate,
            absenceLimit: absenceLimit,
            scheduleBlocks: draft.scheduleBlocks.map(\.asAPIBlock)
        )
    }

    private func generatedCourseCode(from name: String, classroom: String, groupName: String, seed: Int) -> String {
        let words = name
            .uppercased()
            .split(separator: " ")
            .filter { !$0.isEmpty }

        let prefix = words
            .prefix(3)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .padding(toLength: 3, withPad: "X", startingAt: 0)

        let roomDigits = classroom.filter(\.isNumber)
        let groupDigits = groupName.filter(\.isNumber)
        let numericSuffix = String((roomDigits + groupDigits).suffix(3))
        let fallbackSuffix = String(format: "%03d", seed % 1000)
        let suffix = numericSuffix.isEmpty ? fallbackSuffix : numericSuffix

        return "\(prefix)-\(suffix)"
    }

    private var teacherDetailSummary: String {
        teacherCourses.isEmpty ? "Panel docente Borealista" : "\(teacherCourses.count) clases activas"
    }

    private static func isoDate(from rawValue: String, isEndDate: Bool) -> String? {
        let normalized = rawValue.trimmed.lowercased()

        if normalized.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
            return normalized
        }

        let locale = Locale(identifier: "es_MX")
        let calendar = Calendar(identifier: .gregorian)

        for format in ["d MMM yyyy", "dd MMM yyyy", "d MMMM yyyy", "dd MMMM yyyy"] {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.dateFormat = format

            if let date = formatter.date(from: normalized) {
                let output = DateFormatter()
                output.locale = Locale(identifier: "en_US_POSIX")
                output.calendar = calendar
                output.dateFormat = "yyyy-MM-dd"
                return output.string(from: date)
            }
        }

        for format in ["MMM yyyy", "MMMM yyyy"] {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.dateFormat = format

            if let date = formatter.date(from: normalized) {
                let components = calendar.dateComponents([.year, .month], from: date)
                guard let year = components.year, let month = components.month else {
                    continue
                }

                let day: Int
                if isEndDate {
                    day = calendar.range(of: .day, in: .month, for: date)?.count ?? 28
                } else {
                    day = 1
                }

                var finalComponents = DateComponents()
                finalComponents.year = year
                finalComponents.month = month
                finalComponents.day = day

                guard let finalDate = calendar.date(from: finalComponents) else {
                    continue
                }

                let output = DateFormatter()
                output.locale = Locale(identifier: "en_US_POSIX")
                output.calendar = calendar
                output.dateFormat = "yyyy-MM-dd"
                return output.string(from: finalDate)
            }
        }

        return nil
    }

    private func applyScreenshotModeIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--screenshot"),
              arguments.indices.contains(flagIndex + 1),
              let mode = ScreenshotMode(rawValue: arguments[flagIndex + 1]) else {
            return
        }

        activeScreenshotMode = mode
        selectedRole = .student

        switch mode {
        case .login:
            authMode = .signIn
            sessionState = nil
        case .signUp:
            authMode = .signUp
            sessionState = nil
        case .classes:
            continueWithDemoSession()
            studentTab = .classes
        case .identifier:
            continueWithDemoSession()
            studentTab = .identifier
        case .absences:
            continueWithDemoSession()
            studentTab = .absences
        case .profile:
            continueWithDemoSession()
            studentTab = .profile
        case .classDetail:
            continueWithDemoSession()
            studentTab = .classes
            startupStudentRoute = .classDetail(studentCourses.first ?? screenshotStore.courses[0])
        case .justify:
            continueWithDemoSession()
            studentTab = .absences
            startupStudentRoute = .justifyAbsence(firstJustifiableRecord)
        case .confirmation:
            continueWithDemoSession()
            studentTab = .absences
            let record = firstJustifiableRecord.updating(
                status: .pending,
                reason: "Cita medica: comprobante capturado"
            )
            lastJustificationContext = nil
            startupStudentRoute = .confirmation(record)
        case .teacherClasses:
            continueWithTeacherScreenshotSession()
            teacherTab = .classes
        case .teacherJustifications:
            continueWithTeacherScreenshotSession()
            teacherTab = .justifications
        case .teacherProfile:
            continueWithTeacherScreenshotSession()
            teacherTab = .profile
        case .teacherClassDetail:
            continueWithTeacherScreenshotSession()
            teacherTab = .classes
            if let course = teacherCourses.first {
                startupTeacherRoute = .classDetail(course.id)
            }
        case .teacherRoster:
            continueWithTeacherScreenshotSession()
            teacherTab = .classes
            if let course = teacherCourses.first {
                startupTeacherRoute = .roster(course.id)
            }
        case .teacherAttendance:
            continueWithTeacherScreenshotSession()
            teacherTab = .classes
            if let course = teacherCourses.first {
                startupTeacherRoute = .attendanceScanner(course.id)
            }
        }
    }

    private var firstJustifiableRecord: AbsenceRecord {
        studentAbsences.first(where: { $0.status == .absent }) ?? screenshotStore.absences[0]
    }

    private static let placeholderStudentProfile = UserProfile(
        name: "Alumno Borealista",
        role: "Alumno",
        detail: "Tablero academico Borealista",
        email: "",
        id: "",
        initials: "AL"
    )

    private static let placeholderTeacherProfile = UserProfile(
        name: "Profesor Borealista",
        role: "Profesor",
        detail: "Panel docente Borealista",
        email: "",
        id: "",
        initials: "PR"
    )
}

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            switch appModel.sessionState {
            case .student:
                StudentShellView()
            case .teacher:
                TeacherShellView()
            case nil:
                AuthFlowView()
            }
        }
    }
}

enum BorealistaAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidInput(String)
    case httpStatus(code: Int, message: String)
    case decodingFailure

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "La URL base de Borealista no es valida."
        case .invalidResponse:
            "La respuesta del servidor no fue valida."
        case let .invalidInput(message):
            message
        case let .httpStatus(_, message):
            message
        case .decodingFailure:
            "La app no pudo interpretar la respuesta del servidor."
        }
    }
}

struct BorealistaAPI {
    private let baseURLString = (
        Bundle.main.object(forInfoDictionaryKey: "BOREALISTA_API_BASE_URL") as? String
    ) ?? "http://3.131.135.169:8080/BorealistaAPI/api"
    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func login(email: String, password: String, role: APIUserRole) async throws -> StudentSession {
        let request = try makeRequest(
            path: "/login",
            method: "POST",
            body: LoginRequest(email: email, password: password, role: role)
        )

        let response: APIDataEnvelope<StudentSession> = try await perform(request)

        guard let session = response.data else {
            throw BorealistaAPIError.decodingFailure
        }

        return session
    }

    func register(
        role: APIUserRole,
        studentCode: String?,
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async throws {
        let request = try makeRequest(
            path: "/register",
            method: "POST",
            body: RegisterRequest(
                role: role,
                studentCode: studentCode,
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
        )

        let _: APIMessageEnvelope = try await perform(request)
    }

    func fetchCourses(studentCode: String) async throws -> [APICourse] {
        let request = try makeRequest(
            path: "/courses",
            method: "GET",
            queryItems: [URLQueryItem(name: "student_code", value: studentCode)]
        )

        let response: APIDataEnvelope<[APICourse]> = try await perform(request)
        return response.data ?? []
    }

    func fetchStudentAttendances(studentCode: String) async throws -> [APIStudentAttendance] {
        let encodedCode = studentCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? studentCode
        let request = try makeRequest(
            path: "/students/\(encodedCode)/attendances",
            method: "GET"
        )

        let response: APIDataEnvelope<[APIStudentAttendance]> = try await perform(request)
        return response.data ?? []
    }

    func fetchTeacherCourses(teacherID: Int) async throws -> [APITeacherCourse] {
        let request = try makeRequest(
            path: "/teacher/courses",
            method: "GET",
            queryItems: [URLQueryItem(name: "teacher_id", value: String(teacherID))]
        )

        let response: APIDataEnvelope<[APITeacherCourse]> = try await perform(request)
        return response.data ?? []
    }

    func createTeacherCourse(_ requestBody: TeacherCourseRequest) async throws -> APITeacherCourse {
        let request = try makeRequest(
            path: "/courses",
            method: "POST",
            body: requestBody
        )

        let response: APIDataEnvelope<APITeacherCourse> = try await perform(request)
        guard let course = response.data else {
            throw BorealistaAPIError.decodingFailure
        }
        return course
    }

    func updateTeacherCourse(courseID: Int, request requestBody: TeacherCourseRequest) async throws -> APITeacherCourse {
        let request = try makeRequest(
            path: "/courses/\(courseID)",
            method: "PUT",
            body: requestBody
        )

        let response: APIDataEnvelope<APITeacherCourse> = try await perform(request)
        guard let course = response.data else {
            throw BorealistaAPIError.decodingFailure
        }
        return course
    }

    func deleteTeacherCourse(courseID: Int) async throws {
        let request = try makeRequest(
            path: "/courses/\(courseID)",
            method: "DELETE"
        )

        let _: APIMessageEnvelope = try await perform(request)
    }

    func addStudentToCourse(courseID: Int, studentCode: String) async throws -> APIStudent {
        let request = try makeRequest(
            path: "/courses/\(courseID)/students",
            method: "POST",
            body: CourseStudentRequest(studentCode: studentCode)
        )

        let response: APIDataEnvelope<APIStudent> = try await perform(request)
        guard let student = response.data else {
            throw BorealistaAPIError.decodingFailure
        }
        return student
    }

    func removeStudentFromCourse(courseID: Int, studentCode: String) async throws {
        let encodedCode = studentCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? studentCode
        let request = try makeRequest(
            path: "/courses/\(courseID)/students/\(encodedCode)",
            method: "DELETE"
        )

        let _: APIMessageEnvelope = try await perform(request)
    }

    func fetchPendingJustifications() async throws -> [APIExcuse] {
        let request = try makeRequest(
            path: "/justifications/pending",
            method: "GET"
        )

        let response: APIDataEnvelope<[APIExcuse]> = try await perform(request)
        return response.data ?? []
    }

    func approveJustification(excuseID: Int) async throws {
        let request = try makeRequest(
            path: "/justifications/\(excuseID)/approve",
            method: "POST"
        )

        let _: APIMessageEnvelope = try await perform(request)
    }

    func rejectJustification(excuseID: Int) async throws {
        let request = try makeRequest(
            path: "/justifications/\(excuseID)/reject",
            method: "POST"
        )

        let _: APIMessageEnvelope = try await perform(request)
    }

    func updateTeacherPassword(
        email: String,
        currentPassword: String,
        newPassword: String,
        confirmation: String
    ) async throws -> String {
        let request = try makeRequest(
            path: "/teacher/profile/password",
            method: "PATCH",
            body: TeacherPasswordRequest(
                email: email,
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmation: confirmation
            )
        )

        let response: APIMessageEnvelope = try await perform(request)
        return response.message ?? "Contraseña actualizada."
    }

    func startTeacherAttendanceSession(teacherID: Int, courseID: Int) async throws -> APITeacherAttendanceSession {
        let request = try makeRequest(
            path: "/teacher/attendance-sessions",
            method: "POST",
            body: TeacherAttendanceSessionRequest(teacherID: teacherID, courseID: courseID)
        )

        let response: APIDataEnvelope<APITeacherAttendanceSession> = try await perform(request)
        guard let session = response.data else {
            throw BorealistaAPIError.decodingFailure
        }
        return session
    }

    func scanTeacherAttendance(sessionID: Int, studentCode: String) async throws -> String {
        let request = try makeRequest(
            path: "/teacher/attendance-sessions/\(sessionID)/scan",
            method: "POST",
            body: CourseStudentRequest(studentCode: studentCode)
        )

        let response: APIMessageEnvelope = try await perform(request)
        return response.message ?? "Asistencia escaneada correctamente."
    }

    func submitExcuse(attendanceID: Int, reason: String) async throws -> String {
        let request = try makeRequest(
            path: "/excuses",
            method: "POST",
            body: ExcuseRequest(attendanceID: attendanceID, reason: reason)
        )

        let response: APIMessageEnvelope = try await perform(request)
        return response.message ?? "Justificante enviado."
    }

    func registerAttendance(studentCode: String, courseID: Int) async throws -> String {
        let request = try makeRequest(
            path: "/attendance",
            method: "POST",
            body: AttendanceRequest(studentCode: studentCode, courseID: courseID)
        )

        let response: APIMessageEnvelope = try await perform(request)
        return response.message ?? "Asistencia registrada."
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URLRequest {
        try baseRequest(path: path, method: method, queryItems: queryItems)
    }

    private func makeRequest<Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body? = nil
    ) throws -> URLRequest {
        var request = try baseRequest(path: path, method: method, queryItems: queryItems)

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func baseRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURLString + path) else {
            throw BorealistaAPIError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw BorealistaAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        return request
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BorealistaAPIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let envelope = try? decoder.decode(APIMessageEnvelope.self, from: data)
            let message = envelope?.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw BorealistaAPIError.httpStatus(code: httpResponse.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw BorealistaAPIError.decodingFailure
        }
    }
}

struct BorealistaSessionStorage {
    private let defaults = UserDefaults.standard
    private let sessionKey = "borealista.session"

    func save(_ session: StudentSession) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }

        defaults.set(data, forKey: sessionKey)
    }

    func load() -> StudentSession? {
        guard let data = defaults.data(forKey: sessionKey) else {
            return nil
        }

        return try? JSONDecoder().decode(StudentSession.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: sessionKey)
    }
}

struct TeacherCourseRequest: Encodable {
    let courseName: String
    let courseCode: String
    let teacherID: Int
    let classroom: String
    let career: String
    let groupName: String
    let startDate: String
    let endDate: String
    let absenceLimit: Int
    let scheduleBlocks: [APIScheduleBlock]

    enum CodingKeys: String, CodingKey {
        case courseName = "course_name"
        case courseCode = "course_code"
        case teacherID = "teacher_id"
        case classroom
        case career
        case groupName = "group_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case absenceLimit = "absence_limit"
        case scheduleBlocks = "schedule_blocks"
    }
}

struct CourseStudentRequest: Encodable {
    let studentCode: String

    enum CodingKeys: String, CodingKey {
        case studentCode = "student_code"
    }
}

struct TeacherPasswordRequest: Encodable {
    let email: String
    let currentPassword: String
    let newPassword: String
    let confirmation: String

    enum CodingKeys: String, CodingKey {
        case email
        case currentPassword = "current_password"
        case newPassword = "new_password"
        case confirmation
    }
}

struct TeacherAttendanceSessionRequest: Encodable {
    let teacherID: Int
    let courseID: Int

    enum CodingKeys: String, CodingKey {
        case teacherID = "teacher_id"
        case courseID = "course_id"
    }
}
