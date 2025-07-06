#!/usr/bin/env python3
"""Manage Minecraft mods defined in YAML files.

This script fetches mod data from Modrinth and generates the Ansible
``mods.yml`` list with download URLs and SHA256 checksums.
Optionally a minimal GUI using Streamlit can display the current list.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
from typing import Any, Dict, List

import requests
import yaml

BASE_URL = "https://api.modrinth.com/v2"
EXTENDED_PATH = Path("ansible/vars/mods_ext.yml")
OUTPUT_PATH = Path("ansible/vars/mods.yml")
VERSION_PATH = Path("ansible/vars/versions.yml")


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def save_yaml(path: Path, data: Any) -> None:
    with path.open("w", encoding="utf-8") as f:
        yaml.dump(data, f, sort_keys=False)


def fetch_modrinth_version(slug: str, game_version: str) -> Dict[str, Any]:
    """Return download info for the latest version of a Modrinth project."""
    project = requests.get(f"{BASE_URL}/project/{slug}").json()
    project_id = project["id"]
    params = {
        "loaders": ["fabric"],
        "game_versions": [game_version],
        "limit": 1,
    }
    versions = requests.get(
        f"{BASE_URL}/project/{project_id}/version", params=params
    ).json()
    if not versions:
        raise ValueError(f"No version found for {slug} on {game_version}")
    version = versions[0]
    file_info = version["files"][0]
    return {
        "name": file_info["filename"],
        "url": file_info["url"],
    }


def sha256_from_url(url: str) -> str:
    """Download ``url`` and return ``sha256:<hexdigest>``."""
    h = hashlib.sha256()
    with requests.get(url, stream=True) as resp:
        resp.raise_for_status()
        for chunk in resp.iter_content(chunk_size=8192):
            h.update(chunk)
    return "sha256:" + h.hexdigest()


def generate_mods() -> None:
    versions = load_yaml(VERSION_PATH)
    data = load_yaml(EXTENDED_PATH)
    game_version = versions["afabric_mc_version"]
    mods: List[Dict[str, str]] = []
    for mod in data.get("mods", []):
        if mod.get("source") != "modrinth":
            continue
        info = fetch_modrinth_version(mod["slug"], game_version)
        checksum = sha256_from_url(info["url"])
        mods.append(
            {
                "name": info["name"],
                "url": info["url"],
                "checksum": checksum,
            }
        )
    save_yaml(OUTPUT_PATH, {"fabric_mods": mods})
    print(f"Wrote {OUTPUT_PATH} with {len(mods)} entries")


def list_mods() -> None:
    data = load_yaml(EXTENDED_PATH)
    for mod in data.get("mods", []):
        cat = mod.get("category", "unknown")
        print(f"{mod['slug']}: {cat}")


def run_gui() -> None:
    import streamlit as st

    data = load_yaml(EXTENDED_PATH)
    st.title("Minecraft Mod Manager")
    st.write("Mods defined in", EXTENDED_PATH)
    for mod in data.get("mods", []):
        st.write(f"**{mod['slug']}** - {mod.get('category', 'unknown')}")


def main(argv: List[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Manage mod list")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("generate", help="Generate mods.yml from mods_ext.yml")
    sub.add_parser("list", help="List mods with categories")
    sub.add_parser("gui", help="Launch simple web interface")
    args = parser.parse_args(argv)

    if args.cmd == "generate":
        generate_mods()
    elif args.cmd == "list":
        list_mods()
    elif args.cmd == "gui":
        run_gui()


if __name__ == "__main__":
    main()
