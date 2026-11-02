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

SET_KEYS: set[str] = {"install", "kernel.config", *portage.PACKAGE_KEYS}
ENV_KEYS: set[str] = {"env", "packages"}
SET_TYPES: dict[str, type] = dict.fromkeys(SET_KEYS, list)
ENV_TYPES: dict[str, type] = dict.fromkeys(ENV_KEYS, list)
# sets merge their kernel.config lines into one snippet, numbered last
SETS_CONFIG: str = "99-sets.config"
# host keys, sets keys plus disable and make.conf, kernel.config is sets only
HOST_TYPES: dict[str, type] = {
    "disable": list,
    "kernel.config.disable": list,
    "make.conf": dict,
    **dict.fromkeys(SET_KEYS - {"kernel.config"}, list),
}
HOST_KEYS: set[str] = set(HOST_TYPES)


def report(label: str, subject: str) -> None:
    print(f"{label:<9} {subject}")


def check_keys(source: str, doc: Mapping[str, Any], known: set[str]) -> None:
    for key in doc:
        if key not in known:
            print(f"warning: {source}: unknown key {key!r}", file=sys.stderr)


# values have to have the shape the renderer expects
def check_types(source: str, doc: Mapping[str, Any], types: Mapping[str, type]) -> None:
    for key, value in doc.items():
        wanted: type | None = types.get(key)
        if wanted and not isinstance(value, wanted):
            sys.exit(f"{source}: {key} must be a {wanted.__name__}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Render the data files into /etc/portage and /etc/kernel."
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
    # trees the renderer owns, every dir is relative to its root
    owned: list[tuple[Path, list[str]]] = [
        (portage.PORTAGE, portage.SCAN_DIRS),
        (portage.KERNEL, portage.KERNEL_DIRS),
    ]
    written: set[Path] = set()

    host, host_doc = data.host(schema, args.host)
    print(host)
    check_keys(f"hosts/{host}.toml", host_doc, HOST_KEYS)
    check_types(f"hosts/{host}.toml", host_doc, HOST_TYPES)
    disabled: set[str] = set(host_doc.get("disable", []))
    kernel_disabled: set[str] = set(host_doc.get("kernel.config.disable", []))

    # write file
    def emit(root: Path, rel: str, lines: Iterable[str], source: str) -> None:
        path: Path = root / rel
        written.add(path)
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
        emit(
            portage.PORTAGE,
            source,
            [f"{key}={portage.scalar(value)}" for key, value in doc.items()],
            source,
        )

    # repos.conf/ and binrepos.conf/
    for path in data.files(schema / "repos.conf"):
        name: str = data.name(path)
        emit(
            portage.PORTAGE,
            f"repos.conf/{name}.conf",
            portage.ini({name: data.load(path)}),
            f"repos.conf/{name}",
        )
    for path in data.files(schema / "binrepos.conf"):
        source = f"binrepos.conf/{data.name(path)}"
        emit(
            portage.PORTAGE,
            f"{source}.conf",
            portage.ini({data.name(path): data.load(path)}),
            source,
        )

    # env/ and package.env/
    for path in data.files(schema / "env"):
        doc = data.load(path)
        name = data.name(path)
        source = f"env/{name}"
        check_keys(source, doc, ENV_KEYS)
        check_types(source, doc, ENV_TYPES)
        if doc.get("packages") and not doc.get("env"):
            sys.exit(f"{source}: packages needs env")
        if doc.get("env"):
            emit(portage.PORTAGE, f"env/{name}", doc["env"], source)
        if doc.get("packages"):
            emit(
                portage.PORTAGE,
                f"package.env/{name}",
                [f"{atom} {name}" for atom in doc["packages"]],
                source,
            )

    # sets/ and package.use/ and package.accept_keywords/
    names: set[str] = {data.name(path) for path in data.files(schema / "sets")}
    for name in sorted(disabled - names):
        print(f"note: {host} disables unknown set {name}")
    kernel_lines: list[str] = []
    for path in data.files(schema / "sets"):
        name = data.name(path)
        if name in disabled:
            continue
        doc = data.load(path)
        source = f"sets/{name}"
        check_keys(source, doc, SET_KEYS)
        check_types(source, doc, SET_TYPES)
        if doc.get("install"):
            emit(portage.PORTAGE, f"sets/{name}", doc["install"], source)
        for key in portage.PACKAGE_KEYS:
            if doc.get(key):
                emit(portage.PORTAGE, f"{key}/{name}", doc[key], source)
        if doc.get("kernel.config"):
            kernel_lines.append(f"# sets/{name}")
            kernel_lines.extend(doc["kernel.config"])

    # hosts/ and sets/ and package.*/ and make.conf/
    host_entries: dict[str, list[str]] = {
        key: host_doc[key] for key in portage.PACKAGE_KEYS if host_doc.get(key)
    }
    host_install: list[str] = host_doc.get("install") or []
    host_make: dict[str, Any] = host_doc.get("make.conf") or {}
    if host_install or host_entries or host_make:
        source = f"hosts/{host}.toml"
        host_make_conf: str = f"make.conf/50-{host}"
        if host in names:
            sys.exit(f"{schema}/hosts/{host}.toml: a set named {host} already exists")
        if host_make and portage.PORTAGE / host_make_conf in written:
            sys.exit(f"{schema}/hosts/{host}.toml: make.conf/50-{host}.toml exists")
        if host_install:
            emit(portage.PORTAGE, f"sets/{host}", host_install, source)
        for key, lines in host_entries.items():
            emit(portage.PORTAGE, f"{key}/{host}", lines, source)
        if host_make:
            emit(
                portage.PORTAGE,
                host_make_conf,
                [f"{key}={portage.scalar(value)}" for key, value in host_make.items()],
                source,
            )

    # kernel.config.d/ -> kernel/config.d/
    kernel_names: set[str] = {
        path.name for path in data.entries(schema / "kernel.config.d")
    }
    for name in sorted(kernel_disabled - kernel_names - {SETS_CONFIG}):
        print(f"note: {host} disables unknown kernel config {name}")
    if SETS_CONFIG in kernel_names:
        sys.exit(f"{schema}/kernel.config.d/{SETS_CONFIG}: reserved for the sets")
    for path in data.entries(schema / "kernel.config.d"):
        if path.name in kernel_disabled:
            continue
        source = f"kernel.config.d/{path.name}"
        emit(
            portage.KERNEL,
            f"config.d/{path.name}",
            data.read(path).splitlines(),
            source,
        )
    if kernel_lines and SETS_CONFIG not in kernel_disabled:
        emit(
            portage.KERNEL,
            f"config.d/{SETS_CONFIG}",
            kernel_lines,
            "sets/*.config",
        )

    # world_sets
    sets: set[str] = {
        path.name for path in written if path.parent == portage.PORTAGE / "sets"
    }
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
    for root, dirs in owned:
        for rel in portage.scanned(root, dirs):
            path = root / rel
            if path in written:
                continue
            if not portage.generated(path):
                strays.append(str(path))
                continue
            report("prune", rel)
            if not args.check:
                path.unlink()

    # report
    if strays:
        print(f"{len(strays)} unmanaged file(s) left alone:")
        for stray in strays:
            report("", stray)


if __name__ == "__main__":
    main()
