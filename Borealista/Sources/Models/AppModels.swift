import Foundation
import SwiftUI

enum AttendanceState: String, Hashable {
    case present = "Presente"
    case late = "Retardo"
    case absent = "Falta"
    case pending = "En revision"
    case justified = "Justificada"
    case unmarked = "Sin registro"

    var tint: Color {
        switch self {
        case .present:
            BorealistaPalette.forest
        case .late:
            BorealistaPalette.gold
        case .absent:
            BorealistaPalette.ember
        case .pending:
            BorealistaPalette.cedar
        case .justified:
            BorealistaPalette.forest
        case .unmarked:
            BorealistaPalette.stone
        }
    }
}

enum DataOrigin: String, Hashable {
    case remote
    case mock
}

enum NoticeTone: Hashable {
    case info
    case success
    case warning

    var icon: String {
        switch self {
        case .info:
            "info.circle.fill"
        case .success:
            "checkmark.seal.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info:
            BorealistaPalette.cedar
        case .success:
            BorealistaPalette.forest
        case .warning:
            BorealistaPalette.gold
        }
    }
}

struct ScreenNotice: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let tone: NoticeTone
}

struct AlertContext: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let message: String
}

struct JustificationSubmissionContext: Hashable {
    let message: String
    let isRemote: Bool
}

struct UserProfile: Hashable {
    let name: String
    let role: String
    let detail: String
    let email: String
    let id: String
    let initials: String
}

struct Course: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subject: String
    let instructor: String
    let schedule: String
    let room: String
    let code: String
    let term: String
    let studentsCount: Int
    let team: String
    let summary: String
    let accent: String
    var source: DataOrigin = .mock
}

struct AbsenceRecord: Identifiable, Hashable {
    let id = UUID()
    let courseTitle: String
    let date: String
    let time: String
    let reason: String
    let status: AttendanceState
    var attendanceID: Int? = nil
    var source: DataOrigin = .mock
}

struct StudentRecord: Identifiable, Hashable {
    let id: UUID
    let name: String
    let idCode: String
    let attendance: AttendanceState
    let streak: Int

    init(id: UUID = UUID(), name: String, idCode: String, attendance: AttendanceState, streak: Int) {
        self.id = id
        self.name = name
        self.idCode = idCode
        self.attendance = attendance
        self.streak = streak
    }
}

struct JustificationRecord: Identifiable, Hashable {
    let id: UUID
    let excuseID: Int?
    let studentName: String
    let studentCode: String
    let courseTitle: String
    let date: String
    let summary: String
    let status: AttendanceState

    init(
        id: UUID = UUID(),
        excuseID: Int? = nil,
        studentName: String,
        studentCode: String,
        courseTitle: String,
        date: String,
        summary: String,
        status: AttendanceState
    ) {
        self.id = id
        self.excuseID = excuseID
        self.studentName = studentName
        self.studentCode = studentCode
        self.courseTitle = courseTitle
        self.date = date
        self.summary = summary
        self.status = status
    }
}

struct InsightMetric: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
}

enum TeacherWeekday: String, CaseIterable, Hashable, Identifiable {
    case monday = "L"
    case tuesday = "M"
    case wednesday = "X"
    case thursday = "J"
    case friday = "V"

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .monday:
            "Lunes"
        case .tuesday:
            "Martes"
        case .wednesday:
            "Miercoles"
        case .thursday:
            "Jueves"
        case .friday:
            "Viernes"
        }
    }
}

struct ScheduleBlock: Identifiable, Hashable {
    let id: UUID
    var days: [TeacherWeekday]
    var startTime: String
    var endTime: String

    init(id: UUID = UUID(), days: [TeacherWeekday], startTime: String, endTime: String) {
        self.id = id
        self.days = days
        self.startTime = startTime
        self.endTime = endTime
    }

    var daysLabel: String {
        let ordered = TeacherWeekday.allCases.filter(days.contains)

        switch ordered {
        case [.monday, .wednesday]:
            return "Lunes y miercoles"
        case [.tuesday, .thursday, .friday]:
            return "Martes, jueves y viernes"
        default:
            return ordered.map { $0.fullName.lowercased() }.joined(separator: ", ")
                .capitalized
        }
    }

    var compactDays: String {
        TeacherWeekday.allCases
            .filter(days.contains)
            .map(\.rawValue)
            .joined(separator: " · ")
    }

    var timeLabel: String {
        "\(startTime) - \(endTime)"
    }
}

