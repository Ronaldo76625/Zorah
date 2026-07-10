import copy
import json
import math
import subprocess
import struct
import time
from datetime import datetime
from pathlib import Path

import requests

CONFIG_PATH = Path(__file__).parent / "config.json"

DEFAULT_CONFIG = {
    "audio": {
        "rate": 44100,
        "chunk": 1024,
        "threshold_multiplier": 3.5,
        "baseline_frames": 30,
        "min_gap_between_claps": 0.15,
        "max_gap_double_clap": 1.0,
        "max_gap_triple_clap": 0.8,
        "max_gap_quad_clap": 0.8,
        "startup_delay": 5.0,
        "min_threshold": 3000,
    },
    "location": {"latitude": 21.1619, "longitude": -86.8515, "city": "Cancún"},
    "music": {
        "playlist_morning": "Canciones favoritas",
        "playlist_afternoon": "Canciones favoritas",
        "playlist_evening": "Canciones favoritas",
        "playlist_night": "Canciones favoritas",
    },
    "tts": {
        "engine": "kokoro",
        "kokoro_model": "kokoro-v1.0.onnx",
        "kokoro_voices": "voices-v1.0.bin",
        "voice": "ef_dora",
        "speed": 1.0,
        "lang": "es",
    },
    "owner": "Ronaldo",
    "notify_mac": True,
}


def load_config() -> dict:
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH) as f:
            saved = json.load(f)
        merged = copy.deepcopy(DEFAULT_CONFIG)
        for key, val in saved.items():
            if isinstance(val, dict) and key in merged:
                merged[key].update(val)
            else:
                merged[key] = val
        return merged
    else:
        with open(CONFIG_PATH, "w") as f:
            json.dump(DEFAULT_CONFIG, f, indent=2, ensure_ascii=False)
        return copy.deepcopy(DEFAULT_CONFIG)


CFG = load_config()
kokoro_instance = None


def hablar(texto: str):
    global kokoro_instance
    engine = CFG["tts"]["engine"]

    if engine == "kokoro":
        try:
            import sounddevice as sd
            from kokoro_onnx import Kokoro

            if kokoro_instance is None:
                print("[tts] Cargando modelo Kokoro en memoria...")
                model_path = Path(__file__).parent / CFG["tts"]["kokoro_model"]
                voices_path = Path(__file__).parent / CFG["tts"]["kokoro_voices"]
                kokoro_instance = Kokoro(model_path, voices_path)

            voice = CFG["tts"]["voice"]
            speed = CFG["tts"]["speed"]
            lang = CFG["tts"]["lang"]

            samples, rate = kokoro_instance.create(
                texto, voice=voice, speed=speed, lang=lang
            )
            sd.play(samples, rate)
            sd.wait()
            return

        except Exception as e:
            print(f"[tts] Kokoro falló ({e}), usando say como fallback")

    subprocess.run(["say", texto], check=False)


def obtener_clima() -> str:
    lat = CFG["location"]["latitude"]
    lon = CFG["location"]["longitude"]
    try:
        url = (
            f"https://api.open-meteo.com/v1/forecast"
            f"?latitude={lat}&longitude={lon}&current_weather=true"
        )
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        resp = response.json()
        temp = resp["current_weather"]["temperature"]
        codigo = resp["current_weather"]["weathercode"]

        if codigo <= 1:
            condicion = "despejado"
        elif codigo <= 3:
            condicion = "nublado"
        elif codigo <= 69:
            condicion = "con lluvia"
        elif codigo <= 99:
            condicion = "con tormenta"
        else:
            condicion = "con clima variable"

        return f"estamos a {int(temp)} grados y el día está {condicion}"
    except Exception as e:
        print(f"[clima] Error: {e}")
        return "no pude verificar el clima en este momento"


def obtener_playlist() -> str:
    hora = datetime.now().hour
    m = CFG["music"]
    if hora < 12:
        return m["playlist_morning"]
    elif hora < 17:
        return m["playlist_afternoon"]
    elif hora < 21:
        return m["playlist_evening"]
    else:
        return m["playlist_night"]


def ejecutar_applescript(
    script: str,
    capturar_salida: bool = False,
    argumentos: list[str] | None = None,
):
    return subprocess.run(
        ["osascript", "-e", script, *(argumentos or [])],
        check=False,
        capture_output=capturar_salida,
        text=capturar_salida,
    )


def estado_musica() -> str:
    resultado = ejecutar_applescript(
        'tell application "Music" to return player state as text',
        capturar_salida=True,
    )
    return resultado.stdout.strip().lower() if resultado.returncode == 0 else "unknown"


def reproducir_musica():
    playlist = obtener_playlist()
    script = (
        "on run argv\n"
        'tell application "Music" to play playlist (item 1 of argv)\n'
        "end run"
    )
    ejecutar_applescript(script, argumentos=[playlist])
    print(f"[música] Reproduciendo: {playlist}")


def pausar_musica():
    ejecutar_applescript('tell application "Music" to pause')
    print("[música] Pausada")


def reanudar_musica():
    ejecutar_applescript('tell application "Music" to play')
    print("[música] Reanudada")


def cambiar_volumen(subir: bool):
    delta = 10 if subir else -10
    script = f'tell application "Music" to set sound volume to (sound volume + {delta})'
    ejecutar_applescript(script)
    accion = "subido" if subir else "bajado"
    print(f"[música] Volumen {accion}")


