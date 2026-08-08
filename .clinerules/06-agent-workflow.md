# Agent Development Workflow

## Incremental Development

Work in small, reviewable steps.

Before modifying code:

- inspect the relevant existing source files
- inspect the applicable Alire manifest and GPR project files
- understand the existing package hierarchy
- identify the smallest change needed

Do not make large speculative rewrites.

Do not create multiple architectural layers, packages, or abstractions in advance unless they are required by the current task.

Prefer implementing and validating one coherent piece of functionality at a time.

After each meaningful change:

- build the affected crate
- fix errors before continuing
- run focused tests when available

Do not continue stacking changes on top of a known broken build.

## Terminal Command Rules

When using terminal tools:

- Execute exactly one shell command per tool call.
- Never combine commands using `&&`, `||`, `;`, or pipes.
- Never use shell redirection such as `>`, `>>`, `<`, `2>&1`, or command substitution.
- Change directories and run commands as separate terminal tool calls.
- Do not HTML-encode shell characters.
- Before requesting execution, verify that the command contains no strings such as `&amp;`, `&gt;`, or `&lt;`.

Prefer Alire-aware commands when operating on Ada projects.

Examples:

```bash
alr build
```

GNATprove and GNATcov are provided by the `tests` Alire crate.

Run these tools from the `tests` crate, explicitly targeting the appropriate project when required.

Do not add verification tools to the public library crate merely to make them available from its Alire environment.

Do not bypass the Alire environment with a system GNAT toolchain unless there is a specific documented reason.

## Inspect Before Creating Bindings

Before adding a new OpenCV binding operation, inspect the actual OpenCV declaration being wrapped.

Do not invent function signatures, overload behavior, ownership rules, default arguments, template behavior, or exception semantics from memory.

Before implementing a binding:

- locate the relevant OpenCV Core header or official declaration
- identify the exact C++ type, method, overload, or template being wrapped
- inspect existing shim functions for related functionality
- inspect the existing public Ada API for naming and design consistency
- check whether the functionality already exists elsewhere in the binding

The agent should understand the OpenCV semantics before designing the Ada abstraction.

Do not mechanically expose every C++ overload.

Instead:

1. understand the complete OpenCV overload family
2. decide what public Ada abstraction best represents it
3. design the minimal C ABI needed to support that abstraction
4. implement the thin Ada binding
5. implement the thick Ada API
6. add focused tests

Prefer extending an existing abstraction over creating a parallel or duplicate API.

When unsure about OpenCV behavior, stop and inspect the authoritative OpenCV source or documentation rather than guessing.

## Vertical Feature Development

Implement bindings vertically, one coherent feature at a time.

For each new OpenCV Core feature, prefer this sequence:

1. inspect the authoritative OpenCV declaration
2. design the public Ada abstraction
3. add only the C++ shim surface required by that abstraction
4. add or update the thin Ada interop binding
5. implement the thick Ada API
6. add focused AUnit tests
7. build and run the affected tests
8. run GNATprove or GNATcov when relevant

Do not batch large groups of unrelated shim functions before the Ada API that uses them exists.

Do not generate broad C++ wrapper coverage speculatively.

A feature is not considered complete merely because the C++ shim compiles.

Prefer one fully integrated and tested binding over many partially implemented declarations.

Keep each change small enough that ownership, error handling, ABI behavior, and public API design can be reviewed together.

## Stop for Architectural Decisions

Do not silently make significant public API or architecture decisions when multiple reasonable designs exist.

Stop and ask for direction before making choices that materially affect:

- public package hierarchy
- public type names
- ownership semantics
- shallow-copy versus deep-copy behavior
- tagged-type inheritance
- generic package structure
- exception model
- ABI compatibility
- whether functionality belongs in Ada or the C++ shim
- whether a dependency belongs in the main crate or test crate
- compatibility aliases that may become part of the public API

Small implementation details may be resolved independently when they clearly follow established project rules.

When asking for direction:

- present the specific decision
- briefly describe the main options
- recommend one option
- explain the important tradeoff

Do not block on trivial stylistic choices already covered by the repository rules.
