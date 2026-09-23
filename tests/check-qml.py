#!/usr/bin/env python3
"""Load real Omarchy components in an isolated Quickshell test configuration."""
import os
from pathlib import Path
import subprocess
import tempfile

source = Path(__file__).resolve().parents[1]
shell = Path(os.environ.get('OMARCHY_PATH', '/usr/share/omarchy')) / 'shell'
with tempfile.TemporaryDirectory(prefix='mixtape-qml-') as directory:
    harness = Path(directory)
    for component in ('Commons', 'Ui', 'services'):
        (harness / component).symlink_to(shell / component)
    (harness / 'Mixtape').symlink_to(source)
    mixes = harness / 'mixes'
    mixes.mkdir()
    (mixes / 'Test Mix.m3u').write_text('#EXTM3U\n')
    qml = (source / 'tests/qml/shell.qml').read_text().replace('import "../../" as Mixtape', 'import "Mixtape" as Mixtape')
    (harness / 'shell.qml').write_text(qml)
    env = dict(os.environ)
    env.update({'MIXTAPE_RUNTIME_DIR': str(harness / 'runtime'),
                'MIXTAPE_PLAYLIST_DIR': str(mixes),
                'MIXTAPE_MUSIC_DIR': str(harness / 'music')})
    result = subprocess.run(['quickshell', '-p', str(harness), '--no-color'],
                            capture_output=True, text=True, timeout=15, env=env)
    output = result.stdout + result.stderr
    print(output, end='')
    if result.returncode or 'PASS: reel' not in output or 'ReferenceError' in output or 'TypeError' in output:
        raise SystemExit(1)
