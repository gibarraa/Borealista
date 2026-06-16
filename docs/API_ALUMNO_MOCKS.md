# Borealista API local - estado actual

Fecha de corte: 15 de junio de 2026

## Base local

```text
http://localhost:8080/BorealistaAPI/api
```

## Alumno

### `POST /login`

Autentica alumno o docente.

Ejemplo:

```json
{
  "email": "julio.romero0079866@borealista.edu",
  "password": "Borealista123",
  "role": "STUDENT"
}
```

### `POST /register`

Registra alumnos y docentes.

### `GET /courses?student_code={matricula}`

Devuelve las materias inscritas del alumno.

### `POST /attendance`

Registra asistencia con `student_code` y `course_id`.

### `POST /excuses`

Envia un justificante por `attendance_id`.

### `GET /students/{student_code}/attendances`

Devuelve el historial de asistencias/faltas del alumno.

### `GET /students/{student_code}/digital-id`

Devuelve el QR oficial del alumno usando su matricula como payload.

## Docente

### `GET /teacher/courses`

Devuelve clases detalladas del docente con horario, grupo y alumnos.

### `POST /courses`

Crea una nueva clase.

### `PUT /courses/{course_id}`

Actualiza una clase existente.

### `DELETE /courses/{course_id}`

Elimina una clase y limpia sus dependencias.

### `GET /courses/{course_id}/students`

Lista alumnos de un grupo.

### `POST /courses/{course_id}/students`

Agrega alumno por matricula al grupo.

### `DELETE /courses/{course_id}/students/{student_code}`

Elimina alumno del grupo.

### `GET /justifications/pending`

Obtiene justificantes pendientes por revisar.

### `POST /justifications/{excuse_id}/approve`

Aprueba el justificante y cambia la asistencia a `JUSTIFICADA`.

### `POST /justifications/{excuse_id}/reject`

Rechaza el justificante y conserva la falta.

### `PATCH /teacher/profile/password`

Actualiza la contrasena del docente.

## Ventana docente de 5 minutos

Se agregaron endpoints para soportar el pase de lista por QR desde el celular del docente:

### `POST /teacher/attendance-sessions`

Abre una ventana de 5 minutos para una clase.

### `GET /teacher/attendance-sessions/{session_id}`

Consulta estado y tiempo restante.

### `POST /teacher/attendance-sessions/{session_id}/scan`

Registra cada QR escaneado dentro de la sesion.

## Semilla incluida

Alumno demo compatible con el QR del front:

- Nombre: `Julio Cesar Romero Tavares`
- Matricula: `0079866`
- Email: `julio.romero0079866@borealista.edu`
- Password: `Borealista123`

Docente demo:

- Nombre: `Ana Maria Torres`
- Clave: `FAC-204`
- Email: `ana.torres@borealista.edu`
- Password: `Borealista123`
