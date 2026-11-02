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


def entries(path: Path) -> list[Path]:
    if not path.is_dir():
        return []
    return [entry for entry in sorted(path.iterdir()) if entry.is_file()]


def files(path: Path) -> list[Path]:
    return [entry for entry in entries(path) if entry.suffix == ".toml"]


def name(path: Path) -> str:
    return path.stem


def host(schema: Path, hostname: str | None) -> tuple[str, dict[str, Any]]:
    host: str = hostname or socket.gethostname().split(".")[0]
    path: Path = schema / "hosts" / f"{host}.toml"
    if not path.is_file():
        if hostname:
            sys.exit(f"{path}: no such host file")
        # an unknown hostname still renders the shared sets
        print(f"warning: {path}: no such host file", file=sys.stderr)
        return host, {}
    doc: dict[str, Any] = load(path)
    return host, doc
