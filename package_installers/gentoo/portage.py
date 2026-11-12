# what portage expects to find in /etc/portage and world_sets

from collections.abc import Iterable, Mapping
from pathlib import Path

from data import read

PORTAGE: Path = Path("/etc/portage")
WORLD_SETS: Path = Path("/var/lib/portage/world_sets")
# installkernel reads kernel config snippets from here
KERNEL: Path = Path("/etc/kernel")
KERNEL_DIRS: list[str] = ["config.d"]

MARKER_PREFIX: str = "# GENERATED FROM:"
MARKER: str = MARKER_PREFIX + " {}"

PACKAGE_KEYS: list[str] = [
    "package.use",
    "package.accept_keywords",
    "package.mask",
    "package.unmask",
    "package.license",
    "package.env",
]

# directories the renderer owns
SCAN_DIRS: list[str] = [
    "make.conf",
    "env",
    "sets",
    "repos.conf",
    "binrepos.conf",
] + PACKAGE_KEYS


# toml value -> config text, bools lowercase and arrays space separated
def scalar(raw: object) -> str:
    if isinstance(raw, bool):
        return "true" if raw else "false"
    if isinstance(raw, (list, tuple)):
        return " ".join(scalar(entry) for entry in raw)
    return str(raw)


# not-quite-TOML for repos.conf and binrepos.conf
def ini(sections: Mapping[str, Mapping[str, object]]) -> list[str]:
    lines: list[str] = []
    for name, options in sections.items():
        lines.append(f"[{name}]")
        lines.extend(f"{key} = {scalar(entry)}" for key, entry in options.items())
        lines.append("")
    return lines


# toml table -> make.conf lines
def lines(doc: Mapping[str, object]) -> list[str]:
    return [f"{key}={scalar(value)}" for key, value in doc.items()]


# every file under owned folder, nested ones included
def scanned(root: Path, dirs: Iterable[str]) -> list[str]:
    return [
        path.relative_to(root).as_posix()
        for rel_dir in dirs
        if (root / rel_dir).is_dir()
        for path in sorted((root / rel_dir).rglob("*"))
        if path.is_file() and not path.is_symlink()
    ]


# is file managed already
def generated(path: Path) -> bool:
    return read(path).startswith(MARKER_PREFIX)


# include sets in world_sets
def world_entries(names: set[str]) -> list[str]:
    entries: list[str] = []
    for entry in read(WORLD_SETS).split():
        if entry.startswith("@"):
            path: Path = PORTAGE / "sets" / entry[1:]
            # ours: planned, generated before, or gone
            if entry[1:] in names or generated(path) or not path.is_file():
                continue
        entries.append(entry)
    entries.extend(f"@{name}" for name in sorted(names))
    return entries
