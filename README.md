# Zora — Asistente de voz por aplausos (v0.1)

**Creado por:** Ronaldo de Posada Plaza

Zora es un asistente virtual 100% local y de código abierto diseñado para macOS (optimizado para Apple Silicon). Se activa mediante aplausos, no requiere conexión a internet para el procesamiento de voz y se integra de forma nativa con el sistema operativo para controlar la música y el volumen.

---

## Gestos disponibles

Zora calibra el ruido ambiental automáticamente al iniciar y se queda escuchando en segundo plano.

| Aplausos  | Acción                                                               |
|-----------|----------------------------------------------------------------------|
| **2**     | Despertar + Reporte del clima + Iniciar música (Solo la primera vez) |
| **2**     | Pausar / Reanudar la música actual                                   |
| **3**     | Apagar                                                               |


---

## Instalación

Sigue estos pasos para instalar a Zora en tu Mac.

### 1. Requisitos previos y dependencias

Asegúrate de tener Python instalado. Abre tu terminal y ejecuta los siguientes comandos para instalar las librerías necesarias:

```bash
pip install pyaudio requests numpy kokoro-onnx sounddevice
```

> **Nota para usuarios de macOS:** Si la instalación de `pyaudio` falla, necesitas instalar el motor de audio del sistema primero usando Homebrew:
> ```bash
> brew install portaudio
> pip install pyaudio
> ```

---

### 2. Motor de Voz: Kokoro TTS (Gratis y Local)

Zora utiliza **Kokoro ONNX**, un sintetizador de voz neuronal increíblemente ligero y rápido que corre de manera nativa en tu Mac.

Para que Zora pueda hablar, necesitas descargar los archivos del modelo de lenguaje y colocarlos en la carpeta principal de tu proyecto:

1. Descarga el modelo principal (`kokoro-v1.0.onnx`).
2. Descarga el paquete de voces (`voices-v1.0.bin`).
3. Guarda ambos archivos en la misma carpeta donde está `detector.py`.

---

### 3. Estructura final del proyecto

Tu carpeta principal debería verse exactamente así antes de ejecutar a Zora:
> ```bash
> Zora/
>  ├── detector.py
>  ├── config.json
>  ├── Iniciar_Zora.command
>  ├── kokoro-v1.0.onnx
>  └── voices-v1.0.bin
> ```
---

## Configuración (`config.json`)

Al ejecutar el proyecto por primera vez, se generará (o puedes crear/editar) un archivo `config.json`. Puedes personalizar Zora a tu gusto:

- **`owner`**: Tu nombre (Zora lo usará para saludarte).
- **`location`**: Cambia la latitud, longitud y ciudad para que el reporte del clima sea exacto a tu ubicación actual.
- **`music`**: Cambia los nombres por las playlists exactas que tengas en Apple Music, divididas por momento del día (mañana, tarde, noche).
- **`audio`**:
  - `startup_delay`: Tiempo en segundos que Zora espera al abrirse para que el micrófono de la Mac "despierte".
  - `min_threshold`: Volumen mínimo (ej. `3000`) para que un sonido sea considerado un aplauso.
  - `threshold_multiplier`: Multiplicador del ruido base. Súbelo si Zora se activa con ruidos falsos; bájalo si no te escucha bien.
- **`tts`**: Verifica que `"voice"` esté configurado con la voz que prefieras (por defecto `"ef_dora"`).

---

## Cómo iniciar a Zora

Simplemente ejecuta el script principal desde tu terminal:

```bash
python detector.py
```

> **Opcional:** Puedes crear un ejecutable `.command` en tu escritorio para iniciar a Zora con un doble clic.

---

## Próximos pasos (Roadmap)

- [ ] Integración de modo voz con OpenAI Whisper (STT local, gratis).
- [ ] Comandos conversacionales por voz con modelos LLM.
- [ ] Control de luces inteligentes (Home Assistant).
- [ ] Modo "no molestar" automatizado por horario.
