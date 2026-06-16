import { createServer } from "node:http";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DATA_PATH = path.join(__dirname, "..", "data", "db.json");
const PORT = Number(process.env.PORT || 8080);
const API_PREFIX = "/BorealistaAPI/api";

ensureDataFile();

const server = createServer(async (req, res) => {
  const baseURL = `http://${req.headers.host || "localhost"}`;
  const url = new URL(req.url || "/", baseURL);

  if (req.method === "OPTIONS") {
    return sendJson(res, 204, null);
  }

  if (url.pathname === "/health") {
    return sendJson(res, 200, {
      status: "success",
      message: "Borealista backend activo"
    });
  }

  if (!url.pathname.startsWith(API_PREFIX)) {
    return sendJson(res, 404, {
      status: "error",
      message: "Ruta no encontrada"
    });
  }

  const routePath = url.pathname.slice(API_PREFIX.length) || "/";

  try {
    if (req.method === "GET" && routePath === "/") {
      return sendJson(res, 200, {
        status: "success",
        message: "Borealista API activa",
        environment: "aws",
        base_path: API_PREFIX,
        health: "/health",
        endpoints: {
          auth: [
            "POST /login",
            "POST /register"
          ],
          student: [
            "GET /courses?student_code={matricula}",
            "POST /attendance",
            "POST /excuses",
            "GET /students/:studentCode/attendances",
            "GET /students/:studentCode/digital-id"
          ],
          teacher: [
            "GET /teacher/courses?teacher_id={teacherId}",
            "POST /courses",
            "PUT /courses/:courseId",
            "DELETE /courses/:courseId",
            "GET /courses/:courseId/students",
            "POST /courses/:courseId/students",
            "DELETE /courses/:courseId/students/:studentCode",
            "GET /justifications/pending",
            "POST /justifications/:justificationId/approve",
            "POST /justifications/:justificationId/reject",
            "PATCH /teacher/profile/password",
            "POST /teacher/attendance-sessions",
            "GET /teacher/attendance-sessions/:sessionId",
            "POST /teacher/attendance-sessions/:sessionId/scan"
          ]
        }
      });
    }

    if (req.method === "POST" && routePath === "/login") {
      const body = await parseBody(req);
      const db = readDB();
      return handleLogin(res, db, body);
    }

    if (req.method === "POST" && routePath === "/register") {
      const body = await parseBody(req);
      const db = readDB();
      return handleRegister(res, db, body);
    }

    if (req.method === "GET" && routePath === "/courses") {
      const studentCode = url.searchParams.get("student_code");
      const db = readDB();
      return handleStudentCourses(res, db, studentCode);
    }

    if (req.method === "POST" && routePath === "/courses") {
      const body = await parseBody(req);
      const db = readDB();
      return handleCreateCourse(res, db, body);
    }

    const courseStudentsDeleteMatch = routePath.match(/^\/courses\/(\d+)\/students\/([^/]+)$/);
    if (req.method === "DELETE" && courseStudentsDeleteMatch) {
      const [, courseIdRaw, studentCodeRaw] = courseStudentsDeleteMatch;
      const db = readDB();
      return handleRemoveStudentFromCourse(
        res,
        db,
        Number(courseIdRaw),
        decodeURIComponent(studentCodeRaw)
      );
    }

    const courseStudentsMatch = routePath.match(/^\/courses\/(\d+)\/students$/);
    if (courseStudentsMatch) {
      const courseId = Number(courseStudentsMatch[1]);
      const db = readDB();

      if (req.method === "GET") {
        return handleCourseStudents(res, db, courseId);
      }

      if (req.method === "POST") {
        const body = await parseBody(req);
        return handleAddStudentToCourse(res, db, courseId, body);
      }
    }

    const courseMatch = routePath.match(/^\/courses\/(\d+)$/);
    if (courseMatch) {
      const courseId = Number(courseMatch[1]);
      const db = readDB();

      if (req.method === "PUT") {
        const body = await parseBody(req);
        return handleUpdateCourse(res, db, courseId, body);
      }

      if (req.method === "DELETE") {
        return handleDeleteCourse(res, db, courseId);
      }
    }

    if (req.method === "POST" && routePath === "/attendance") {
      const body = await parseBody(req);
      const db = readDB();
      return handleAttendance(res, db, body);
    }

    if (req.method === "POST" && routePath === "/excuses") {
      const body = await parseBody(req);
      const db = readDB();
      return handleExcuse(res, db, body);
    }

    const studentAttendanceMatch = routePath.match(/^\/students\/([^/]+)\/attendances$/);
    if (req.method === "GET" && studentAttendanceMatch) {
      const db = readDB();
      return handleStudentAttendances(
        res,
        db,
        decodeURIComponent(studentAttendanceMatch[1])
      );
    }

    const studentDigitalIdMatch = routePath.match(/^\/students\/([^/]+)\/digital-id$/);
    if (req.method === "GET" && studentDigitalIdMatch) {
      const db = readDB();
      return handleStudentDigitalID(
        res,
        db,
        decodeURIComponent(studentDigitalIdMatch[1])
      );
    }

    if (req.method === "GET" && routePath === "/teacher/courses") {
      const db = readDB();
      const teacherId = url.searchParams.get("teacher_id");
      return handleTeacherCourses(res, db, teacherId ? Number(teacherId) : undefined);
    }

    if (req.method === "POST" && routePath === "/teacher/attendance-sessions") {
      const body = await parseBody(req);
      const db = readDB();
      return handleCreateAttendanceSession(res, db, body);
    }

    const attendanceSessionMatch = routePath.match(/^\/teacher\/attendance-sessions\/(\d+)$/);
    if (req.method === "GET" && attendanceSessionMatch) {
      const db = readDB();
      return handleAttendanceSessionStatus(res, db, Number(attendanceSessionMatch[1]));
    }

    const attendanceSessionScanMatch = routePath.match(/^\/teacher\/attendance-sessions\/(\d+)\/scan$/);
    if (req.method === "POST" && attendanceSessionScanMatch) {
      const body = await parseBody(req);
      const db = readDB();
      return handleAttendanceSessionScan(
        res,
        db,
        Number(attendanceSessionScanMatch[1]),
        body
      );
    }

    if (req.method === "GET" && routePath === "/justifications/pending") {
      const db = readDB();
      return handlePendingJustifications(res, db);
    }

    const justificationApproveMatch = routePath.match(/^\/justifications\/(\d+)\/approve$/);
    if (req.method === "POST" && justificationApproveMatch) {
      const db = readDB();
      return handleJustificationDecision(
        res,
        db,
        Number(justificationApproveMatch[1]),
        "APPROVED"
      );
    }

    const justificationRejectMatch = routePath.match(/^\/justifications\/(\d+)\/reject$/);
    if (req.method === "POST" && justificationRejectMatch) {
      const db = readDB();
      return handleJustificationDecision(
        res,
        db,
        Number(justificationRejectMatch[1]),
        "REJECTED"
      );
    }

    if (req.method === "PATCH" && routePath === "/teacher/profile/password") {
      const body = await parseBody(req);
      const db = readDB();
      return handleTeacherPasswordUpdate(res, db, body);
    }

    return sendJson(res, 404, {
      status: "error",
      message: "Ruta no encontrada"
    });
  } catch (error) {
    return sendJson(res, 500, {
      status: "error",
      message: error instanceof Error ? error.message : "Error interno del servidor"
    });
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Borealista backend escuchando en http://0.0.0.0:${PORT}${API_PREFIX}`);
});

function ensureDataFile() {
  const directory = path.dirname(DATA_PATH);
  if (!existsSync(directory)) {
    mkdirSync(directory, { recursive: true });
  }
}

function readDB() {
  return JSON.parse(readFileSync(DATA_PATH, "utf8"));
}

function writeDB(db) {
  writeFileSync(DATA_PATH, JSON.stringify(db, null, 2));
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,POST,PUT,PATCH,DELETE,OPTIONS"
  });

  if (payload === null) {
    res.end();
    return;
  }

  res.end(JSON.stringify(payload));
}