struct TeacherManagedCourse: Identifiable, Hashable {
    let id: UUID
    var courseID: Int
    var name: String
    var classroom: String
    var career: String
    var groupName: String
    var periodStart: String
    var periodEnd: String
    var absenceLimit: Int
    var scheduleBlocks: [ScheduleBlock]
    var students: [StudentRecord]
    var accent: String

    init(
        id: UUID = UUID(),
        courseID: Int,
        name: String,
        classroom: String,
        career: String,
        groupName: String,
        periodStart: String,
        periodEnd: String,
        absenceLimit: Int,
        scheduleBlocks: [ScheduleBlock],
        students: [StudentRecord],
        accent: String
    ) {
        self.id = id
        self.courseID = courseID
        self.name = name
        self.classroom = classroom
        self.career = career
        self.groupName = groupName
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.absenceLimit = absenceLimit
        self.scheduleBlocks = scheduleBlocks
        self.students = students
        self.accent = accent
    }

    var initials: String {
        let letters = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let value = String(letters).uppercased()
        return value.isEmpty ? "CL" : value
    }

    var scheduleSummary: String {
        guard let firstBlock = scheduleBlocks.first else {
            return "Sin horario"
        }

        return "\(firstBlock.daysLabel) · \(firstBlock.timeLabel)"
    }

    var locationSummary: String {
        "\(classroom) · \(groupName)"
    }

    var periodSummary: String {
        "\(periodStart) - \(periodEnd)"
    }
}

struct TeacherCourseDraft: Hashable {
    var name = ""
    var classroom = ""
    var career = ""
    var groupName = ""
    var periodStart = ""
    var periodEnd = ""
    var absenceLimit = "3"
    var scheduleBlocks: [ScheduleBlock] = []
    var accent = "sunrise"

    static let empty = TeacherCourseDraft(
        name: "",
        classroom: "",
        career: "",
        groupName: "",
        periodStart: "Ago 2026",
        periodEnd: "Dic 2026",
        absenceLimit: "3",
        scheduleBlocks: [
            ScheduleBlock(days: [.monday, .wednesday], startTime: "9:00", endTime: "11:00")
        ],
        accent: "sunrise"
    )

    init(
        name: String = "",
        classroom: String = "",
        career: String = "",
        groupName: String = "",
        periodStart: String = "",
        periodEnd: String = "",
        absenceLimit: String = "3",
        scheduleBlocks: [ScheduleBlock] = [],
        accent: String = "sunrise"
    ) {
        self.name = name
        self.classroom = classroom
        self.career = career
        self.groupName = groupName
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.absenceLimit = absenceLimit
        self.scheduleBlocks = scheduleBlocks
        self.accent = accent
    }

    init(course: TeacherManagedCourse) {
        name = course.name
        classroom = course.classroom
        career = course.career
        groupName = course.groupName
        periodStart = course.periodStart
        periodEnd = course.periodEnd
        absenceLimit = String(course.absenceLimit)
        scheduleBlocks = course.scheduleBlocks
        accent = course.accent
    }
}

enum APIUserRole: String, Codable {
    case student = "STUDENT"
    case teacher = "TEACHER"
}

struct StudentSession: Codable, Hashable {
    let id: Int
    let code: String
    let firstName: String
    let lastName: String
    let email: String
    let role: APIUserRole

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case role
    }

    var fullName: String {
        [firstName, lastName]
            .map(\.trimmed)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var initials: String {
        let letters = fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let value = String(letters).uppercased()
        return value.isEmpty ? "AL" : value
    }
}

struct APIDataEnvelope<T: Decodable>: Decodable {
    let status: String
    let data: T?
    let message: String?
}

struct APIMessageEnvelope: Decodable {
    let status: String
    let message: String?
}

struct APICourse: Decodable, Hashable {
    let courseId: Int
    let courseName: String
    let courseCode: String
    let startDate: String
    let endDate: String
    let teacherName: String

    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case courseName = "course_name"
        case courseCode = "course_code"
        case startDate = "start_date"
        case endDate = "end_date"
        case teacherName = "teacher_name"
    }
}

struct APIStudentAttendance: Decodable, Hashable {
    let attendanceID: Int
    let courseID: Int
    let courseName: String
    let date: String
    let time: String
    let status: String
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case attendanceID = "attendance_id"
        case courseID = "course_id"
        case courseName = "course_name"
        case date
        case time
        case status
        case reason
    }
}

struct APIScheduleBlock: Codable, Hashable {
    let id: String?
    let days: [String]
    let startTime: String
    let endTime: String

