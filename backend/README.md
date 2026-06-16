# Borealista Backend

Backend local en Node.js para soportar el flujo alumno/docente de Borealista.

## Ejecutar

```bash
cd backend
npm start
```

Servidor base local:

```text
http://localhost:8080/BorealistaAPI/api
```

Servidor desplegado en AWS al 16 de junio de 2026:

```text
http://3.131.135.169:8080/BorealistaAPI/api
```

## Endpoints principales

- `POST /login`
- `POST /register`
- `GET /courses?student_code={matricula}`
- `POST /attendance`
- `POST /excuses`
- `GET /students/:studentCode/attendances`
- `GET /students/:studentCode/digital-id`
- `GET /teacher/courses`
- `POST /courses`
- `PUT /courses/:courseId`
- `DELETE /courses/:courseId`
- `GET /courses/:courseId/students`
- `POST /courses/:courseId/students`
- `DELETE /courses/:courseId/students/:studentCode`
- `GET /justifications/pending`
- `POST /justifications/:justificationId/approve`
- `POST /justifications/:justificationId/reject`
- `PATCH /teacher/profile/password`

## Ventana docente de 5 minutos

Para endurecer el pase de lista desde el celular del docente tambien se incluyen:

- `POST /teacher/attendance-sessions`
- `GET /teacher/attendance-sessions/:sessionId`
- `POST /teacher/attendance-sessions/:sessionId/scan`

Esos endpoints permiten abrir una sesion de asistencia de 5 minutos y registrar cada QR escaneado dentro de esa ventana.

## Reglas reales de negocio

- Un profesor ya no entra a ningun modo demo: `POST /register` y `POST /login` trabajan con datos persistidos.
- `POST /courses/:courseId/students` ya no crea alumnos placeholder. La matricula debe existir primero como alumno registrado.
- `POST /teacher/attendance-sessions` exige `teacher_id` real y valida que la clase pertenezca a ese docente.
- `PATCH /teacher/profile/password` exige `email` real del profesor autenticado.

## iPhone fisico

Si vas a correr el backend en tu Mac y la app en tu iPhone, cambia `BOREALISTA_API_BASE_URL` en `Borealista/Info.plist` por algo como:

```text
http://TU_IP_LOCAL:8080/BorealistaAPI/api
```

Ejemplo: `http://192.168.1.20:8080/BorealistaAPI/api`