async function parseBody(req) {
  const chunks = [];

  for await (const chunk of req) {
    chunks.push(chunk);
  }

  if (chunks.length === 0) {
    return {};
  }

  const rawBody = Buffer.concat(chunks).toString("utf8");
  return rawBody.trim() ? JSON.parse(rawBody) : {};
}

function handleLogin(res, db, body) {
  const email = String(body.email || "").trim().toLowerCase();
  const password = String(body.password || "").trim();
  const role = String(body.role || "").trim().toUpperCase();

  const user = db.users.find(
    (candidate) =>
      candidate.email.toLowerCase() === email &&
      candidate.password === password &&
      candidate.role === role
  );

  if (!user) {
    return sendJson(res, 401, {
      status: "error",
      message: "Credenciales invalidas"
    });
  }

  return sendJson(res, 200, {
    status: "success",
    data: serializeSessionUser(user)
  });
}

function handleRegister(res, db, body) {
  const role = String(body.role || "").trim().toUpperCase();
  const studentCode = String(body.student_code || "").trim();
  const firstName = String(body.first_name || "").trim();
  const lastName = String(body.last_name || "").trim();
  const email = String(body.email || "").trim().toLowerCase();
  const password = String(body.password || "").trim();

  if (!["STUDENT", "TEACHER"].includes(role)) {
    return sendJson(res, 400, {
      status: "error",
      message: "El rol debe ser STUDENT o TEACHER"
    });
  }

  if (!firstName || !lastName || !email || !password) {
    return sendJson(res, 400, {
      status: "error",
      message: "Completa nombre, apellido, correo y contrasena"
    });
  }

  if (role === "STUDENT" && !studentCode) {
    return sendJson(res, 400, {
      status: "error",
      message: "La matricula es obligatoria para registrar un alumno"
    });
  }

  if (db.users.some((user) => user.email.toLowerCase() === email)) {
    return sendJson(res, 409, {
      status: "error",
      message: "Ya existe un usuario con ese correo"
    });
  }

  if (studentCode && db.users.some((user) => user.code === studentCode)) {
    return sendJson(res, 409, {
      status: "error",
      message: "Ya existe un usuario con esa matricula"
    });
  }

  const user = {
    id: nextId(db.users, "id"),
    code: role === "STUDENT" ? studentCode : `FAC-${String(nextId(db.users, "id")).padStart(3, "0")}`,
    first_name: firstName,
    last_name: lastName,
    email,
    password,
    role
  };

  db.users.push(user);
  writeDB(db);

  return sendJson(res, 201, {
    status: "success",
    message: "Usuario registrado exitosamente"
  });
}

