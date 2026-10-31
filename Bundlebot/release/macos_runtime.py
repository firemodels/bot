#!/usr/bin/env python3
"""Copy and relocate the non-system Mach-O dependencies of a staged bundle."""

import os
from pathlib import Path
import shutil
import subprocess
import sys


def output(*args):
    return subprocess.check_output(args, text=True)


def is_system(name):
    return name.startswith(("/usr/lib/", "/System/Library/"))


def dependencies(path):
    return [line.strip().split(" (compatibility version", 1)[0]
            for line in output("otool", "-L", str(path)).splitlines()[1:]]


def rpaths(path):
    lines = output("otool", "-l", str(path)).splitlines()
    return [lines[i + 2].strip().split(" (offset", 1)[0][5:]
            for i, line in enumerate(lines) if line.strip() == "cmd LC_RPATH"]


def expand(name, loader, executable):
    return name.replace("@loader_path", str(loader.parent)).replace(
        "@executable_path", str(executable.parent))


def resolve(name, source, executable, search_paths, mpi_prefix):
    if name.startswith("@rpath/"):
        candidates = [Path(expand(base, source, executable)) / name[7:]
                      for base in search_paths]
    else:
        candidates = [Path(expand(name, source, executable))]
    # MPI plugins have already been staged; their sibling libraries still live
    # under the installed prefix when we start walking the dependency graph.
    candidates.append(mpi_prefix / "lib" / Path(name).name)
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    raise RuntimeError(f"Cannot resolve {name} required by {source}")


def bundle(dist, mpi_prefix):
    libdir = dist / "bin/openmpi/lib"
    libdir.mkdir(parents=True, exist_ok=True)
    queue = []
    for directory in (dist / "bin", dist / "smvbin"):
        for path in directory.rglob("*"):
            if path.is_file() and "Mach-O" in output("file", "-b", str(path)):
                queue.append((path, path, path, []))
    processed = set()
    originals = {}
    for source, target, executable, inherited in queue:
        if target in processed:
            continue
        processed.add(target)
        paths = rpaths(source)
        # Expand inherited paths at their defining loader, not at a dependency.
        search = [expand(p, source, executable) for p in paths] + inherited
        deps = dependencies(source)
        is_dylib = "dynamically linked shared library" in output("file", "-b", str(source))
        changes = []
        if is_dylib:
            changes += ["-id", "@loader_path/" + target.name]
            deps = deps[1:]  # The first otool entry is the library's own ID.
        for name in deps:
            if is_system(name):
                continue
            resolved = resolve(name, source, executable, search, mpi_prefix)
            destination = libdir / resolved.name
            previous = originals.get(destination)
            if previous is not None and previous != resolved:
                raise RuntimeError(f"Conflicting libraries: {previous} and {resolved}")
            originals[destination] = resolved
            if destination != resolved and not destination.exists():
                shutil.copy2(resolved, destination)
            queue.append((resolved, destination, executable, search))
            reference = "@loader_path/" + os.path.relpath(destination, target.parent)
            changes += ["-change", name, reference]
        for path in dict.fromkeys(paths):
            changes += ["-delete_rpath", path]
        target.chmod(target.stat().st_mode | 0o200)
        if changes:
            subprocess.run(["install_name_tool", *changes, str(target)], check=True)

    for target in sorted(processed):
        # Editing Mach-O load commands invalidates the original signature.
        # Ad-hoc signing permits local Apple Silicon testing, not distribution
        # through Gatekeeper; a public release still needs Developer ID signing.
        subprocess.run(["codesign", "--force", "--sign", "-", str(target)], check=True)
        deps = dependencies(target)
        if "dynamically linked shared library" in output("file", "-b", str(target)):
            deps = deps[1:]
        for name in deps:
            if not is_system(name):
                if not name.startswith("@loader_path/") or not Path(
                        expand(name, target, target)).is_file():
                    raise RuntimeError(f"Unbundled dependency {name} in {target}")
    print(f"Relocated and signed {len(processed)} Mach-O files")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: macos_runtime.py STAGED_BUNDLE OPENMPI_PREFIX")
    bundle(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