    enum CodingKeys: String, CodingKey {
        case id
        case days
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct APIStudent: Decodable, Hashable {
    let id: Int
    let code: String
    let firstName: String
    let lastName: String
    let email: String
    let role: APIUserRole
    let attendanceStatus: String?
    let streak: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case role
        case attendanceStatus = "attendance_status"
        case streak
    }
}

struct APITeacherCourse: Decodable, Hashable {
    let courseId: Int
    let courseName: String
    let courseCode: String
    let teacherID: Int
    let teacherName: String
    let classroom: String
    let career: String
    let groupName: String
    let startDate: String
    let endDate: String
    let absenceLimit: Int
    let scheduleBlocks: [APIScheduleBlock]
    let students: [APIStudent]

    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case courseName = "course_name"
        case courseCode = "course_code"
        case teacherID = "teacher_id"
        case teacherName = "teacher_name"
        case classroom
        case career
        case groupName = "group_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case absenceLimit = "absence_limit"
        case scheduleBlocks = "schedule_blocks"
        case students
    }
}

struct APIExcuse: Decodable, Hashable {
    let excuseID: Int
    let attendanceID: Int
    let courseID: Int
    let studentName: String
    let studentCode: String
    let courseTitle: String
    let date: String
    let summary: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case excuseID = "excuse_id"
        case attendanceID = "attendance_id"
        case courseID = "course_id"
        case studentName = "student_name"
        case studentCode = "student_code"
        case courseTitle = "course_title"
        case date
        case summary
        case status
    }
}

struct APITeacherAttendanceSession: Decodable, Hashable {
    let sessionID: Int
    let courseID: Int
    let courseName: String
    let startedAt: String
    let expiresAt: String
    let remainingSeconds: Int
    let scannedCodes: [String]

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case courseID = "course_id"
        case courseName = "course_name"
        case startedAt = "started_at"
        case expiresAt = "expires_at"
        case remainingSeconds = "remaining_seconds"
        case scannedCodes = "scanned_codes"
    }
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let role: APIUserRole
}

struct RegisterRequest: Encodable {
    let role: APIUserRole
    let studentCode: String?
    let firstName: String
    let lastName: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case role
        case studentCode = "student_code"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case password
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        if let studentCode {
            try container.encode(studentCode, forKey: .studentCode)
        }
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
    }
}

struct ExcuseRequest: Encodable {
    let attendanceID: Int
    let reason: String

    enum CodingKeys: String, CodingKey {
        case attendanceID = "attendance_id"
        case reason
    }
}

struct AttendanceRequest: Encodable {
    let studentCode: String
    let courseID: Int

    enum CodingKeys: String, CodingKey {
        case studentCode = "student_code"
        case courseID = "course_id"
    }
}

enum BorealistaDateFormatter {
    private static let parser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    static func format(_ isoDate: String) -> String {
        guard let date = parser.date(from: isoDate) else {
            return isoDate
        }

        return display.string(from: date)
    }

    static func range(start: String, end: String) -> String {
        "\(format(start)) - \(format(end))"
    }
}

extension APICourse {
    func asDisplayCourse(accent: String) -> Course {
        Course(
            title: courseName,
            subject: "Materia inscrita",
            instructor: teacherName,
            schedule: BorealistaDateFormatter.range(start: startDate, end: endDate),
            room: "Campus Borealista",
            code: courseCode,
            term: BorealistaDateFormatter.range(start: startDate, end: endDate),
            studentsCount: 0,
            team: "Grupo activo",
            summary: "Clase activa del periodo actual.",
            accent: accent,
            source: .remote
        )
    }
}

extension APIStudentAttendance {
    func asAbsenceRecord() -> AbsenceRecord {
        AbsenceRecord(
            courseTitle: courseName,
            date: BorealistaDateFormatter.format(date),
            time: time,
            reason: reason ?? fallbackReason(for: status),
            status: AttendanceState(apiStatus: status),
            attendanceID: attendanceID,
            source: .remote
        )
    }

    private func fallbackReason(for status: String) -> String {
        switch AttendanceState(apiStatus: status) {
        case .present:
            return "Asistencia registrada"
        case .late:
            return "Retardo registrado"
        case .absent:
            return "Falta sin justificar"
        case .pending:
            return "Justificante en revision"
        case .justified:
            return "Justificante aprobado"
        case .unmarked:
            return "Sin registro de asistencia"
        }
    }
}

extension APIStudent {
    func asStudentRecord() -> StudentRecord {
        StudentRecord(
            name: "\(firstName) \(lastName)".trimmed,
            idCode: code,
            attendance: AttendanceState(apiStatus: attendanceStatus),
            streak: streak ?? 0
        )
    }
}