function handleStudentCourses(res, db, studentCode) {
  const normalizedCode = String(studentCode || "").trim();

  if (!normalizedCode) {
    return sendJson(res, 400, {
      status: "error",
      message: "Debes enviar el query param student_code"
    });
  }

  const courses = db.courses
    .filter((course) => course.students.includes(normalizedCode))
    .map((course) => serializeStudentCourse(db, course));

  return sendJson(res, 200, {
    status: "success",
    data: courses
  });
}

function handleCreateCourse(res, db, body) {
  const courseName = String(body.course_name || "").trim();
  const courseCode = String(body.course_code || "").trim();
  const teacherId = Number(body.teacher_id);
  const startDate = String(body.start_date || "").trim();
  const endDate = String(body.end_date || "").trim();

  if (!courseName || !courseCode || !teacherId || !startDate || !endDate) {
    return sendJson(res, 400, {
      status: "error",
      message: "course_name, course_code, teacher_id, start_date y end_date son obligatorios"
    });
  }

  const teacher = findUserById(db, teacherId);
  if (!teacher || teacher.role !== "TEACHER") {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro el docente asignado"
    });
  }

  const course = {
    course_id: nextId(db.courses, "course_id"),
    course_name: courseName,
    course_code: courseCode,
    teacher_id: teacherId,
    classroom: String(body.classroom || "").trim() || "Por definir",
    career: String(body.career || "").trim() || "Por definir",
    group_name: String(body.group_name || "").trim() || "Grupo unico",
    start_date: startDate,
    end_date: endDate,
    absence_limit: Number(body.absence_limit) || 3,
    schedule_blocks: Array.isArray(body.schedule_blocks) ? body.schedule_blocks : [],
    students: Array.isArray(body.students) ? body.students.filter(Boolean) : []
  };

  db.courses.push(course);
  writeDB(db);

  return sendJson(res, 201, {
    status: "success",
    data: serializeTeacherCourse(db, course),
    message: "Clase creada exitosamente"
  });
}

