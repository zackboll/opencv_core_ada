#!/usr/bin/env python3
"""Real compiler/object/runtime and loader checks; no GCC-major/ALI inference.

Dependency/version checking follows the previously qualified Geometry checker.
Inputs are explicit Core cross environment variables. Does not modify inputs.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile


def require(condition, message):
    if not condition:
        raise ValueError(message)


def run(*args, **kwargs):
    return subprocess.check_output([str(arg) for arg in args], text=True,
                                   stderr=subprocess.STDOUT, **kwargs)


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def contained(path, root):
    resolved = Path(path).resolve(strict=True)
    require(resolved.is_relative_to(root), f"path escapes {root}: {path}")
    return resolved


def elf(path):
    text = run("readelf", "-h", path)
    for field, expected in (("Class", "ELF64"), ("Data", "little endian"),
                            ("Machine", "AArch64")):
        values = re.findall(r"^\s*" + field + r":\s*(.+)$", text, re.M)
        require(values and all(expected in value for value in values),
                f"wrong {field}: {path}")


def comments(path):
    return set(re.findall(r"\[\s*[0-9a-f]+\]\s+(.+)",
                          run("readelf", "-p", ".comment", path)))


def signature(path):
    first = Path(path).read_text().splitlines()[0]
    require(re.fullmatch(r'V "GNAT Lib v[0-9.]+"', first), f"bad ALI: {path}")
    return first


def check_trace(path, ada, cxx, sysroot):
    commands = 0
    for line in path.read_text().splitlines():
        words = shlex.split(line)
        if not words:
            continue
        name = Path(words[0]).name
        if not re.fullmatch(r"(?:[\w.-]+-)?(?:gcc|g\+\+|gnatbind|ar|ranlib)(?:-[0-9]+)?", name):
            continue
        driver = Path(words[0])
        if "gcc" in name or "g++" in name:
            require(driver.is_absolute() and driver.resolve() in (ada, cxx),
                    f"unsupplied compiler/linker: {line}")
            for word in words:
                require(not re.match(r"-[IL]/usr/(?:local/)?(?:include|lib)\b", word)
                        and "x86_64" not in word, f"host search path: {line}")
            if "-c" in words and not words[-1].startswith("b__"):
                require("--sysroot=" + str(sysroot) in words,
                        f"compile missing supplied sysroot: {line}")
            commands += 1
        else:
            require(name.startswith("aarch64-linux-gnu-"), f"host tool: {line}")
    require(commands, f"no supplied compiler invocations in {path}")
    return commands


def check_summary(path):
    text = path.read_text()
    for line in ("Registered tests: 2025", "Total Tests Run:   2025",
                 "Successful Tests:  2025", "Failed Assertions: 0",
                 "Unexpected Errors: 0"):
        require(text.splitlines().count(line) == 1, f"missing/duplicate summary: {line}")
    sequence = re.findall(r"^RUN ([0-9]+)/2025: .+$", text, re.M)
    require(sequence == [str(index) for index in range(1, 2026)],
            "missing, duplicate or reordered test execution records")
    require(not re.search(r"^(?:FAIL|ERROR) ", text, re.M), "test failure record")
    return dict(registered=2025, executed=2025, successful=2025,
                failed_assertions=0, unexpected_errors=0)


def qualified_run_directories(item, sysroot, dynamic):
    searches = re.findall(r"\((?:RPATH|RUNPATH)\).*\[([^\]]*)\]", dynamic)
    require(not searches or item.is_relative_to(sysroot),
            f"executable has an unqualified run path: {item}")
    directories = []
    for search in searches:
        for entry in search.split(":"):
            # The qualified SDK OpenCV embeds target-root /usr/lib.
            require(entry in ("/lib", "/usr/lib", "/lib64", "/usr/lib64"),
                    f"unqualified run path: {item}: {entry}")
            directories.append(contained(sysroot / entry.lstrip("/"), sysroot))
    return searches, directories


def versions(path, definitions=False):
    text = run("readelf", "-V", path)
    if definitions:
        section = text.split("Version definition section", 1)
        return set() if len(section) < 2 else set(re.findall(
            r"Name:\s+(\S+)", section[1].split("Version needs section", 1)[0]))
    section = text.split("Version needs section", 1)
    needs = {}
    current = None
    for line in section[-1].splitlines() if len(section) == 2 else []:
        match = re.search(r"File:\s+(\S+)", line)
        if match:
            current = match[1]
            needs[current] = set()
        match = re.search(r"Name:\s+(\S+)", line)
        if match and current:
            needs[current].add(match[1])
    return needs


def executable(path, sysroot):
    elf(path)
    match = re.search(r"Requesting program interpreter: ([^\]]+)\]",
                      run("readelf", "-l", path))
    require(match and match[1] == "/lib/ld-linux-aarch64.so.1",
            f"wrong interpreter: {path}")
    loader = contained(sysroot / match[1].lstrip("/"), sysroot)
    # This Scarthgap profile uses standard target loader directories. Reject
    # custom loader configuration rather than silently guessing its semantics.
    config = sysroot / "etc/ld.so.conf"
    require(not config.exists() or not config.read_text().strip(),
            "nonempty ld.so.conf requires an explicitly reviewed resolver")
    directories = [sysroot / name for name in
                   ("lib", "usr/lib", "lib64", "usr/lib64",
                    "lib/aarch64-linux-gnu", "usr/lib/aarch64-linux-gnu")]
    closure = {}
    pending = [path.resolve(strict=True), loader]
    while pending:
        item = pending.pop()
        if str(item) in closure:
            continue
        elf(item)
        dynamic = run("readelf", "-d", item)
        searches, run_directories = qualified_run_directories(item, sysroot, dynamic)
        needed = {}
        for name in re.findall(r"\(NEEDED\).*\[([^\]]+)\]", dynamic):
            require("/" not in name, f"unsafe DT_NEEDED: {name}")
            candidates = [directory / name for directory in run_directories + directories
                          if (directory / name).exists()]
            require(candidates, f"unresolved dependency: {name}")
            library = contained(candidates[0], sysroot)
            needed[name] = str(library)
            pending.append(library)
        closure[str(item)] = dict(sha256=digest(item), needed=needed,
                                  qualified_run_paths=searches)
    checked = 0
    for item, details in closure.items():
        for name, required in versions(item).items():
            require(name in details["needed"], f"unresolved versions: {name}")
            require(required <= versions(details["needed"][name], True),
                    f"unsatisfied symbol versions: {item}: {name}")
            checked += len(required)
    return dict(interpreter=match[1], closure=closure,
                symbol_versions_checked=checked)


def verify(directory, executables):
    sysroot = Path(os.environ["ENV_PREFIX"]).resolve(strict=True)
    runtime = Path(os.environ["OPENCV_CROSS_RUNTIME"]).resolve(strict=True)
    ada = Path(os.environ["OPENCV_CROSS_ADA"]).resolve(strict=True)
    cxx = Path(os.environ["OPENCV_CROSS_CXX"]).resolve(strict=True)
    ada_version = run(ada, "--version")
    cxx_version = run(cxx, "--version")
    require("25.2" in ada_version and "13.3.1" in ada_version,
            "not the GNAT Pro 25.2 compiler")
    require("25.2" in cxx_version and "13.3.1" in cxx_version,
            "not the matching GNAT Pro 25.2 C++ compiler")
    with tempfile.TemporaryDirectory(prefix="core-ali-identity.") as temporary:
        temp = Path(temporary)
        source = temp / "identity_probe.adb"
        source.write_text("procedure Identity_Probe is begin null; end Identity_Probe;\n")
        run(ada, "--RTS=" + str(runtime), "--sysroot=" + str(sysroot),
            "-c", source, cwd=temp)
        elf(temp / "identity_probe.o")
        ali = signature(temp / "identity_probe.ali")
        identities = comments(temp / "identity_probe.o")
        cpp = temp / "identity_probe.cpp"
        cpp.write_text("int identity_probe() { return 0; }\n")
        run(cxx, "--sysroot=" + str(sysroot), "-c", cpp, "-o", temp / "cpp.o")
        elf(temp / "cpp.o")
        identities |= comments(temp / "cpp.o")
    require(identities, "missing compiler identity")
    runtime_alis = list((runtime / "adalib").glob("*.ali"))
    require(runtime_alis and all(signature(path) == ali for path in runtime_alis),
            "runtime ALI mismatch")
    inventory = {}
    for suffix in (".o", ".a", ".ali"):
        paths = sorted(directory.rglob("*" + suffix))
        require(paths, f"missing {suffix} outputs")
        inventory[suffix] = []
        for path in paths:
            if suffix == ".ali":
                require(signature(path) == ali, f"foreign ALI: {path}")
            else:
                elf(path)
                actual = comments(path)
                require(actual and actual <= identities, f"foreign compiler: {path}")
            inventory[suffix].append(dict(path=str(path), sha256=digest(path)))
    traces = {}
    build_log = directory / "logs/aunit-build.log"
    if build_log.exists():
        traces[str(build_log)] = check_trace(build_log, ada, cxx, sysroot)
    return dict(ali_signature=ali, compiler_identities=sorted(identities),
                ada_version=ada_version, cxx_version=cxx_version,
                runtime_ali_count=len(runtime_alis), compiler_trace_counts=traces,
                ada_sha256=digest(ada), cxx_sha256=digest(cxx),
                runtime_sha256=digest(runtime / "adalib/libgnat.a"),
                counts={key: len(value) for key, value in inventory.items()},
                inventory=inventory,
                executables={str(path): executable(path, sysroot) for path in executables})


if __name__ == "__main__":
    try:
        if len(sys.argv) == 3 and sys.argv[1] == "--summary":
            print(json.dumps(check_summary(Path(sys.argv[2])), sort_keys=True))
            sys.exit(0)
        require(len(sys.argv) >= 3, "usage: verify_outputs.py DIRECTORY EXECUTABLE...")
        print(json.dumps(verify(Path(sys.argv[1]), [Path(p) for p in sys.argv[2:]]),
                         indent=2, sort_keys=True))
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"error: {error}")