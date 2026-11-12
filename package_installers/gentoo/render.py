#!/usr/bin/env python3
# render the data into portage configurations

import argparse
import os
import socket
import sys
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any

import data
import portage
from macros import AT_MACROS

# every data directory a render reads
REQUIRED: list[str] = [
    "binrepos.conf",
    "env",
    "hosts",
    "kernel.config.d",
    "make.conf",
    "repos.conf",
    "sets",
]

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
# values that format into a config line
SCALARS: tuple[type, ...] = (str, bool, int, float)


def report(label: str, subject: str) -> None:
    print(f"{label:<9} {subject}")


def relative(path: Path) -> str:
    for root in (portage.PORTAGE, portage.KERNEL):
        if path.is_relative_to(root):
            return path.relative_to(root).as_posix()
    return str(path)


def check_keys(source: str, doc: Mapping[str, Any], known: set[str]) -> None:
    for key in doc:
        if key not in known:
            sys.exit(f"{source}: unknown key {key!r}")


# values have to have the shape the renderer expects
def check_types(source: str, doc: Mapping[str, Any], types: Mapping[str, type]) -> None:
    for key, value in doc.items():
        wanted: type | None = types.get(key)
        if wanted is None:
            continue
        if not isinstance(value, wanted):
            sys.exit(f"{source}: {key} must be a {wanted.__name__}")
        if wanted is list:
            for entry in value:
                if not isinstance(entry, str):
                    sys.exit(f"{source}: {key} must hold only strings")


# tables and dates have no config line
def check_values(source: str, doc: Mapping[str, Any]) -> None:
    for key, value in doc.items():
        for entry in value if isinstance(value, list) else [value]:
            if not isinstance(entry, SCALARS):
                sys.exit(f"{source}: {key} cannot hold a {type(entry).__name__}")


# rendered files and the source that claimed them, in render order
class Plan:
    def __init__(self) -> None:
        self.files: dict[Path, tuple[str, str]] = {}

    def add(self, root: Path, rel: str, lines: Iterable[str], source: str) -> None:
        path: Path = root / rel
        if path in self.files:
            sys.exit(
                f"{source} and {self.files[path][0]} both write {relative(path)}"
            )
        text: str = (
            portage.MARKER.format(source)
            + "\n"
            + "".join(f"{line}\n" for line in lines)
        )

        # @macro@
        for token, value in AT_MACROS.items():
            if token in text:
                text = text.replace(token, value())

        self.files[path] = (source, text)


# make.conf/ and repos.conf/ and binrepos.conf/
def plan_static(schema: Path, plan: Plan) -> None:
    for path in data.files(schema / "make.conf"):
        source: str = f"make.conf/{data.name(path)}"
        doc: dict[str, Any] = data.load(path)
        check_values(source, doc)
        lines = (f"{key}={portage.scalar(value)}" for key, value in doc.items())
        plan.add(portage.PORTAGE, source, lines, source)

    for path in data.files(schema / "repos.conf"):
        name: str = data.name(path)
        source = f"repos.conf/{name}"
        doc = data.load(path)
        check_values(source, doc)
        plan.add(portage.PORTAGE, f"{source}.conf", portage.ini({name: doc}), source)

    for path in data.files(schema / "binrepos.conf"):
        name = data.name(path)
        source = f"binrepos.conf/{name}"
        doc = data.load(path)
        check_values(source, doc)
        plan.add(portage.PORTAGE, f"{source}.conf", portage.ini({name: doc}), source)


# env/ and package.env/
def plan_env(schema: Path, plan: Plan) -> None:
    for path in data.files(schema / "env"):
        name: str = data.name(path)
        source: str = f"env/{name}"
        doc: dict[str, Any] = data.load(path)
        check_keys(source, doc, ENV_KEYS)
        check_types(source, doc, ENV_TYPES)
        if doc.get("packages") and not doc.get("env"):
            sys.exit(f"{source}: packages needs env")
        if doc.get("env"):
            plan.add(portage.PORTAGE, f"env/{name}", doc["env"], source)
        if doc.get("packages"):
            lines = (f"{atom} {name}" for atom in doc["packages"])
            plan.add(portage.PORTAGE, f"package.env/{name}", lines, source)


# sets/ and package.*/, returns the merged kernel.config lines
def plan_sets(
    schema: Path, host: str, disabled: set[str], names: set[str], plan: Plan
) -> list[str]:
    for name in sorted(disabled - names):
        print(f"note: {host} disables unknown set {name}")
    kernel_lines: list[str] = []
    for path in data.files(schema / "sets"):
        name = data.name(path)
        if name in disabled:
            continue
        source: str = f"sets/{name}"
        doc: dict[str, Any] = data.load(path)
        check_keys(source, doc, SET_KEYS)
        check_types(source, doc, SET_TYPES)
        if doc.get("install"):
            plan.add(portage.PORTAGE, f"sets/{name}", doc["install"], source)
        for key in portage.PACKAGE_KEYS:
            if doc.get(key):
                plan.add(portage.PORTAGE, f"{key}/{name}", doc[key], source)
        if doc.get("kernel.config"):
            kernel_lines.append(f"# sets/{name}")
            kernel_lines.extend(doc["kernel.config"])
    return kernel_lines


