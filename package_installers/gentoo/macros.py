# @MACRO@ tokens

import os
import subprocess
import sys
from collections.abc import Callable


# run a probe, exit with whatever it complained about
def probe(command: list[str]) -> str:
    try:
        return subprocess.run(
            command, capture_output=True, text=True, check=True
        ).stdout
    except subprocess.CalledProcessError as error:
        sys.exit(f"{command[0]}: {error.stderr.strip() or error}")
    except OSError as error:
        sys.exit(f"{command[0]}: {error}")


def cpu_flags() -> str:
    return " ".join(probe(["cpuid2cpuflags"]).split())


def jobs() -> str:
    count: int | None = getattr(os, "process_cpu_count", os.cpu_count)()
    return str(count or 4)


# how many mirrors mirrorselect picks
MIRROR_SERVERS: int = 4

# GENTOO_MIRRORS value, quoted for make.conf
def mirrors() -> str:
    print("selecting mirrorlist")
    output: str = probe(
        ["mirrorselect", "--servers", str(MIRROR_SERVERS), "--output", "--quiet", "--deep"]
    )
    # mirrorselect wraps the assignment over several lines
    for line in output.replace("\\\n", " ").splitlines():
        key, _, value = line.strip().partition("=")
        if key != "GENTOO_MIRRORS":
            continue
        urls: list[str] = value.strip().strip("\"'").split()
        if urls:
            return f'"{" ".join(urls)}"'
    sys.exit("mirrorselect: no GENTOO_MIRRORS in its output")


# @macro@ -> closure
AT_MACROS: dict[str, Callable[[], str]] = {
    "@JOBS@": jobs,
    "@CPU_FLAGS@": cpu_flags,
    "@GENTOO_MIRRORS@": mirrors,
}
