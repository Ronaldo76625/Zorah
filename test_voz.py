from kokoro_onnx import Kokoro
import sounddevice as sd

kokoro = Kokoro("kokoro-v1.0.onnx", "voices-v1.0.bin")
samples, rate = kokoro.create("Hola Ronaldo, soy Zora", voice="ef_dora", speed=1.0, lang="es")
sd.play(samples, rate)
sd.wait()
