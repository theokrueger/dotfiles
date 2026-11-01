# what portage expects to find in /etc/portage and world_sets

from collections.abc import Mapping
from pathlib import Path

from data import read

PORTAGE: Path = Path("/etc/portage")
WORLD_SETS: Path = Path("/var/lib/portage/world_sets")

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

# directorys that can be modified
SCAN_DIRS: list[str] = [
    "make.conf",
    "env",
    "sets",
    "repos.conf",
    "binrepos.conf",
] + PACKAGE_KEYS


# not-quite-TOML for repos.conf and binrepos.conf
def ini(sections: Mapping[str, Mapping[str, object]]) -> list[str]:
    lines: list[str] = []
    for name, options in sections.items():
        lines.append(f"[{name}]")
        lines.extend(f"{key} = {value}" for key, value in options.items())
        lines.append("")
    return lines


# every file under owned folder
def scanned() -> list[str]:
    dirs: list[str] = list(SCAN_DIRS) + [
        f"profile/{path.name}"
        for path in (PORTAGE / "profile").glob("*")
        if path.is_dir()
    ]
    return [
        f"{rel_dir}/{entry.name}"
        for rel_dir in dirs
        if (PORTAGE / rel_dir).is_dir()
        for entry in sorted((PORTAGE / rel_dir).iterdir())
        if entry.is_file()
    ]


# is file managed already
def generated(path: Path) -> bool:
    return read(path).startswith(MARKER_PREFIX)


# include sets as in world sets
def world_entries(names: set[str]) -> list[str]:
    entries: list[str] = []
    for entry in read(WORLD_SETS).split():
        if entry.startswith("@"):
            if entry[1:] in names:
                continue
            # keep unowned sets there
            if generated(PORTAGE / "sets" / entry[1:]):
                continue
        entries.append(entry)
    entries.extend(f"@{name}" for name in sorted(names))
    return entries
