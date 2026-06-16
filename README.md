# Borealista

Proyecto iOS + backend local para Borealista.

## Estructura

- `Borealista.xcodeproj`: proyecto listo para abrir en Xcode.
- `Borealista/`: app SwiftUI.
- `backend/`: API local en Node.js para alumno y docente.
- `docs/`: evidencia, entregable y notas de rubrica.
- `project.yml`: configuracion fuente para XcodeGen.

## Requisitos

- macOS con Xcode instalado
- iOS Simulator o iPhone fisico
- Node.js 18+ para el backend

## Ejecutar backend

```bash
cd backend
npm start
```

Base local:

```text
http://localhost:8080/BorealistaAPI/api
```

## Ejecutar la app

1. Abre `Borealista.xcodeproj` en Xcode.
2. Si Xcode marca tema de firma, entra a `Signing & Capabilities` y selecciona tu equipo.
3. Corre el target `Borealista` en simulador o en tu iPhone.

La app viene apuntando por defecto al backend desplegado en:

```text
http://3.131.135.169:8080/BorealistaAPI/api
```

Si prefieres usar el backend local de tu Mac para probar en iPhone fisico, cambia `BOREALISTA_API_BASE_URL` en `Borealista/Info.plist` por tu IP local, por ejemplo:

```text
http://192.168.1.20:8080/BorealistaAPI/api
```

## Notas

- El QR del alumno se genera a partir de su matricula.
- El backend local incluye persistencia simple en `backend/data/db.json`.
- `project.yml` permite regenerar el proyecto si usas XcodeGen, pero no es obligatorio porque el `.xcodeproj` ya va incluido.