function handleUpdateCourse(res, db, courseId, body) {
  const course = db.courses.find((item) => item.course_id === courseId);

  if (!course) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la clase"
    });
  }

  course.course_name = String(body.course_name || course.course_name).trim() || course.course_name;
  course.course_code = String(body.course_code || course.course_code).trim() || course.course_code;
  course.classroom = String(body.classroom || course.classroom).trim() || course.classroom;
  course.career = String(body.career || course.career).trim() || course.career;
  course.group_name = String(body.group_name || course.group_name).trim() || course.group_name;
  course.start_date = String(body.start_date || course.start_date).trim() || course.start_date;
  course.end_date = String(body.end_date || course.end_date).trim() || course.end_date;
  course.absence_limit = Number(body.absence_limit) || course.absence_limit;

  if (Array.isArray(body.schedule_blocks)) {
    course.schedule_blocks = body.schedule_blocks;
  }

  writeDB(db);

  return sendJson(res, 200, {
    status: "success",
    data: serializeTeacherCourse(db, course),
    message: "Clase actualizada exitosamente"
  });
}

function handleDeleteCourse(res, db, courseId) {
  const courseIndex = db.courses.findIndex((item) => item.course_id === courseId);

  if (courseIndex === -1) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la clase"
    });
  }

  db.courses.splice(courseIndex, 1);
  db.attendances = db.attendances.filter((attendance) => attendance.course_id !== courseId);
  db.excuses = db.excuses.filter((excuse) => excuse.course_id !== courseId);
  db.attendance_sessions = db.attendance_sessions.filter((session) => session.course_id !== courseId);
  writeDB(db);

  return sendJson(res, 200, {
    status: "success",
    message: "Clase eliminada exitosamente"
  });
}

function handleCourseStudents(res, db, courseId) {
  const course = db.courses.find((item) => item.course_id === courseId);

  if (!course) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la clase"
    });
  }

  const students = course.students
    .map((studentCode) => findUserByCode(db, studentCode))
    .filter(Boolean)
    .map((student) => serializeStudent(student, db, course.course_id));

  return sendJson(res, 200, {
    status: "success",
    data: students
  });
}

function handleAddStudentToCourse(res, db, courseId, body) {
  const course = db.courses.find((item) => item.course_id === courseId);

  if (!course) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la clase"
    });
  }

  const studentCode = String(body.student_code || "").trim();
  if (!studentCode) {
    return sendJson(res, 400, {
      status: "error",
      message: "Debes enviar la matricula del alumno"
    });
  }

  if (course.students.includes(studentCode)) {
    return sendJson(res, 409, {
      status: "error",
      message: "El alumno ya esta inscrito en la clase"
    });
  }

  const student = findUserByCode(db, studentCode);
  if (!student || student.role !== "STUDENT") {
    return sendJson(res, 404, {
      status: "error",
      message: "La matricula no existe. El alumno debe registrarse primero."
    });
  }

  course.students.push(studentCode);
  writeDB(db);

  return sendJson(res, 201, {
    status: "success",
    data: serializeStudent(student, db, course.course_id),
    message: "Alumno agregado exitosamente"
  });
}

function handleRemoveStudentFromCourse(res, db, courseId, studentCode) {
  const course = db.courses.find((item) => item.course_id === courseId);

  if (!course) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la clase"
    });
  }

  if (!course.students.includes(studentCode)) {
    return sendJson(res, 404, {
      status: "error",
      message: "El alumno no pertenece a esta clase"
    });
  }

  course.students = course.students.filter((code) => code !== studentCode);
  writeDB(db);

  return sendJson(res, 200, {
    status: "success",
    message: "Alumno eliminado del grupo"
  });
}

function handleAttendance(res, db, body) {
  const studentCode = String(body.student_code || "").trim();
  const courseId = Number(body.course_id);

  const result = createAttendance(db, {
    studentCode,
    courseId
  });

  if (result.error) {
    return sendJson(res, result.statusCode, {
      status: "error",
      message: result.error
    });
  }

  writeDB(db);

  return sendJson(res, 201, {
    status: "success",
    message: "Asistencia registrada: PRESENTE",
    data: result.attendance
  });
}

function handleExcuse(res, db, body) {
  const attendanceId = Number(body.attendance_id);
  const reason = String(body.reason || "").trim();

  if (!attendanceId || !reason) {
    return sendJson(res, 400, {
      status: "error",
      message: "attendance_id y reason son obligatorios"
    });
  }

  const attendance = db.attendances.find((item) => item.attendance_id === attendanceId);
  if (!attendance) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la asistencia a justificar"
    });
  }

  if (db.excuses.some((item) => item.attendance_id === attendanceId)) {
    return sendJson(res, 409, {
      status: "error",
      message: "Ese justificante ya fue enviado anteriormente"
    });
  }

  const excuse = {
    excuse_id: nextId(db.excuses, "excuse_id"),
    attendance_id: attendanceId,
    student_code: attendance.student_code,
    course_id: attendance.course_id,
    reason,
    status: "PENDING",
    created_at: new Date().toISOString()
  };

  db.excuses.push(excuse);
  attendance.status = "PENDING";
  writeDB(db);

  return sendJson(res, 201, {
    status: "success",
    message: "Justificante enviado a revision exitosamente"
  });
}

