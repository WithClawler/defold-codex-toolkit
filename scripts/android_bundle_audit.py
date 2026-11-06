#!/usr/bin/env python3
"""Inspect Android ELF debug sections and ZIP sizes without external tools."""
import argparse
import json
import struct
import zipfile


def sections(data):
    if data[:4] != b'\x7fELF' or data[4] not in (1, 2) or data[5] not in (1, 2):
        raise ValueError('invalid ELF header')
    endian = '<' if data[5] == 1 else '>'
    wide = data[4] == 2
    offset = struct.unpack_from(endian + ('Q' if wide else 'I'), data, 40 if wide else 32)[0]
    size, count, names_index = struct.unpack_from(endian + 'HHH', data, 58 if wide else 46)
    fmt = endian + ('IIQQQQIIQQ' if wide else 'IIIIIIIIII')
    if size < struct.calcsize(fmt) or not count or names_index >= count:
        raise ValueError('invalid or unsupported ELF section table')
    headers = [struct.unpack_from(fmt, data, offset + i * size) for i in range(count)]
    table = headers[names_index]
    names = data[table[4]:table[4] + table[5]]
    result = {}
    for header in headers:
        if header[0] >= len(names):
            raise ValueError('invalid ELF section name')
        name = names[header[0]:].split(b'\0', 1)[0].decode('ascii')
        result[name] = header[5]
    return result


def audit(path):
    with zipfile.ZipFile(path) as archive:
        libraries = []
        for item in archive.infolist():
            if '/lib/' in '/' + item.filename and item.filename.endswith('.so'):
                found = sections(archive.read(item))
                debug = {name: size for name, size in found.items()
                         if name.startswith(('.debug', '.zdebug')) and size}
                libraries.append(dict(path=item.filename, bytes=item.file_size,
                                      zip_bytes=item.compress_size, debug_sections=debug))
        if not libraries:
            raise ValueError('no native libraries found')
        return dict(libraries=libraries, zip_bytes=sum(i.compress_size for i in archive.infolist()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle')
    parser.add_argument('--require-stripped', action='store_true')
    args = parser.parse_args()
    report = audit(args.bundle)
    print(json.dumps(report, indent=2))
    if args.require_stripped and any(lib['debug_sections'] for lib in report['libraries']):
        parser.exit(1, 'Release contains native debug sections\n')


if __name__ == '__main__':
    main()
