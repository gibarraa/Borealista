# Cumplimiento de rubrica

Fecha: 15 de junio de 2026

## 1. App con 5 o mas vistas interconectadas

Cumplido.

Vistas implementadas:

- Login / registro
- Mis clases alumno
- Detalle de clase alumno
- Identificador QR
- Mis faltas
- Justificante
- Confirmacion
- Dashboard docente
- Detalle de clase docente
- Nueva clase
- Ajustes de clase
- Editor de horario
- Alumnos del grupo
- Toma de asistencia
- Justificantes pendientes
- Perfil docente

Archivos principales:

- `Borealista/Sources/Screens/Auth/AuthViews.swift`
- `Borealista/Sources/Screens/Student/StudentViews.swift`
- `Borealista/Sources/Screens/Teacher/TeacherViews.swift`

## 2. Navegacion a detalle y modal

Cumplido.

- `NavigationStack` para detalle de clase, alumnos, ajustes y asistencia.
- `sheet` para composer de clase y editor de horario.
- flujo de confirmacion para borrar clase y borrar alumno.

## 3. Minimo 3 componentes reutilizables

Cumplido.

Ejemplos claros:

- `PremiumCard`
- `FormField`
- `PrimaryActionButton`
- `SecondaryActionButton`
- `TeacherTabBar`
- `StudentTabBar`
- `QRCodeView`

Archivos:

- `Borealista/Sources/Theme/DesignSystem.swift`
- `Borealista/Sources/Components/PremiumComponents.swift`

## 4. Uso de texto, imagen y minimo 4 controles

Cumplido.

Controles usados:

- `TextField`
- `SecureField`
- `Button`
- `Toggle`
- `ScrollView`
- `NavigationStack`
- `sheet`

Imagenes usadas:

- logo Borealista
- QR del alumno
- iconografia SF Symbols

## 5. Stacks y organizacion visual

Cumplido.

Se usan `VStack`, `HStack` y `ZStack` en toda la aplicacion para layout, overlays glass y barras flotantes.

## 6. Listas o contenedores desplazables

Cumplido.

- `ShellScrollView`
- listas de cursos
- listas de faltas
- lista de justificantes
- lista de alumnos
- lista de escaneos de asistencia

## 7. Manejo de estado con `@State`

Cumplido.

Ejemplos:

- formularios de auth
- navegacion
- timer de asistencia
- escaneo QR
- formularios de clase
- busqueda de alumnos
- editor de horario
- confirmaciones modales

Archivos:

- `Borealista/Sources/App/AppModel.swift`
- `Borealista/Sources/Screens/Teacher/TeacherViews.swift`
- `Borealista/Sources/Screens/Student/StudentViews.swift`

## 8. Consumo de REST API

Cumplido.

Cliente iOS:

- `POST /login`
- `POST /register`
- `GET /courses`
- `POST /excuses`
- `POST /attendance`

Backend local incluido:

- `backend/src/server.js`
- `backend/data/db.json`

## 9. Documento con problema, justificacion, mockup y logo

Cumplido.

Documentos entregados:

- `docs/entregable_borealista.md`
- `docs/cumplimiento_rubrica.md`
- `docs/API_ALUMNO_MOCKS.md`
- `backend/README.md`

Assets entregados:

- `docs/assets/logo-borealista.png`
- `docs/assets/rubrica-pagina-1.png`
- `docs/assets/rubrica-pagina-2.png`

## 10. Alineacion funcional extra solicitada por proyecto

Cumplido.

Puntos cerrados:

- QR generado a partir de la matricula del alumno
- docente toma asistencia desde su celular
- seleccion de clase antes de pasar lista
- boton `Tomar asistencia`
- ventana activa de 5 minutos
- endpoints locales para alumno y docente
- branding Borealista integrado en la app
