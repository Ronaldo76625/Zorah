import copy
import struct
import unittest
from unittest.mock import patch

import detector


class DetectorTests(unittest.TestCase):
    def test_default_location_is_valid(self):
        latitude = detector.DEFAULT_CONFIG["location"]["latitude"]
        longitude = detector.DEFAULT_CONFIG["location"]["longitude"]

        self.assertGreaterEqual(latitude, -90)
        self.assertLessEqual(latitude, 90)
        self.assertGreaterEqual(longitude, -180)
        self.assertLessEqual(longitude, 180)

    def test_rms_for_constant_signal(self):
        samples = [1_000] * 4
        audio = struct.pack("4h", *samples)

        self.assertEqual(detector.rms(audio, 4), 1_000)

    def test_each_gesture_uses_its_configured_window(self):
        audio_config = detector.DEFAULT_CONFIG["audio"]

        self.assertEqual(
            detector.ventana_para_gesto(2, audio_config),
            audio_config["max_gap_double_clap"],
        )
        self.assertEqual(
            detector.ventana_para_gesto(3, audio_config),
            audio_config["max_gap_triple_clap"],
        )
        self.assertEqual(
            detector.ventana_para_gesto(4, audio_config),
            audio_config["max_gap_quad_clap"],
        )

    @patch("detector.datetime")
    def test_playlist_changes_by_time(self, mocked_datetime):
        config = copy.deepcopy(detector.CFG)
        config["music"] = {
            "playlist_morning": "Mañana",
            "playlist_afternoon": "Tarde",
            "playlist_evening": "Noche",
            "playlist_night": "Madrugada",
        }

        with patch.object(detector, "CFG", config):
            mocked_datetime.now.return_value.hour = 14
            self.assertEqual(detector.obtener_playlist(), "Tarde")

    @patch("detector.ejecutar_applescript")
    @patch("detector.obtener_playlist", return_value='Lista "personal"')
    def test_playlist_is_passed_as_applescript_argument(self, _, mocked_script):
        detector.reproducir_musica()

        self.assertEqual(
            mocked_script.call_args.kwargs["argumentos"],
            ['Lista "personal"'],
        )


if __name__ == "__main__":
    unittest.main()
