import hashlib
import json
import sys
from pathlib import Path

import requests
import typer
import yaml

APP = typer.Typer(help="Minecraft mod manager using Modrinth API")

REPO_ROOT = Path(__file__).resolve().parents[1]
MODS_FILE = REPO_ROOT / "ansible" / "vars" / "mods.yml"
VERSIONS_FILE = REPO_ROOT / "ansible" / "vars" / "versions.yml"


def load_yaml(path: Path):
    if path.exists():
        with path.open("r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    return {}


def save_yaml(path: Path, data: dict):
    with path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, allow_unicode=True, sort_keys=False)


def compute_sha256(url: str) -> str:
    response = requests.get(url, stream=True, timeout=30)
    response.raise_for_status()
    digest = hashlib.sha256()
    for chunk in response.iter_content(chunk_size=8192):
        digest.update(chunk)
    return digest.hexdigest()


def get_project(slug: str) -> dict:
    resp = requests.get(f"https://api.modrinth.com/v2/project/{slug}", timeout=10)
    if resp.status_code != 200:
        typer.echo(f"Project {slug} not found", err=True)
        raise typer.Exit(1)
    return resp.json()


def get_latest_version(slug: str, mc_version: str, loader: str) -> dict:
    url = (
        f"https://api.modrinth.com/v2/project/{slug}/version"
        f"?loaders=%5B%22{loader}%22%5D&game_versions=%5B%22{mc_version}%22%5D"
    )
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
    versions = resp.json()
    if not versions:
        typer.echo("No version found", err=True)
        raise typer.Exit(1)
    return versions[0]


@APP.command()
def add(slug: str, mc_version: str = typer.Option(None), loader: str = "fabric"):
    """Add or update a mod from Modrinth."""
    versions_data = load_yaml(VERSIONS_FILE)
    if mc_version is None:
        mc_version = versions_data.get("afabric_mc_version")
    if mc_version is None:
        typer.echo("Minecraft version not specified and not found in versions.yml", err=True)
        raise typer.Exit(1)
    project = get_project(slug)
    version = get_latest_version(slug, mc_version, loader)
    file_info = version["files"][0]
    checksum = compute_sha256(file_info["url"])

    mods_data = load_yaml(MODS_FILE)
    mods = mods_data.get("fabric_mods", [])
    existing = next((m for m in mods if m.get("slug") == slug or m.get("name") == file_info["filename"]), None)
    item = {
        "name": file_info["filename"],
        "url": file_info["url"],
        "checksum": f"sha256:{checksum}",
        "slug": slug,
        "version": version["version_number"],
        "categories": project.get("categories", []),
    }
    if existing:
        mods[mods.index(existing)] = item
        typer.echo(f"Updated {slug} -> {file_info['filename']}")
    else:
        mods.append(item)
        typer.echo(f"Added {slug} -> {file_info['filename']}")
    mods_data["fabric_mods"] = mods
    save_yaml(MODS_FILE, mods_data)


@APP.command()
def list_mods():
    """List mods in table format."""
    mods_data = load_yaml(MODS_FILE)
    mods = []

    for mod in mods_data.get("fabric_mods", []):
        name = mod["name"]
        slug = mod.get("slug", name)
        ver = mod.get("version", name)
        cats = ", ".join(mod.get("categories", []))
        checksum = mod.get("checksum", name).split(":")[-1][:6] if "checksum" in mod else "N/A"
        mods.append({"slug": slug, "categories": cats, "version": ver, "checksum": checksum})

    mods_sorted = sorted(
        mods,
        key=lambda m: (m["slug"].lower(), m["slug"]),
    )

    # Print table header
    header = f"| {'Mod Name':<25} | {'Categories':<40} | {'Version':<40} | {'Checksum':<8} |"
    line = f"|{'-' * 27}|{'-' * 42}|{'-' * 42}|{'-' * 10}|"
    print(line)
    print(header)
    print(line)

    # Print table rows
    for mod in mods_sorted:
        print(
            f"| {mod['slug']:<25} | {mod['categories']:<40} | {mod['version']:<40} | {mod['checksum']:<8} |"
        )
    print(line)


if __name__ == "__main__":
    APP()
