# @MACRO@ tokens

import os
import subprocess
import sys
from collections.abc import Callable


def cpu_flags() -> str:
    try:
        probe = subprocess.run(
            ["cpuid2cpuflags"], capture_output=True, text=True, check=True
        )
    except subprocess.CalledProcessError as error:
        sys.exit(f"cpuid2cpuflags: {error.stderr.strip() or error}")
    except OSError as error:
        sys.exit(f"cpuid2cpuflags: {error}")
    return " ".join(probe.stdout.split())


def jobs() -> str:
    count: int | None = getattr(os, "process_cpu_count", os.cpu_count)()
    return str(count or 4)


# @macro@ -> closure
AT_MACROS: dict[str, Callable[[], str]] = {
    "@JOBS@": jobs,
    "@CPU_FLAGS@": cpu_flags,
}