function handleStudentAttendances(res, db, studentCode) {
  const user = findUserByCode(db, studentCode);

  if (!user || user.role !== "STUDENT") {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro al alumno"
    });
  }

  const data = db.attendances
    .filter((attendance) => attendance.student_code === studentCode)
    .map((attendance) => {
      const course = findCourseById(db, attendance.course_id);
      const excuse = db.excuses.find((item) => item.attendance_id === attendance.attendance_id);

      return {
        attendance_id: attendance.attendance_id,
        course_id: attendance.course_id,
        course_name: course?.course_name || "Clase",
        date: attendance.date,
        time: attendance.time,
        status: attendance.status,
        reason: excuse?.reason || null
      };
    });

  return sendJson(res, 200, {
    status: "success",
    data
  });
}

function handleStudentDigitalID(res, db, studentCode) {
  const user = findUserByCode(db, studentCode);

  if (!user || user.role !== "STUDENT") {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro al alumno"
    });
  }

  return sendJson(res, 200, {
    status: "success",
    data: {
      student_code: user.code,
      qr_value: user.code,
      name: `${user.first_name} ${user.last_name}`.trim()
    }
  });
}

function handleTeacherCourses(res, db, teacherId) {
  const courses = db.courses
    .filter((course) => (teacherId ? course.teacher_id === teacherId : true))
    .map((course) => serializeTeacherCourse(db, course));

  return sendJson(res, 200, {
    status: "success",
    data: courses
  });
}

function handleCreateAttendanceSession(res, db, body) {
  const courseId = Number(body.course_id);
  const teacherId = Number(body.teacher_id);
  const course = findCourseById(db, courseId);

  if (!teacherId) {
    return sendJson(res, 400, {
      status: "error",
      message: "teacher_id es obligatorio"
    });
  }

  if (!course) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la clase para abrir la asistencia"
    });
  }

  const teacher = findUserById(db, teacherId);
  if (!teacher || teacher.role !== "TEACHER") {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro el docente"
    });
  }

  if (course.teacher_id !== teacherId) {
    return sendJson(res, 403, {
      status: "error",
      message: "Esta clase no pertenece al docente autenticado"
    });
  }

  const startedAt = new Date();
  const expiresAt = new Date(startedAt.getTime() + 5 * 60 * 1000);

  const session = {
    session_id: nextId(db.attendance_sessions, "session_id"),
    teacher_id: teacherId,
    course_id: courseId,
    started_at: startedAt.toISOString(),
    expires_at: expiresAt.toISOString(),
    scanned_codes: []
  };

  db.attendance_sessions.push(session);
  writeDB(db);

  return sendJson(res, 201, {
    status: "success",
    data: serializeAttendanceSession(db, session),
    message: "Ventana de asistencia iniciada"
  });
}

function handleAttendanceSessionStatus(res, db, sessionId) {
  const session = db.attendance_sessions.find((item) => item.session_id === sessionId);

  if (!session) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la sesion de asistencia"
    });
  }

  return sendJson(res, 200, {
    status: "success",
    data: serializeAttendanceSession(db, session)
  });
}

function handleAttendanceSessionScan(res, db, sessionId, body) {
  const session = db.attendance_sessions.find((item) => item.session_id === sessionId);

  if (!session) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro la sesion de asistencia"
    });
  }

  if (new Date(session.expires_at).getTime() <= Date.now()) {
    return sendJson(res, 409, {
      status: "error",
      message: "La ventana de 5 minutos ya expiro"
    });
  }

  const studentCode = String(body.student_code || "").trim();
  if (!studentCode) {
    return sendJson(res, 400, {
      status: "error",
      message: "Debes enviar la matricula del alumno"
    });
  }

  if (session.scanned_codes.includes(studentCode)) {
    return sendJson(res, 409, {
      status: "error",
      message: "Ese QR ya fue escaneado durante esta sesion"
    });
  }

  const result = createAttendance(db, {
    studentCode,
    courseId: session.course_id
  });

  if (result.error) {
    return sendJson(res, result.statusCode, {
      status: "error",
      message: result.error
    });
  }

  session.scanned_codes.push(studentCode);
  writeDB(db);

  return sendJson(res, 201, {
    status: "success",
    message: "Asistencia escaneada correctamente",
    data: {
      session: serializeAttendanceSession(db, session),
      attendance: result.attendance
    }
  });
}

