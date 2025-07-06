#!/usr/bin/env python3
"""Simple GUI to manage Minecraft mods list using Modrinth API."""

from __future__ import annotations

import hashlib
import os
import tkinter as tk
from tkinter import messagebox, simpledialog
from typing import Dict

import requests
import yaml

# File paths relative to this script
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODS_FILE = os.path.join(REPO_ROOT, "ansible", "vars", "mods.yml")
VERSIONS_FILE = os.path.join(REPO_ROOT, "ansible", "vars", "versions.yml")


def load_yaml(path: str) -> Dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def save_yaml(path: str, data: Dict) -> None:
    with open(path, "w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, allow_unicode=True, sort_keys=False)


def get_mc_version() -> str:
    versions = load_yaml(VERSIONS_FILE)
    return versions.get("afabric_mc_version", "")


def fetch_modrinth_latest(slug: str, mc_version: str) -> Dict[str, str]:
    params = {
        "loaders": ["fabric"],
        "game_versions": [mc_version],
        "limit": 1,
    }
    resp = requests.get(
        f"https://api.modrinth.com/v2/project/{slug}/version",
        params=params,
        timeout=10,
    )
    resp.raise_for_status()
    versions = resp.json()
    if not versions:
        raise RuntimeError("No compatible version found")
    file_info = versions[0]["files"][0]
    url = file_info["url"]
    filename = file_info["filename"]
    data = requests.get(url, timeout=10).content
    checksum = hashlib.sha256(data).hexdigest()
    return {"name": filename, "url": url, "checksum": f"sha256:{checksum}"}


def refresh_list(listbox: tk.Listbox, mods: Dict) -> None:
    listbox.delete(0, tk.END)
    for mod in mods.get("fabric_mods", []):
        listbox.insert(tk.END, mod["name"])


def add_mod(root: tk.Tk, listbox: tk.Listbox, mods: Dict) -> None:
    slug = simpledialog.askstring(
        "Add Mod",
        "Modrinth slug or project ID:",
        parent=root,
    )
    if not slug:
        return
    try:
        mc_ver = get_mc_version()
        entry = fetch_modrinth_latest(slug, mc_ver)
    except Exception as exc:  # noqa: BLE001
        messagebox.showerror("Error", str(exc), parent=root)
        return
    mods.setdefault("fabric_mods", []).append(entry)
    save_yaml(MODS_FILE, mods)
    refresh_list(listbox, mods)


def remove_mod(root: tk.Tk, listbox: tk.Listbox, mods: Dict) -> None:
    sel = listbox.curselection()
    if not sel:
        return
    idx = sel[0]
    confirm = messagebox.askyesno(
        "Remove",
        f"Delete {mods['fabric_mods'][idx]['name']}?",
        parent=root,
    )
    if confirm:
        mods["fabric_mods"].pop(idx)
        save_yaml(MODS_FILE, mods)
        refresh_list(listbox, mods)


def main() -> None:
    mods = load_yaml(MODS_FILE)
    root = tk.Tk()
    root.title("Minecraft Mod Manager")
    listbox = tk.Listbox(root, width=80)
    listbox.pack(fill=tk.BOTH, expand=True)
    refresh_list(listbox, mods)

    btn_frame = tk.Frame(root)
    btn_frame.pack(fill=tk.X)
    tk.Button(
        btn_frame,
        text="Add",
        command=lambda: add_mod(root, listbox, mods),
    ).pack(side=tk.LEFT)
    tk.Button(
        btn_frame,
        text="Remove",
        command=lambda: remove_mod(root, listbox, mods),
    ).pack(side=tk.LEFT)

    root.mainloop()


if __name__ == "__main__":
    main()
