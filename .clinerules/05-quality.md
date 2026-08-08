# Quality and Tooling Rules

## Build Cleanliness

The agent must keep the repository buildable throughout development.

Before considering a coding task complete, run the relevant Alire build for the crate being modified.

For the top-level library crate, use the configured Alire/GNAT toolchain rather than invoking an unrelated system compiler directly.

New code should not introduce compiler warnings.

Treat warnings from the project's normal development build as issues to fix unless there is a documented reason to suppress a specific warning.

Do not broadly disable warning classes merely to make a build appear clean.

Prefer fixing the underlying code or adding a narrow, documented suppression when necessary.

The agent must not finish a task while knowingly leaving:

- compilation errors
- unresolved linker errors
- broken Alire dependencies
- new compiler warnings
- failing tests caused by the change

## SPARK and GNATprove

GNATprove is a development dependency of the `tests` crate, not the public `opencvcore_ada` crate.

When GNATprove is needed for library code, invoke it through the Alire environment provided by the `tests` crate and explicitly target the appropriate library project when necessary.

Do not add GNATprove to the public library crate merely to make the tool executable available.

Use SPARK where it provides meaningful value in the Ada layer.

Good candidates for SPARK analysis include:

- range and bounds validation
- matrix dimension checks
- type and channel validation
- conversion helpers
- value-type operations
- ownership-state logic that can be modeled safely
- pure Ada utility code
- contracts on public operations

Do not force C/C++ interoperability code into SPARK when the foreign interface prevents useful proof.

Treat calls into the C++ shim as trusted external boundaries unless a stronger model is explicitly provided.

Use preconditions, postconditions, type invariants, and assertions where they improve correctness and make assumptions explicit.

Do not add contracts merely to increase proof statistics.

When modifying SPARK-compatible code, run GNATprove when practical and address newly introduced proof failures before considering the task complete.

Clearly distinguish between:

- properties proven by GNATprove
- properties enforced by Ada runtime checks
- properties assumed at the C/C++ boundary
- behavior validated only through testing

## Source Formatting

Use GNATformat for Ada source formatting.

The repository's preferred formatter is the standalone Alire-installed GNATformat tool.

When formatting a file, use the standalone formatter directly.

For example:

```bash
~/.alire/bin/gnatformat SOURCE_FILE
```

Format newly created or substantially modified Ada source files before considering a task complete.

Do not perform repository-wide formatting as a side effect of an unrelated change.

Do not reformat unrelated source files merely because the formatter would produce different output.

Keep formatting-only changes separate from functional changes when practical.

If GNATformat and an explicit project coding convention disagree, follow the documented project convention and update formatter configuration where possible rather than repeatedly fighting the formatter manually.

Formatting must not be used to conceal or combine unrelated code changes.

## Task Completion Checks

Before considering a coding task complete, the agent should perform the relevant checks in this order:

1. Format modified Ada source files with GNATformat.
2. Build the affected Alire crate.
3. Run the relevant AUnit tests.
4. Run GNATprove for affected SPARK-compatible code when practical.
5. Run GNATcov through the `tests` crate when the change is significant enough to justify coverage verification.
6. Review the final diff for unrelated or accidental changes.

GNATprove and GNATcov should be invoked through the `tests` Alire environment because they are development dependencies of that crate.

Do not add GNATprove or GNATcov to the public library crate merely to simplify tool invocation.

Do not claim a task is complete if a required check was skipped because of a known failure.

If a check cannot be run, explicitly state:

- which check was not run
- why it could not be run
- what remains to be verified

Prefer targeted checks during development, followed by broader verification before completing a substantial feature.

Do not rebuild or retest unrelated crates unnecessarily.
