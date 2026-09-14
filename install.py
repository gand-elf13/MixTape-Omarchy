#!/usr/bin/env python3
"""Link this checkout into Omarchy and add its widget, preserving other settings."""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--section', choices=['left', 'center', 'right'], default='right')
args = parser.parse_args()
source = Path(__file__).resolve().parent
config_dir = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'omarchy'
config_file = config_dir / 'shell.json'
config = json.loads(config_file.read_text())
layout = config['bar']['layout']
plugin_id = 'local.mixtape'
link = config_dir / 'plugins' / plugin_id
if link.exists() or link.is_symlink():
    if link.resolve() != source:
        raise SystemExit(f'Refusing to replace existing plugin at {link}')
else:
    link.parent.mkdir(parents=True, exist_ok=True)
    link.symlink_to(source, target_is_directory=True)
entry = {'id': plugin_id}
for section in ('left', 'center', 'right'):
    for existing in layout.get(section, []):
        if existing.get('id') == plugin_id:
            entry = existing
    layout[section] = [item for item in layout.get(section, []) if item.get('id') != plugin_id]
layout[args.section].append(entry)
backup = config_file.with_name('shell.json.mixtape-backup-' + datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
shutil.copy2(config_file, backup)
fd, temporary = tempfile.mkstemp(prefix='.shell-mixtape-', dir=config_dir)
try:
    with os.fdopen(fd, 'w') as output:
        output.write(json.dumps(config, indent=2) + '\n')
    os.chmod(temporary, config_file.stat().st_mode & 0o777)
    os.replace(temporary, config_file)
finally:
    Path(temporary).unlink(missing_ok=True)
print(f'Installed Mixtape in the {args.section} section.\nBackup: {backup}\nThe shell should hot-reload the widget.')