# hosts/ plus its own set and make.conf/
def plan_host(host: str, host_doc: Mapping[str, Any], plan: Plan) -> None:
    source: str = f"hosts/{host}.toml"
    entries: dict[str, list[str]] = {
        key: host_doc[key] for key in portage.PACKAGE_KEYS if host_doc.get(key)
    }
    install: list[str] = host_doc.get("install") or []
    make: dict[str, Any] = host_doc.get("make.conf") or {}
    check_values(source, make)
    if install:
        plan.add(portage.PORTAGE, f"sets/{host}", install, source)
    for key, lines in entries.items():
        plan.add(portage.PORTAGE, f"{key}/{host}", lines, source)
    if make:
        lines = (f"{key}={portage.scalar(value)}" for key, value in make.items())
        plan.add(portage.PORTAGE, f"make.conf/50-{host}", lines, source)


# kernel.config.d/ and the merged sets snippet
def plan_kernel(
    schema: Path, host: str, disabled: set[str], lines: list[str], plan: Plan
) -> None:
    names: set[str] = {path.name for path in data.entries(schema / "kernel.config.d")}
    for name in sorted(disabled - names - {SETS_CONFIG}):
        print(f"note: {host} disables unknown kernel config {name}")
    if SETS_CONFIG in names:
        sys.exit(f"{schema}/kernel.config.d/{SETS_CONFIG}: reserved for the sets")
    for path in data.entries(schema / "kernel.config.d"):
        if path.name in disabled:
            continue
        source: str = f"kernel.config.d/{path.name}"
        plan.add(
            portage.KERNEL,
            f"config.d/{path.name}",
            data.read(path).splitlines(),
            source,
        )
    if lines and SETS_CONFIG not in disabled:
        plan.add(portage.KERNEL, f"config.d/{SETS_CONFIG}", lines, "sets/*.config")


def apply(plan: Plan, check: bool) -> None:
    for path, (source, text) in plan.files.items():
        if path.is_dir():
            sys.exit(f"{source}: {relative(path)} is a directory")
        exists: bool = path.is_file()
        if exists and data.read(path) == text:
            continue
        report("update" if exists else "create", relative(path))
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")


def world(plan: Plan, check: bool) -> None:
    sets: set[str] = {
        path.name for path in plan.files if path.parent == portage.PORTAGE / "sets"
    }
    entries: list[str] = portage.world_entries(sets)
    text: str = "".join(f"{entry}\n" for entry in entries)
    if data.read(portage.WORLD_SETS) == text:
        return
    report("update", str(portage.WORLD_SETS))
    for entry in entries:
        report("", entry)
    if not check:
        portage.WORLD_SETS.parent.mkdir(parents=True, exist_ok=True)
        portage.WORLD_SETS.write_text(text, encoding="utf-8")


def prune(plan: Plan, check: bool) -> None:
    owned: list[tuple[Path, list[str]]] = [
        (portage.PORTAGE, portage.SCAN_DIRS),
        (portage.KERNEL, portage.KERNEL_DIRS),
    ]
    strays: list[str] = []
    for root, dirs in owned:
        for rel in portage.scanned(root, dirs):
            path = root / rel
            if path in plan.files:
                continue
            if not portage.generated(path):
                strays.append(str(path))
                continue
            report("prune", rel)
            if not check:
                path.unlink()
    if strays:
        print(f"{len(strays)} unmanaged file(s) left alone:")
        for stray in strays:
            report("", stray)


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
    for name in REQUIRED:
        if not (schema / name).is_dir():
            sys.exit(f"{schema / name}: no such data directory")

    host: str = args.host or socket.gethostname().split(".")[0]
    host_doc: dict[str, Any] | None = data.host(schema, host)
    if host_doc is None:
        if args.host:
            sys.exit(f"{schema}/hosts/{host}.toml: no such host file")
        # an unknown hostname still renders the shared sets, but nothing is disabled
        print(
            f"warning: {schema}/hosts/{host}.toml: host file missing",
            file=sys.stderr,
        )
        host_doc = {}

    print(host)
    check_keys(f"hosts/{host}.toml", host_doc, HOST_KEYS)
    check_types(f"hosts/{host}.toml", host_doc, HOST_TYPES)
    disabled: set[str] = set(host_doc.get("disable") or [])
    kernel_disabled: set[str] = set(host_doc.get("kernel.config.disable") or [])
    names: set[str] = {data.name(path) for path in data.files(schema / "sets")}

    # plan everything first so a bad entry cannot leave a half rendered tree
    plan: Plan = Plan()
    plan_static(schema, plan)
    plan_env(schema, plan)
    kernel_lines: list[str] = plan_sets(schema, host, disabled, names, plan)
    plan_host(host, host_doc, plan)
    plan_kernel(schema, host, kernel_disabled, kernel_lines, plan)

    apply(plan, args.check)
    world(plan, args.check)
    prune(plan, args.check)


if __name__ == "__main__":
    main()
