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

After each meaningful code or build-configuration change:

- build the affected crate if the current state has not already been successfully built
- fix errors before continuing
- run focused tests when the relevant implementation or tests have changed

Do not rerun a successful build or test when no relevant files have changed.

Do not continue stacking changes on top of a known broken build.

## Loop Prevention, Failure Handling, and Progress Rules

Every tool call must make progress toward the current task.

### Never Repeat Identical Commands Without a State Change

Never execute the exact same command with the same arguments twice in a row.

This applies whether the previous command:

- succeeded
- failed
- returned no output
- returned unexpected output
- exited with a nonzero status

A failed command is diagnostic information, not a reason to immediately retry the same command.

An identical retry is permitted only if something relevant has changed
independently of the previous command, such as:

- a source file was modified
- a configuration file was modified
- a dependency was installed or changed
- the working directory was deliberately changed
- the environment or toolchain configuration was deliberately changed

Changes caused solely by the previous command do not count as a relevant
state change for retrying that same command.

In particular:

- build artifacts produced by a build do not justify immediately rebuilding
- test output produced by a test does not justify immediately rerunning the test
- generated logs or reports do not justify rerunning the command that created them
- merely changing command arguments to cosmetically retry the same operation
  does not count as progress

If none of those conditions occurred, do not retry the command.

### Required Behavior After Command Failure

Whenever a command fails:

1. Read and interpret the error output.
2. State internally what the failure indicates.
3. Identify at least one plausible cause.
4. Choose a next action that is meaningfully different from the failed command.
5. Do not retry the failed command until something relevant has changed.

For example, if a tool reports that an imported GPR project cannot be found, do not repeatedly invoke the same tool.

Instead, investigate or correct the project environment, dependency path, working directory, or invocation method.

### Retry Limit

Do not perform more than one retry for the same failure condition unless a relevant state change has occurred.

If two attempts produce the same or substantially equivalent error:

- stop retrying
- do not try cosmetic variations of the same command
- choose a different diagnostic approach

If no distinct productive next action is apparent, stop and ask the user for direction.

### Command Result Consumption

After every `execute_command` result, the next action must not be the same
command.

Before issuing another tool call, explicitly determine:

1. What new fact did the previous command establish?
2. Did repository, filesystem, dependency, build, or environment state change?
3. What different action follows from the result?

If the previous command succeeded, consume the result and advance to the next
implementation, inspection, test, or verification step.

If the previous command failed, diagnose the error and change something or run
a meaningfully different diagnostic before retrying.

Never use a repeated command as a way to "continue thinking."

A build that completed successfully is complete evidence that the build passed
at that point. Do not immediately build again.

A test command that completed successfully is complete evidence that those
tests passed at that point. Do not immediately run the same tests again.

### Verification Result Freshness

Treat successful build, test, formatting, proof, and coverage results as cached
verification of the current repository state.

Do not repeat a verification command if:

- the command already succeeded, and
- no file relevant to that verification has changed since it succeeded.

This applies to:

- `alr build`
- test executables
- AUnit test runs
- GNATprove
- GNATcov
- GNATformat verification
- other compile, link, test, or static-analysis commands

A successful verification remains valid until relevant state changes.

Task-completion checks must reuse successful verification results obtained
earlier in the task when no relevant files have changed.

Do not rerun a successful build merely because the workflow has reached a
later "completion checks" step.

Do not rerun successful tests merely because the workflow has reached the end
of the task.

Only invalidate a previous verification result after a relevant change.

Examples:

source edit
-> build
-> build succeeds
-> inspect unrelated file
-> do NOT build again

source edit
-> build
-> build succeeds
-> source edit
-> previous build result is stale
-> build again

tests run
-> tests succeed
-> no source or test changes
-> do NOT run tests again

tests run
-> tests succeed
-> test or implementation changes
-> previous test result is stale
-> run tests again

### Tool Hook Rejections

A command rejected by a project hook must not be retried unchanged.

If the duplicate-command guard blocks a command, this means the previous
execution result is already available and should be reused.

Do not interpret a duplicate-command hook rejection as a command failure that
needs to be retried.

After a duplicate command is blocked:

1. use the result from the previous successful or failed invocation
2. continue to a different implementation or diagnostic step
3. do not submit the blocked command again

### Diagnostic Commands

A successful read-only or diagnostic command result is authoritative for the current state unless something relevant changes.

Examples include:

- `grep`
- `find`
- `cat`
- `ls`
- `git status`
- `git diff`
- compiler or tool version queries
- searches for project files
- searches through installed dependency sources

After a successful diagnostic command:

1. consume and reason about its output
2. retain the discovered fact
3. choose the next distinct action

Do not repeatedly search for information that has already been found.

### Error-Driven Debugging

When investigating a build, formatting, or test failure, use the actual error message to choose the next diagnostic step.

Do not respond to an error by blindly repeating the failing command.

Prefer:

failure
-> interpret error
-> inspect relevant configuration or environment
-> make a corrective change
-> retry once

over:

failure
-> retry
-> retry
-> retry

If a tool invocation fails because it is outside the correct Alire environment, investigate running the tool through the appropriate Alire crate rather than repeatedly invoking the standalone command.

### Loop Detection

Treat any of the following as a loop:

- the same command is issued twice consecutively
- the same failure appears twice without a relevant intervening state change
- the same file or symbol is repeatedly searched for after it has already been found
- multiple diagnostic commands are producing the same known fact without advancing implementation

When a loop is detected:

1. stop issuing tool calls
2. summarize what is already known
3. choose a genuinely different approach
4. ask the user if no productive alternative is clear

## Terminal Command Rules

When using terminal tools:

- Execute exactly one shell command per tool call.
- Never combine commands using `&&`, `||`, `;`, or pipes.
- Never use shell redirection such as `>`, `>>`, `<`, `2>&1`, or command substitution.
- Change directories and run commands as separate terminal tool calls.
- Do not HTML-encode shell characters.
- Before requesting execution, verify that the command contains no strings such as `&amp;`, `&gt;`, or `&lt;`.

Prefer Alire-aware commands when operating on Ada projects.

Example:

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