extension APITeacherCourse {
    func asTeacherManagedCourse(accent: String) -> TeacherManagedCourse {
        TeacherManagedCourse(
            courseID: courseId,
            name: courseName,
            classroom: classroom,
            career: career,
            groupName: groupName,
            periodStart: BorealistaDateFormatter.format(startDate),
            periodEnd: BorealistaDateFormatter.format(endDate),
            absenceLimit: absenceLimit,
            scheduleBlocks: scheduleBlocks.map(\.asScheduleBlock),
            students: students.map { $0.asStudentRecord() },
            accent: accent
        )
    }
}

extension APIExcuse {
    func asJustificationRecord() -> JustificationRecord {
        JustificationRecord(
            excuseID: excuseID,
            studentName: studentName,
            studentCode: studentCode,
            courseTitle: courseTitle,
            date: date,
            summary: summary,
            status: AttendanceState(apiStatus: status)
        )
    }
}

extension UserProfile {
    static func student(from session: StudentSession) -> UserProfile {
        UserProfile(
            name: session.fullName,
            role: "Alumno",
            detail: "Tablero academico Borealista",
            email: session.email,
            id: session.code,
            initials: session.initials
        )
    }

    static func teacher(from session: StudentSession, detail: String) -> UserProfile {
        UserProfile(
            name: session.fullName,
            role: "Profesor",
            detail: detail,
            email: session.email,
            id: session.code,
            initials: session.initials
        )
    }
}

extension AbsenceRecord {
    func updating(status: AttendanceState, reason: String) -> AbsenceRecord {
        AbsenceRecord(
            courseTitle: courseTitle,
            date: date,
            time: time,
            reason: reason,
            status: status,
            attendanceID: attendanceID,
            source: source
        )
    }
}

extension AttendanceState {
    init(apiStatus: String?) {
        switch String(apiStatus ?? "").trimmed.uppercased() {
        case "PRESENTE":
            self = .present
        case "RETARDO":
            self = .late
        case "AUSENTE", "REJECTED":
            self = .absent
        case "PENDING":
            self = .pending
        case "JUSTIFICADA", "APPROVED":
            self = .justified
        default:
            self = .unmarked
        }
    }
}

extension APIScheduleBlock {
    var asScheduleBlock: ScheduleBlock {
        ScheduleBlock(
            days: days.compactMap(TeacherWeekday.init(rawValue:)),
            startTime: startTime,
            endTime: endTime
        )
    }
}

