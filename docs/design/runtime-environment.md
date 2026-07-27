# Init Environment

> 规范状态：正式设计。实现状态：已实现，由 `bin/themis-init.sh` 加载并验证。

Themis validates its installation prerequisites when `themis-init.sh` starts. These checks belong to the source repository's installation tooling and are not part of an installed project's Core or Workspace runtime.

## Scope

The check requires:

| Dependency | Supported version | Purpose during Init |
|---|---|---|
| Bash | 3.2.0 or newer | Run Themis installation scripts with a portable syntax baseline. |
| Git | 2.0.0 or newer | Read Git installation and target-project metadata required by Init. |
| [mikefarah/yq](https://github.com/mikefarah/yq) | Major version 4, starting at v4.0.0 | Read, validate, and update YAML installation files. |

The check does not inspect or configure:

- Agent or Claude Code availability;
- file-system permissions;
- project language runtimes, test frameworks, containers, or CI tools;
- dependencies used by normal Themis SDD workflows after installation.

Upgrade must perform only the compatibility checks defined by the Upgrade design. It must not source or invoke the Init environment library.

## yq contract

Only the Go implementation published as `mikefarah/yq` is supported. Python packages and other commands named `yq` are incompatible even when they are available on `PATH`.

Init uses the v4 command-line contract:

```bash
yq eval '<expression>' '<file>'
```

```bash
yq eval -i '<expression>' '<file>'
```

A future yq major version is not accepted automatically because its command and expression compatibility has not been established.

## Validation behavior

The private library is `bin/_themis-init-env.sh`. `bin/themis-init.sh` sources it and invokes:

```bash
themis_init_require_environment
```

Checks run in this order:

1. Bash;
2. Git;
3. mikefarah/yq.

The first failed check stops validation. Success is silent and returns status `0`. Failure writes one diagnostic to standard error and returns a non-zero status:

```text
Themis Init prerequisite failed: <tool>
  Required: <requirement>
  Detected: <detected-version-or-not-found>
  Reason: <missing | unsupported implementation | version too old | version unreadable>
  Install: <guidance>
```

Validation reads version output only. It does not install software or modify files, configuration, environment variables, Core, or Workspace.

## Installation guidance

### macOS

- Bash: macOS system Bash 3.2 satisfies the minimum. If another older Bash is selected, install a newer Bash and run Init with it.
- Git: install or update with Homebrew using `brew install git`, or use a compatible system Git.
- yq: install the mikefarah implementation with `brew install yq` and confirm `yq --version` reports v4.

### Linux

- Bash and Git: install compatible versions through the distribution package manager.
- yq: use a distribution package only after confirming it is mikefarah/yq v4, or install an official binary from the [mikefarah/yq releases](https://github.com/mikefarah/yq/releases).

### Windows Git Bash

- Bash and Git: install or upgrade Git for Windows, then run Init inside Git Bash.
- yq: download a mikefarah/yq v4 Windows binary from the [official releases](https://github.com/mikefarah/yq/releases), name or wrap it as `yq`, and add its directory to `PATH` inside Git Bash.

After correcting a prerequisite, rerun Init. Themis does not perform silent dependency installation.
