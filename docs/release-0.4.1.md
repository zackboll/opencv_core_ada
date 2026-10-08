# opencv_core 0.4.1 maintenance candidate

This patch corrects recursive GPRinstall of the externally built Windows Core
shim. It does not change the public Ada or C API. Features Task 008 remains
paused; no post-0.4.0 Core functionality is included.

## Lineage and predecessor certification

- PR #52 implementation: `42afb59ece62b18a2bc380fc70c015fa53f5965d`.
- PR #52 merge: `7897ecb869580c0a6396792dee88d817f87aebf6`.
- Post-merge run: https://github.com/zackboll/opencv_core_ada/actions/runs/37555676196
  completed successfully at that merge SHA. Actual completed logs were inspected.
- Annotated 0.4.0 tag object: `5f524caacb6fcc06a913f39aab9c86a29d70ce64`.
- Peeled tag / maintenance base: `99867564ad5d4560a95ed18038104771a1673ac6`.
- Both trees: `76f6408dc8bfc638424444b5ab7cae3c6dba3584`.
- Historical release branch remains `87fa3ce2907aa785a357a1dda812e80a4a84b0d9`.

Gate 0 completed job IDs (all success):

| Job | ID |
| --- | --- |
| Alire Fedora Latest | 112581225879 |
| Windows x86_64 / MSYS2 | 112581225923 |
| Alire Ubuntu LTS | 112581225961 |
| macOS ARM64 | 112581226024 |
| Release entry point | 112581226029 |
| OpenCV 5.0 | 112581226064 |
| OpenCV 4.6 | 112581226067 |
| OpenCV 4.10 | 112581226075 |
| OpenCV 4.1 | 112581226079 |
| Ubuntu 24.04 ARM64 | 112581226080 |
| macOS ARM64 MacPorts | 112581226088 |

Windows logs explicitly showed the external MSYS2 MinGW64 `g++.exe`,
`External Core DLL/import archive installed VERIFIED`,
`Original Core prefix removed VERIFIED`, PE import of
`libopencv_core_shim.dll`, both consumer PASS markers, and
`opencv_core installed Mat consumer ok` after relocation. Windows and MacPorts
each passed 1875 tests with zero failed assertions/unexpected errors. Those
counts describe predecessor main, not this maintenance release.

## Correction and qualification contract

Only `opencv_core_shim.gpr` production project metadata changes. The external
branch retains `Externally_Built = True` and `Library_Kind = relocatable`, adds
`Languages = ("C++")` and `Source_Dirs = ("cpp/")`, and requires
`lib/libopencv_core_shim.dll.a` in the installed shim library directory.
The external MSYS2 builder remains responsible for compilation and DLL/import
archive creation. No production Ada/native sources or ABI symbols change.

The packaging unittest reproduces `no language found, aborting`, demonstrates
that a language-only project installs no usable library, verifies byte-identical
external library/archive installation, and rejects a missing archive. Its Linux
archive fixture is not Windows import-archive evidence.

The real validator recursively installs Core to A, fresh-builds/runs a public
Mat consumer, moves A to a longer B, verifies A is absent and not a symlink,
then fresh-builds/runs another consumer. It audits installed source/ALI/library
resolution and rejects source-tree library lookup. Windows additionally checks
DLL/import archive, rejects a static substitute, and inspects consumer PE imports.
Raw logs are preserved, with Windows separator normalization only for audits;
no unsupported `gprbuild -vP2` or pipefail/grep-q shortcut is used.

Final candidate SHA, local results, completed candidate matrix jobs, publication
dry-run manifest audit, and PR head equality belong in the review handoff.
No tagging, merging, publication, or Alire index modification is authorized.
Index PR #2198 remains separate and must not be modified by this task.