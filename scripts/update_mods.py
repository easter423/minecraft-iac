#!/usr/bin/env python3
"""Utility to generate mods.yml from modrinth slugs defined in mods_source.yml."""
import argparse
import hashlib
import sys
from pathlib import Path
import yaml
import requests

DEFAULT_SOURCE = Path('ansible/vars/mods_source.yml')
DEFAULT_OUTPUT = Path('ansible/vars/mods.yml')
VERSIONS_FILE = Path('ansible/vars/versions.yml')


def load_game_version():
    if VERSIONS_FILE.exists():
        with open(VERSIONS_FILE, 'r') as f:
            data = yaml.safe_load(f)
            return data.get('afabric_mc_version')
    return None


def fetch_latest(slug: str, game_version: str, loader: str = 'fabric'):
    url = f'https://api.modrinth.com/v2/project/{slug}/version'
    params = {
        'loaders': f'["{loader}"]',
        'game_versions': f'["{game_version}"]',
    }
    resp = requests.get(url, params=params, timeout=30)
    resp.raise_for_status()
    versions = resp.json()
    if not versions:
        raise RuntimeError(f'No version for {slug} ({game_version}/{loader})')
    version = versions[0]
    file = version['files'][0]
    file_url = file['url']
    filename = file['filename']
    file_data = requests.get(file_url, timeout=30).content
    checksum = hashlib.sha256(file_data).hexdigest()
    return {
        'name': filename,
        'url': file_url,
        'checksum': f'sha256:{checksum}',
    }


def main():
    parser = argparse.ArgumentParser(description='Update mods.yml from source list')
    parser.add_argument('-s', '--source', type=Path, default=DEFAULT_SOURCE)
    parser.add_argument('-o', '--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('-g', '--game-version', default=None)
    parser.add_argument('-l', '--loader', default='fabric')
    args = parser.parse_args()

    game_version = args.game_version or load_game_version()
    if not game_version:
        print('Minecraft version not specified and could not be read', file=sys.stderr)
        sys.exit(1)

    with open(args.source, 'r') as f:
        source = yaml.safe_load(f)

    mods = []
    for entry in source.get('mods', []):
        slug = entry['slug']
        try:
            mod = fetch_latest(slug, game_version, args.loader)
        except Exception as e:
            print(f'Failed to fetch {slug}: {e}', file=sys.stderr)
            continue
        mods.append(mod)

    with open(args.output, 'w') as f:
        yaml.dump({'fabric_mods': mods}, f, allow_unicode=True)
    print(f'Wrote {args.output} with {len(mods)} mods.')


if __name__ == '__main__':
    main()