extension ScheduleBlock {
    var asAPIBlock: APIScheduleBlock {
        APIScheduleBlock(
            id: id.uuidString,
            days: days.map(\.rawValue),
            startTime: startTime,
            endTime: endTime
        )
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct MockDataStore {
    let studentProfile = UserProfile(
        name: "Julio Cesar Romero Tavares",
        role: "Alumno",
        detail: "Ingenieria en Sistemas",
        email: "julio.romero0079866@borealista.edu",
        id: "0079866",
        initials: "JC"
    )

    let teacherProfile = UserProfile(
        name: "Ana Maria Torres",
        role: "Profesor",
        detail: "Coordinacion academica",
        email: "ana.torres@borealista.edu",
        id: "FAC-204",
        initials: "AT"
    )

    let teacherCourses: [TeacherManagedCourse] = [
        TeacherManagedCourse(
            courseID: 1,
            name: "Matematicas avanzadas",
            classroom: "Salon 302",
            career: "Ingenieria en software",
            groupName: "Grupo 3A",
            periodStart: "Ago 2025",
            periodEnd: "Dic 2025",
            absenceLimit: 3,
            scheduleBlocks: [
                ScheduleBlock(days: [.monday, .wednesday], startTime: "9:00", endTime: "11:00"),
                ScheduleBlock(days: [.tuesday, .thursday, .friday], startTime: "11:00", endTime: "13:00")
            ],
            students: [
                StudentRecord(name: "Julio Cesar Romero Tavares", idCode: "0079866", attendance: .present, streak: 18),
                StudentRecord(name: "Andrea Flores", idCode: "0079891", attendance: .present, streak: 11),
                StudentRecord(name: "Marco Benitez", idCode: "0079812", attendance: .late, streak: 6)
            ],
            accent: "sunrise"
        ),
        TeacherManagedCourse(
            courseID: 2,
            name: "Fisica aplicada",
            classroom: "Salon 204",
            career: "Ingenieria mecatronica",
            groupName: "Grupo 2B",
            periodStart: "Ago 2025",
            periodEnd: "Dic 2025",
            absenceLimit: 4,
            scheduleBlocks: [
                ScheduleBlock(days: [.tuesday, .thursday], startTime: "8:00", endTime: "10:00")
            ],
            students: [
                StudentRecord(name: "Camila Nunez", idCode: "0079762", attendance: .present, streak: 9),
                StudentRecord(name: "Sofia Herrera", idCode: "0079788", attendance: .absent, streak: 1)
            ],
            accent: "forest"
        )
    ]

    let courses: [Course] = [
        Course(
            title: "Matematicas avanzadas",
            subject: "Calculo y modelado",
            instructor: "Ana Maria Torres",
            schedule: "Lun/Mie/Vie · 8:00 - 10:00",
            room: "Aula 204",
            code: "MAT-402",
            term: "Ago 2026 - Dic 2026",
            studentsCount: 32,
            team: "Grupo 02",
            summary: "Analisis vectorial, sistemas diferenciales y resolucion de problemas aplicados.",
            accent: "sunrise"
        ),
        Course(
            title: "Fisica experimental",
            subject: "Laboratorio y mecanica",
            instructor: "Ana Maria Torres",
            schedule: "Mar/Jue · 11:00 - 12:30",
            room: "Laboratorio 5",
            code: "PHY-210",
            term: "Ago 2026 - Dic 2026",
            studentsCount: 24,
            team: "Grupo 01",
            summary: "Practicas semanales, reportes y fundamentos de mecanica para ingenieria.",
            accent: "forest"
        ),
        Course(
            title: "Diseno de sistemas",
            subject: "Arquitectura de producto",
            instructor: "Mauricio Cardenas",
            schedule: "Vie · 15:00 - 18:00",
            room: "Studio 3",
            code: "SYS-301",
            term: "Ago 2026 - Dic 2026",
            studentsCount: 18,
            team: "Grupo 04",
            summary: "Mapeo de sistemas, arquitectura y revision colaborativa de soluciones.",
            accent: "cedar"
        )
    ]

    let absences: [AbsenceRecord] = [
        AbsenceRecord(
            courseTitle: "Matematicas avanzadas",
            date: "10 nov 2026",
            time: "8:00 - 10:00",
            reason: "Justificante medico aprobado",
            status: .justified
        ),
        AbsenceRecord(
            courseTitle: "Fisica experimental",
            date: "3 nov 2026",
            time: "11:00 - 12:30",
            reason: "Pendiente de justificar",
            status: .absent
        ),
        AbsenceRecord(
            courseTitle: "Diseno de sistemas",
            date: "28 oct 2026",
            time: "15:00 - 18:00",
            reason: "Llegada tarde por trafico",
            status: .late
        )
    ]

    let roster: [StudentRecord] = [
        StudentRecord(name: "Julio Cesar Romero Tavares", idCode: "0079866", attendance: .present, streak: 12),
        StudentRecord(name: "Andrea Flores", idCode: "A01752100", attendance: .present, streak: 17),
        StudentRecord(name: "Sofia Herrera", idCode: "A01753299", attendance: .late, streak: 4),
        StudentRecord(name: "Marco Benitez", idCode: "A01759901", attendance: .absent, streak: 2),
        StudentRecord(name: "Camila Nunez", idCode: "A01750011", attendance: .present, streak: 20)
    ]

    let justifications: [JustificationRecord] = [
        JustificationRecord(
            studentName: "Julio Cesar Romero Tavares",
            studentCode: "0079866",
            courseTitle: "Matematicas avanzadas",
            date: "3 jun 2026 · Horario: 19:00 - 20:00",
            summary: "Otro. Se me poncho la llanta del carro y no pude llegar a tiempo.",
            status: .pending
        ),
        JustificationRecord(
            studentName: "Marco Benitez",
            studentCode: "0079812",
            courseTitle: "Fisica experimental",
            date: "3 nov 2026",
            summary: "Pendiente de revision por transporte.",
            status: .pending
        )
    ]

    let studentMetrics: [InsightMetric] = [
        InsightMetric(title: "Asistencia", value: "94%", icon: "checkmark.seal.fill"),
        InsightMetric(title: "Clases activas", value: "3", icon: "books.vertical.fill"),
        InsightMetric(title: "Pendientes", value: "1", icon: "clock.fill")
    ]

    let teacherMetrics: [InsightMetric] = [
        InsightMetric(title: "Clases activas", value: "6", icon: "rectangle.stack.fill"),
        InsightMetric(title: "Estudiantes", value: "128", icon: "person.3.fill"),
        InsightMetric(title: "Por revisar", value: "4", icon: "doc.text.fill")
    ]
}
