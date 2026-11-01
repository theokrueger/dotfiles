# reading the data files that describe a portage config
import socket
import sys
import tomllib
from pathlib import Path
from typing import Any


def load(path: Path) -> Any:
    try:
        with path.open("rb") as handle:
            return tomllib.load(handle)
    except tomllib.TOMLDecodeError as error:
        sys.exit(f"{path}: {error}")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def files(path: Path) -> list[Path]:
    if not path.is_dir():
        return []
    return [
        entry
        for entry in sorted(path.iterdir())
        if entry.is_file() and entry.suffix == ".toml"
    ]


def name(path: Path) -> str:
    return path.stem


def host(schema: Path, name: str | None) -> tuple[str, dict[str, Any]]:
    host: str = name or socket.gethostname().split(".")[0]
    path: Path = schema / "hosts" / f"{host}.toml"
    if name and not path.is_file():
        sys.exit(f"{path}: no such host file")
    doc: dict[str, Any] = load(path) if path.is_file() else {}
    return host, doc