function handlePendingJustifications(res, db) {
  const data = db.excuses
    .filter((excuse) => excuse.status === "PENDING")
    .map((excuse) => serializeExcuse(db, excuse));

  return sendJson(res, 200, {
    status: "success",
    data
  });
}

function handleJustificationDecision(res, db, excuseId, decision) {
  const excuse = db.excuses.find((item) => item.excuse_id === excuseId);

  if (!excuse) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro el justificante"
    });
  }

  const attendance = db.attendances.find((item) => item.attendance_id === excuse.attendance_id);
  excuse.status = decision;

  if (attendance) {
    attendance.status = decision === "APPROVED" ? "JUSTIFICADA" : "AUSENTE";
  }

  writeDB(db);

  return sendJson(res, 200, {
    status: "success",
    message: decision === "APPROVED" ? "Justificante aprobado" : "Justificante rechazado"
  });
}

function handleTeacherPasswordUpdate(res, db, body) {
  const email = String(body.email || "").trim().toLowerCase();
  const currentPassword = String(body.current_password || "").trim();
  const newPassword = String(body.new_password || "").trim();
  const confirmation = String(body.confirmation || "").trim();

  if (!email) {
    return sendJson(res, 400, {
      status: "error",
      message: "email es obligatorio"
    });
  }

  const teacher = db.users.find(
    (item) => item.role === "TEACHER" && item.email.toLowerCase() === email
  );

  if (!teacher) {
    return sendJson(res, 404, {
      status: "error",
      message: "No se encontro el docente"
    });
  }

  if (!currentPassword || !newPassword || !confirmation) {
    return sendJson(res, 400, {
      status: "error",
      message: "Completa current_password, new_password y confirmation"
    });
  }

  if (teacher.password !== currentPassword) {
    return sendJson(res, 401, {
      status: "error",
      message: "La contrasena actual no coincide"
    });
  }

  if (newPassword !== confirmation) {
    return sendJson(res, 400, {
      status: "error",
      message: "La nueva contrasena y su confirmacion no coinciden"
    });
  }

  teacher.password = newPassword;
  writeDB(db);

  return sendJson(res, 200, {
    status: "success",
    message: "Contrasena actualizada exitosamente"
  });
}

function createAttendance(db, { studentCode, courseId }) {
  if (!studentCode || !courseId) {
    return {
      statusCode: 400,
      error: "Debes enviar student_code y course_id"
    };
  }

  const course = findCourseById(db, courseId);
  if (!course) {
    return {
      statusCode: 404,
      error: "No se encontro la clase seleccionada"
    };
  }

  const student = findUserByCode(db, studentCode);
  if (!student || student.role !== "STUDENT") {
    return {
      statusCode: 404,
      error: "No se encontro al alumno"
    };
  }

  if (!course.students.includes(studentCode)) {
    return {
      statusCode: 409,
      error: "La matricula no pertenece al grupo seleccionado"
    };
  }

  const today = currentISODate();
  const duplicated = db.attendances.find(
    (attendance) =>
      attendance.student_code === studentCode &&
      attendance.course_id === courseId &&
      attendance.date === today
  );

  if (duplicated) {
    return {
      statusCode: 409,
      error: "La asistencia de hoy ya fue registrada para este alumno"
    };
  }

  const attendance = {
    attendance_id: nextId(db.attendances, "attendance_id"),
    student_code: studentCode,
    course_id: courseId,
    date: today,
    time: courseTimeLabel(course),
    status: "PRESENTE"
  };

  db.attendances.push(attendance);

  return {
    attendance
  };
}

function serializeSessionUser(user) {
  return {
    id: user.id,
    code: user.code,
    first_name: user.first_name,
    last_name: user.last_name,
    email: user.email,
    role: user.role
  };
}

function serializeStudentCourse(db, course) {
  const teacher = findUserById(db, course.teacher_id);
  return {
    course_id: course.course_id,
    course_name: course.course_name,
    course_code: course.course_code,
    start_date: course.start_date,
    end_date: course.end_date,
    teacher_name: teacher ? `${teacher.first_name} ${teacher.last_name}`.trim() : "Docente"
  };
}

