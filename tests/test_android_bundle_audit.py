import importlib.util
import pathlib
import struct
import tempfile
import unittest
import zipfile

path = pathlib.Path(__file__).parents[1] / 'scripts/android_bundle_audit.py'
spec = importlib.util.spec_from_file_location('audit', path)
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


def elf(debug):
    names = b'\0.shstrtab\0' + (b'.debug_info\0' if debug else b'.text\0')
    blob = bytearray(64 + 3 * 64 + len(names))
    blob[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<Q', blob, 40, 64)
    struct.pack_into('<HHH', blob, 58, 64, 3, 1)
    struct.pack_into('<IIQQQQIIQQ', blob, 128, 1, 3, 0, 0, 256, len(names), 0, 0, 1, 0)
    struct.pack_into('<IIQQQQIIQQ', blob, 192, 11, 1, 0, 0, 256, 8, 0, 0, 1, 0)
    blob[256:] = names
    return blob


class AuditTest(unittest.TestCase):
    def test_sections_and_malformed(self):
        self.assertIn('.debug_info', audit.sections(elf(True)))
        self.assertNotIn('.debug_info', audit.sections(elf(False)))
        with self.assertRaises(ValueError):
            audit.sections(b'bad')

    def test_checks_every_abi(self):
        with tempfile.TemporaryDirectory() as folder:
            path = pathlib.Path(folder) / 'app.aab'
            with zipfile.ZipFile(path, 'w') as z:
                z.writestr('base/lib/arm64-v8a/libgame.so', elf(False))
                z.writestr('base/lib/armeabi-v7a/libgame.so', elf(True))
            report = audit.audit(path)
            self.assertEqual(len(report['libraries']), 2)
            self.assertFalse(report['libraries'][0]['debug_sections'])
            self.assertTrue(report['libraries'][1]['debug_sections'])


if __name__ == '__main__':
    unittest.main()