def notificar(titulo: str, mensaje: str):
    if not CFG.get("notify_mac", False):
        return
    script = "on run argv\n" \
        "display notification (item 2 of argv) with title \"Zorah\" subtitle (item 1 of argv)\n" \
        "end run"
    ejecutar_applescript(script, argumentos=[titulo, mensaje])


def saludo_por_hora() -> str:
    hora = datetime.now().hour
    nombre = CFG["owner"]
    if hora < 12:
        return f"Buenos días {nombre}"
    elif hora < 19:
        return f"Buenas tardes {nombre}"
    else:
        return f"Buenas noches {nombre}"


def ejecutar_gesto(cantidad: int, estado: dict) -> bool:
    """
    Ejecuta la acción correspondiente a la cantidad de aplausos.
    Devuelve True si el programa debe seguir corriendo, False si debe apagarse.
    """
    if cantidad == 2:
        if not estado["saludado"]:
            print("\n[gesto] Doble aplauso → despertar\n")
            reporte_clima = obtener_clima()
            saludo = saludo_por_hora()
            frase = f"{saludo}. Hoy {reporte_clima}. Enseguida pongo tu música."
            notificar("Zorah despertó", reporte_clima)
            hablar(frase)
            reproducir_musica()
            estado["saludado"] = True
            estado["reproduciendo"] = estado_musica() == "playing"
        else:
            reproduciendo = estado_musica() == "playing"
            if reproduciendo:
                print("\n[gesto] Doble aplauso → pausar\n")
                pausar_musica()
                hablar("Pausando la música.")
                notificar("Zorah", "Música pausada")
                estado["reproduciendo"] = False
            else:
                print("\n[gesto] Doble aplauso → reanudar\n")
                reanudar_musica()
                hablar("Reanudando.")
                notificar("Zorah", "Música reanudada")
                estado["reproduciendo"] = True
        return True

    elif cantidad == 3:
        print("\n[gesto] Triple aplauso → apagar Zorah\n")
        # Opcional: pausar la música antes de irse
        if estado.get("reproduciendo", False):
            pausar_musica()
        hablar("Apagando sistema. Hasta luego.")
        notificar("Zorah", "Desconectada")
        return False  # Esta es la señal para romper el ciclo principal

    # Si detecta 4 o 5 aplausos en el futuro, los puedes manejar aquí
    return True


def rms(data_bytes: bytes, chunk: int) -> float:
    muestras = struct.unpack(str(chunk) + "h", data_bytes)
    return math.sqrt(sum(x**2 for x in muestras) / chunk)


def ventana_para_gesto(cantidad: int, config_audio: dict) -> float:
    if cantidad >= 4:
        return config_audio["max_gap_quad_clap"]
    if cantidad == 3:
        return config_audio["max_gap_triple_clap"]
    return config_audio["max_gap_double_clap"]


def main():
    import pyaudio

    cfg_a = CFG["audio"]
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = cfg_a["rate"]
    CHUNK = cfg_a["chunk"]

    p = pyaudio.PyAudio()
    stream = p.open(
        format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK
    )

    print("=" * 40)
    print("  Zorah está escuchando...         ")
    print("  2 aplausos → despertar + música  ")
    print("  2 aplausos → pausar / reanudar   ")
    print("  3 aplausos → apagar / detener    ")
    print("  Ctrl+C para detener              ")
    print("=" * 40)

    espera = cfg_a.get("startup_delay", 5.0)
    print(f"[calibración] Esperando {espera} segundos a que el micrófono despierte...")
    time.sleep(espera)

    print("[calibración] Midiendo ruido ambiental...")
    baseline_samples = []
    for _ in range(cfg_a["baseline_frames"]):
        data = stream.read(CHUNK, exception_on_overflow=False)
        baseline_samples.append(rms(data, CHUNK))

    ruido_base = sum(baseline_samples) / len(baseline_samples)
    umbral = ruido_base * cfg_a["threshold_multiplier"]

    minimo_permitido = cfg_a.get("min_threshold", 3000)
    if umbral < minimo_permitido:
        umbral = minimo_permitido

    print(f"[calibración] Ruido base: {int(ruido_base)} | Umbral final: {int(umbral)}")

    estado = {"reproduciendo": False, "saludado": False}
    aplausos_detectados = 0
    ultimo_aplauso_tiempo = 0.0

    try:
        while True:
            data = stream.read(CHUNK, exception_on_overflow=False)
            volumen = rms(data, CHUNK)

            if volumen > umbral:
                ahora = time.time()
                if ahora - ultimo_aplauso_tiempo < cfg_a["min_gap_between_claps"]:
                    continue

                aplausos_detectados += 1
                print(f"[aplauso {aplausos_detectados}] vol={int(volumen)}")
                ultimo_aplauso_tiempo = ahora

            else:
                if aplausos_detectados > 0:
                    ahora = time.time()
                    ventana = ventana_para_gesto(aplausos_detectados, cfg_a)
                    if ahora - ultimo_aplauso_tiempo > ventana:
                        if aplausos_detectados >= 2:
                            if not ejecutar_gesto(aplausos_detectados, estado):
                                break
                        else:
                            print("[aplauso] Solo uno detectado, ignorando")
                        aplausos_detectados = 0

    except KeyboardInterrupt:
        print("\n[Zorah] Hasta luego.")

    finally:
        stream.stop_stream()
        stream.close()
        p.terminate()


if __name__ == "__main__":
    main()
