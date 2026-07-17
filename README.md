# SafeWalk 🛡️

Aplicación móvil de seguridad y emergencia desarrollada en Flutter. Permite activar una alerta SOS que comparte tu ubicación en tiempo real con tus contactos de emergencia, incluye un chat activo durante la emergencia, notificaciones push, y una función de registro de rutas con seguimiento en vivo.

## ✨ Funcionalidades

- **Autenticación** de usuarios con correo y contraseña (Firebase Auth)
- **Contactos de emergencia**: CRUD completo, con vinculación automática a cuentas de SafeWalk mediante el correo electrónico
- **Botón SOS**: crea una alerta de emergencia, comparte la ubicación en tiempo real y notifica a los contactos vinculados
- **Chat de emergencia**: disponible únicamente mientras la alerta esté activa
- **Notificaciones push** en tiempo real mediante Firebase Cloud Messaging y Cloud Functions
- **Historial de SOS**: registro de emergencias pasadas
- **Perfil de usuario** editable (nombre, teléfono)
- **Registro de ruta**: búsqueda de direcciones con autocompletado, cálculo de la mejor ruta a pie y seguimiento en vivo con re-ruteo automático
- **Llamada directa** a contactos desde la app

## 🛠️ Tecnologías utilizadas

- **Flutter / Dart** — desarrollo multiplataforma
- **Provider** — gestión de estado
- **Firebase Authentication** — autenticación de usuarios
- **Cloud Firestore** — base de datos en tiempo real
- **Firebase Cloud Messaging** — notificaciones push
- **Cloud Functions (Node.js)** — envío de notificaciones al crearse una alerta SOS
- **flutter_map + OpenStreetMap** — mapas, sin dependencia de Google Maps
- **Nominatim** — búsqueda de direcciones (geocodificación)
- **OSRM** — cálculo de rutas a pie
- **Geolocator** — ubicación en tiempo real
- **url_launcher** — llamadas telefónicas directas

---

## 📸 Capturas de pantalla




<p align="center">[LA APLICACION MOVIL CON EL ICON Y EL SPLASH SCREEN]</p>



<p align="center">

  <img width="45%" height="1600" alt="Imagen1" src="https://github.com/user-attachments/assets/f5e7336e-163d-4b50-b116-a6e5663e3617" />
  <img width="45%" height="1600" alt="Imagen2" src="https://github.com/user-attachments/assets/40a254df-63c5-4337-92d0-a126160d30a7" />
  <img width="45%" height="1600" alt="Imagen3" src="https://github.com/user-attachments/assets/4ff0f0f2-3d72-4c64-b3eb-147a353420bc" />
  <img width="45%" height="1600" alt="Imagen4" src="https://github.com/user-attachments/assets/05e8c11a-cbaa-4393-834f-396cb0dd89d8" />
  <img width="45%" height="1600" alt="Imagen5" src="https://github.com/user-attachments/assets/5f461711-fb2e-491d-8065-6cac6e3b867a" />
  <img width="45%" height="1600" alt="Imagen6" src="https://github.com/user-attachments/assets/09f57c02-03a1-4f70-90c3-f1b7cfe03ef5" />
  <img width="45%" height="1600" alt="Imagen7" src="https://github.com/user-attachments/assets/8a2f8170-713c-4bf8-b2c7-f97a7bd3191e" />
  <img width="45%" height="1600" alt="Imagen8" src="https://github.com/user-attachments/assets/a0ae526c-6086-4bd5-aedc-73024cfab0c9" />


</p>



---

## 📁 Estructura del proyecto

```
lib/
├── main.dart
├── core/
│   └── theme/              # Tema y paleta de colores de la app
├── data/
│   └── models/              # Modelos de datos (SosEvent, EmergencyContact, ChatMessage, etc.)
└── presentation/
    ├── providers/            # Lógica de negocio (ChangeNotifier)
    └── screens/              # Pantallas de la aplicación
        ├── auth/
        ├── contacts/
        ├── home/
        ├── profile/
        ├── route/
        └── sos/
```

## 🚀 Cómo ejecutar el proyecto

### Requisitos previos

- Flutter SDK instalado
- Cuenta de Firebase (plan Blaze, necesario para Cloud Functions)
- Firebase CLI y FlutterFire CLI instalados

### Pasos

1. Clona el repositorio:
   ```bash
   git clone https://github.com/AlmeidaKevin/safewalk.git
   cd safewalk
   ```

2. Instala las dependencias:
   ```bash
   flutter pub get
   ```

3. Configura Firebase para el proyecto:
   ```bash
   flutterfire configure
   ```

4. Habilita en tu proyecto de Firebase:
   - **Authentication** → método Correo/Contraseña
   - **Cloud Firestore** → en modo producción, aplicando las reglas de `firestore.rules`
   - **Cloud Messaging**

5. Despliega la Cloud Function encargada de las notificaciones:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

6. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## 🔒 Seguridad

Las reglas de Firestore (`firestore.rules`) restringen el acceso de modo que:
- Cada usuario solo puede leer/modificar sus propios contactos
- Un evento SOS solo es visible para su dueño y los contactos notificados
- El chat de emergencia solo es accesible mientras la alerta esté activa

## 👤 Autor

**Kevin Almeida** — [@AlmeidaKevin](https://github.com/AlmeidaKevin)
**Diego Montaluisa**
**Pablo Erazo**
**Alessia de los Angeles**
