#!/usr/bin/env python3
"""Check device packaging and exported FFI symbols before publishing an IPA."""
from pathlib import Path
import plistlib
import subprocess
import sys

app = Path(sys.argv[1]).resolve()
with (app / 'Info.plist').open('rb') as stream:
    info = plistlib.load(stream)
if 'iPhoneOS' not in info.get('CFBundleSupportedPlatforms', []):
    raise SystemExit('Refusing to package a simulator app as a device IPA.')
executable = app / info['CFBundleExecutable']
architectures = subprocess.check_output(['lipo', '-archs', str(executable)], text=True)
if 'arm64' not in architectures.split():
    raise SystemExit('The app is missing its arm64 device executable.')

native = app / 'Frameworks/flutter_js.framework/flutter_js'
symbols = subprocess.check_output(['nm', '-gU', str(native if native.exists() else executable)], text=True)
for symbol in ('jsNewRuntime', 'jsNewContext', 'jsEval', 'jsFreeRuntime',
               'jsSetMemoryLimit', 'tetoEnsureQuickJSLinked'):
    if not any(line.split()[-1:] == ['_' + symbol] for line in symbols.splitlines()):
        raise SystemExit('Missing release QuickJS symbol: ' + symbol)
if not any(p.name.lower() == 'mpv.framework' for p in (app / 'Frameworks').glob('*.framework')):
    raise SystemExit('The app is missing the MPV framework.')
print('Verified device architecture, MPV framework and QuickJS exports.')
