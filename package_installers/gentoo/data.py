# reading the data files that describe a portage config
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
    except OSError as error:
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


# None when the host has no file, an empty file is a valid host
def host(schema: Path, host: str) -> dict[str, Any] | None:
    path: Path = schema / "hosts" / f"{host}.toml"
    return load(path) if path.is_file() else None
