#!/usr/bin/env python3
# render the data into portage configurations

import argparse
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

# sets merge their kernel.config lines into one snippet, numbered last
SETS_CONFIG: str = "99-sets.config"
# files a machine renders once
ONCE: str = "once.toml"


def report(label: str, subject: str) -> None:
    print(f"{label:<9} {subject}")


def relative(path: Path) -> str:
    for root in (portage.PORTAGE, portage.KERNEL):
        if path.is_relative_to(root):
            return path.relative_to(root).as_posix()
    return str(path)


# rendered files and the source that claimed them, in render order
class Plan:
    def __init__(self) -> None:
        self.files: dict[Path, tuple[str, str]] = {}

    def claim(self, path: Path, source: str) -> None:
        if path in self.files:
            sys.exit(
                f"{source} and {self.files[path][0]} both write {relative(path)}"
            )

    def text(self, source: str, lines: Iterable[str]) -> str:
        text: str = (
            portage.MARKER.format(source)
            + "\n"
            + "".join(f"{line}\n" for line in lines)
        )

        # @macro@
        for token, value in AT_MACROS.items():
            if token in text:
                text = text.replace(token, value())

        return text

    def add(self, root: Path, rel: str, lines: Iterable[str], source: str) -> None:
        path: Path = root / rel
        self.claim(path, source)
        self.files[path] = (source, self.text(source, lines))

    # once file, kept while its marker says it is ours
    def once(
        self,
        root: Path,
        rel: str,
        lines: Iterable[str],
        source: str,
        again: bool,
    ) -> None:
        path: Path = root / rel
        if path.is_file() and not again:
            # a file nobody generated is not ours to replace
            if not portage.generated(path):
                return
            self.claim(path, source)
            self.files[path] = (source, data.read(path))
            return
        self.claim(path, source)
        self.files[path] = (source, self.text(source, lines))


# make.conf/ and repos.conf/ and binrepos.conf/
def plan_static(schema: Path, plan: Plan) -> None:
    for path in data.files(schema / "make.conf"):
        source: str = f"make.conf/{data.name(path)}"
        doc: dict[str, Any] = data.load(path)
        plan.add(portage.PORTAGE, source, portage.lines(doc), source)

    # one ini section per data file, named after it
    for folder in ("repos.conf", "binrepos.conf"):
        for path in data.files(schema / folder):
            name: str = data.name(path)
            source: str = f"{folder}/{name}"
            doc: dict[str, Any] = data.load(path)
            plan.add(
                portage.PORTAGE, f"{source}.conf", portage.ini({name: doc}), source
            )


# env/ and package.env/
def plan_env(schema: Path, plan: Plan) -> None:
    for path in data.files(schema / "env"):
        name: str = data.name(path)
        source: str = f"env/{name}"
        doc: dict[str, Any] = data.load(path)
        env: list[str] = doc.get("env") or []
        packages: list[str] = doc.get("packages") or []
        if packages and not env:
            sys.exit(f"{source}: packages needs env")
        if env:
            plan.add(portage.PORTAGE, source, env, source)
        if packages:
            lines = (f"{atom} {name}" for atom in packages)
            plan.add(portage.PORTAGE, f"package.env/{name}", lines, source)


# sets/ and package.*/, returns the merged kernel.config lines
def plan_sets(schema: Path, host: str, disabled: set[str], plan: Plan) -> list[str]:
    paths: list[Path] = data.files(schema / "sets")
    names: set[str] = {data.name(path) for path in paths}
    for name in sorted(disabled - names):
        print(f"note: {host} disables unknown set {name}", file=sys.stderr)
    kernel_lines: list[str] = []
    for path in paths:
        name = data.name(path)
        if name in disabled:
            continue
        source: str = f"sets/{name}"
        doc: dict[str, Any] = data.load(path)
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
    if install:
        plan.add(portage.PORTAGE, f"sets/{host}", install, source)
    for key, lines in entries.items():
        plan.add(portage.PORTAGE, f"{key}/{host}", lines, source)
    if make:
        plan.add(portage.PORTAGE, f"make.conf/50-{host}", portage.lines(make), source)