function serializeTeacherCourse(db, course) {
  const teacher = findUserById(db, course.teacher_id);
  return {
    course_id: course.course_id,
    course_name: course.course_name,
    course_code: course.course_code,
    teacher_id: course.teacher_id,
    teacher_name: teacher ? `${teacher.first_name} ${teacher.last_name}`.trim() : "Docente",
    classroom: course.classroom,
    career: course.career,
    group_name: course.group_name,
    start_date: course.start_date,
    end_date: course.end_date,
    absence_limit: course.absence_limit,
    schedule_blocks: course.schedule_blocks,
    students: course.students
      .map((studentCode) => findUserByCode(db, studentCode))
      .filter(Boolean)
      .map((student) => serializeStudent(student, db, course.course_id))
  };
}

function serializeStudent(student, db = null, courseId = null) {
  const basePayload = {
    id: student.id,
    code: student.code,
    first_name: student.first_name,
    last_name: student.last_name,
    email: student.email,
    role: student.role
  };

  if (!db || !courseId) {
    return basePayload;
  }

  return {
    ...basePayload,
    attendance_status: latestAttendanceStatus(db, student.code, courseId),
    streak: attendanceStreak(db, student.code, courseId)
  };
}

function serializeExcuse(db, excuse) {
  const student = findUserByCode(db, excuse.student_code);
  const course = findCourseById(db, excuse.course_id);
  const attendance = db.attendances.find((item) => item.attendance_id === excuse.attendance_id);

  return {
    excuse_id: excuse.excuse_id,
    attendance_id: excuse.attendance_id,
    course_id: excuse.course_id,
    student_name: student ? `${student.first_name} ${student.last_name}`.trim() : "Alumno",
    student_code: excuse.student_code,
    course_title: course?.course_name || "Clase",
    date: attendance ? `${attendance.date} · Horario: ${attendance.time}` : excuse.created_at,
    summary: excuse.reason,
    status: excuse.status
  };
}

function serializeAttendanceSession(db, session) {
  const course = findCourseById(db, session.course_id);
  return {
    session_id: session.session_id,
    course_id: session.course_id,
    course_name: course?.course_name || "Clase",
    started_at: session.started_at,
    expires_at: session.expires_at,
    remaining_seconds: Math.max(
      0,
      Math.floor((new Date(session.expires_at).getTime() - Date.now()) / 1000)
    ),
    scanned_codes: session.scanned_codes
  };
}

function findUserById(db, id) {
  return db.users.find((user) => user.id === id);
}

function findUserByCode(db, code) {
  return db.users.find((user) => user.code === code);
}

function findCourseById(db, courseId) {
  return db.courses.find((course) => course.course_id === courseId);
}

function latestAttendanceStatus(db, studentCode, courseId) {
  const latest = db.attendances
    .filter(
      (attendance) =>
        attendance.student_code === studentCode &&
        attendance.course_id === courseId
    )
    .sort((left, right) => {
      const leftStamp = `${left.date}T${left.time}`;
      const rightStamp = `${right.date}T${right.time}`;
      return rightStamp.localeCompare(leftStamp);
    })[0];

  return latest?.status || "SIN_REGISTRO";
}

function attendanceStreak(db, studentCode, courseId) {
  const records = db.attendances
    .filter(
      (attendance) =>
        attendance.student_code === studentCode &&
        attendance.course_id === courseId
    )
    .sort((left, right) => {
      const leftStamp = `${left.date}T${left.time}`;
      const rightStamp = `${right.date}T${right.time}`;
      return rightStamp.localeCompare(leftStamp);
    });

  let streak = 0;
  for (const record of records) {
    if (record.status === "PRESENTE" || record.status === "RETARDO" || record.status === "JUSTIFICADA") {
      streak += 1;
      continue;
    }
    break;
  }

  return streak;
}

function nextId(collection, key) {
  return collection.reduce((maxValue, item) => {
    return Math.max(maxValue, Number(item[key]) || 0);
  }, 0) + 1;
}

function currentISODate() {
  return new Date().toISOString().slice(0, 10);
}

function courseTimeLabel(course) {
  const firstBlock = course.schedule_blocks[0];
  if (!firstBlock) {
    return "Por definir";
  }

  return `${firstBlock.start_time} - ${firstBlock.end_time}`;
}
