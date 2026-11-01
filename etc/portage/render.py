#!/usr/bin/env python3
# render the data into portage configurations

import argparse
import os
import sys
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any

import data
import portage
from macros import AT_MACROS

SET_KEYS: set[str] = {"install", *portage.PACKAGE_KEYS}
ENV_KEYS: set[str] = {"env", "packages"}
# host keys, sets keys plus disable and make.conf
HOST_TYPES: dict[str, type] = {
    "disable": list,
    "make.conf": dict,
    **dict.fromkeys(SET_KEYS, list),
}
HOST_KEYS: set[str] = set(HOST_TYPES)


def report(label: str, subject: str) -> None:
    print(f"{label:<9} {subject}")


def check_keys(source: str, doc: Mapping[str, Any], known: set[str]) -> None:
    for key in doc:
        if key not in known:
            print(f"warning: {source}: unknown key {key!r}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Render the Portage data files into /etc/portage and world_sets."
    )
    parser.add_argument(
        "--schema",
        default=os.path.dirname(os.path.abspath(__file__)),
        help="data directory",
    )
    parser.add_argument(
        "--host",
        help="hostname",
    )
    parser.add_argument("--check", action="store_true", help="print actions")
    args: argparse.Namespace = parser.parse_args()

    schema: Path = Path(args.schema)
    written: set[str] = set()

    host_doc: dict[str, Any]
    host, host_doc = data.host(schema, args.host)
    print(host)
    check_keys(f"hosts/{host}.toml", host_doc, HOST_KEYS)
    for key, value in host_doc.items():
        wanted: type | None = HOST_TYPES.get(key)
        if wanted and not isinstance(value, wanted):
            sys.exit(f"hosts/{host}.toml: {key} must be a {wanted.__name__}")
    disabled: set[str] = set(host_doc.get("disable", []))

    # write file
    def emit(rel: str, lines: Iterable[str], source: str) -> None:
        written.add(rel)
        path: Path = portage.PORTAGE / rel
        text: str = (
            portage.MARKER.format(source)
            + "\n"
            + "".join(f"{line}\n" for line in lines)
        )

        # @macro@
        for token, value in AT_MACROS.items():
            if token in text:
                text = text.replace(token, value())

        # maybe write
        exists: bool = path.is_file()
        if exists and data.read(path) == text:
            return

        action: str = "update" if exists else "create"
        report(action, rel)

        if not args.check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")

    # make.conf/
    for path in data.files(schema / "make.conf"):
        doc: dict[str, Any] = data.load(path)
        source: str = f"make.conf/{data.name(path)}"
        emit(source, [f"{key}={value}" for key, value in doc.items()], source)

    # repos.conf/ and binrepos.conf/
    repos: dict[str, dict[str, Any]] = {
        data.name(path): data.load(path) for path in data.files(schema / "repos.conf")
    }
    for name, section in repos.items():
        emit(
            f"repos.conf/{name}.conf",
            portage.ini({name: section}),
            f"repos.conf/{name}",
        )
    for path in data.files(schema / "binrepos.conf"):
        source = f"binrepos.conf/{data.name(path)}"
        emit(f"{source}.conf", portage.ini({data.name(path): data.load(path)}), source)

    # env/ and package.env/
    for path in data.files(schema / "env"):
        doc = data.load(path)
        name = data.name(path)
        source = f"env/{name}"
        check_keys(source, doc, ENV_KEYS)
        if doc.get("env"):
            emit(f"env/{name}", doc["env"], source)
        if doc.get("packages"):
            emit(
                f"package.env/{name}",
                [f"{atom} {name}" for atom in doc["packages"]],
                source,
            )

    # sets/ and package.use/ and package.accept_keywords/
    names: set[str] = {data.name(path) for path in data.files(schema / "sets")}
    for name in sorted(disabled - names):
        print(f"note: {host} disables unknown set {name}")
    for path in data.files(schema / "sets"):
        name = data.name(path)
        if name in disabled:
            continue
        doc = data.load(path)
        source = f"sets/{name}"
        check_keys(source, doc, SET_KEYS)
        if doc.get("install"):
            emit(f"sets/{name}", doc["install"], source)
        for key in portage.PACKAGE_KEYS:
            if doc.get(key):
                emit(f"{key}/{name}", doc[key], source)

    # hosts/ and sets/ and package.*/ and make.conf/
    host_entries: dict[str, list[str]] = {
        key: host_doc[key] for key in portage.PACKAGE_KEYS if host_doc.get(key)
    }
    host_make: dict[str, Any] = host_doc.get("make.conf") or {}
    if host_doc.get("install") or host_entries or host_make:
        if host in names:
            sys.exit(f"{schema}/hosts/{host}.toml: a set named {host} already exists")
        source = f"hosts/{host}.toml"
        if host_doc.get("install"):
            emit(f"sets/{host}", host_doc["install"], source)
        for key, lines in host_entries.items():
            emit(f"{key}/{host}", lines, source)
        if host_make:
            emit(
                f"make.conf/50-{host}",
                [f"{key}={value}" for key, value in host_make.items()],
                source,
            )

    # world_sets
    sets: set[str] = {rel.split("/")[1] for rel in written if rel.startswith("sets/")}
    world: str = "\n".join(portage.world_entries(sets))
    world_data: str = f"{world}\n" if world else ""
    if data.read(portage.WORLD_SETS) != world_data:
        report("update", str(portage.WORLD_SETS))
        for entry in world_data.split():
            report("", entry)
        if not args.check:
            portage.WORLD_SETS.parent.mkdir(parents=True, exist_ok=True)
            portage.WORLD_SETS.write_text(world_data, encoding="utf-8")

    # prune generated files from previous config
    strays: list[str] = []
    for rel in portage.scanned():
        if rel in written:
            continue
        if not portage.generated(portage.PORTAGE / rel):
            strays.append(rel)
            continue
        report("prune", rel)
        if not args.check:
            (portage.PORTAGE / rel).unlink()

    # report
    if strays:
        print(f"{len(strays)} unmanaged file(s) left alone:")
        for rel in strays:
            report("", str(portage.PORTAGE / rel))


if __name__ == "__main__":
    sys.exit(main())