# kernel.config.d/ and the merged sets snippet
def plan_kernel(
    schema: Path, host: str, disabled: set[str], kernel_lines: list[str], plan: Plan
) -> None:
    paths: list[Path] = data.entries(schema / "kernel.config.d")
    names: set[str] = {path.name for path in paths}
    for name in sorted(disabled - names - {SETS_CONFIG}):
        print(f"note: {host} disables unknown kernel config {name}", file=sys.stderr)
    if SETS_CONFIG in names:
        sys.exit(f"kernel.config.d/{SETS_CONFIG}: reserved for the sets")
    for path in paths:
        if path.name in disabled:
            continue
        source: str = f"kernel.config.d/{path.name}"
        plan.add(
            portage.KERNEL,
            f"config.d/{path.name}",
            data.read(path).splitlines(),
            source,
        )
    if kernel_lines and SETS_CONFIG not in disabled:
        plan.add(
            portage.KERNEL, f"config.d/{SETS_CONFIG}", kernel_lines, "sets/*.config"
        )


# once.toml
def plan_once(schema: Path, plan: Plan, again: bool) -> None:
    for rel, entries in data.load(schema / ONCE).items():
        source: str = f"{ONCE}:{rel}"
        path: Path = Path(rel)
        if path.is_absolute() or ".." in path.parts:
            sys.exit(f"{source}: must stay inside the portage config")
        plan.once(portage.PORTAGE, rel, portage.lines(entries), source, again)


def apply(plan: Plan, force: bool) -> None:
    for path, (source, text) in plan.files.items():
        if path.is_dir():
            sys.exit(f"{source}: {relative(path)} is a directory")
        exists: bool = path.is_file()
        if not force and exists and data.read(path) == text:
            continue
        report("update" if exists else "create", relative(path))
        data.write(path, text)


def world(plan: Plan, force: bool) -> None:
    sets: set[str] = {
        path.name for path in plan.files if path.parent == portage.PORTAGE / "sets"
    }
    entries: list[str] = portage.world_entries(sets)
    text: str = "".join(f"{entry}\n" for entry in entries)
    if not force and data.read(portage.WORLD_SETS) == text:
        return
    report("update", str(portage.WORLD_SETS))
    for entry in entries:
        report("", entry)
    data.write(portage.WORLD_SETS, text)


def prune(plan: Plan) -> None:
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
                strays.append(rel)
                continue
            report("prune", rel)
            path.unlink()
    if strays:
        print(f"{len(strays)} unmanaged file(s) left alone:")
        for stray in strays:
            report("", stray)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Render the data files into /etc/portage and /etc/kernel."
    )
    parser.add_argument("--host", help="hostname")
    parser.add_argument("--all", action="store_true", help="write every file")
    parser.add_argument(
        "--once-again",
        action="store_true",
        help="render every once.toml entry again",
    )
    args: argparse.Namespace = parser.parse_args()

    schema: Path = Path(__file__).resolve().parent
    for name in REQUIRED:
        if not (schema / name).is_dir():
            sys.exit(f"{schema / name}: no such data directory")
    if not (schema / ONCE).is_file():
        sys.exit(f"{schema / ONCE}: no such data file")

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

    print(f"host: {host}")
    disabled: set[str] = set(host_doc.get("disable") or [])
    kernel_disabled: set[str] = set(host_doc.get("kernel.config.disable") or [])

    # plan everything first so a bad entry cannot leave a half rendered tree
    plan: Plan = Plan()
    plan_static(schema, plan)
    plan_env(schema, plan)
    kernel_lines: list[str] = plan_sets(schema, host, disabled, plan)
    plan_host(host, host_doc, plan)
    plan_kernel(schema, host, kernel_disabled, kernel_lines, plan)
    plan_once(schema, plan, args.once_again)

    apply(plan, args.all)
    world(plan, args.all)
    prune(plan)


if __name__ == "__main__":
    main()
