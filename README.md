[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/tyler36/ddev-vitest/actions/workflows/tests.yml/badge.svg)](https://github.com/tyler36/ddev-vitest/actions/workflows/tests.yml)
[![last commit](https://img.shields.io/github/last-commit/tyler36/ddev-vite)](https://github.com/tyler36/ddev-vite/commits)
[![release](https://img.shields.io/github/v/release/tyler36/ddev-vite)](https://github.com/tyler36/ddev-vite/releases/latest)

# ddev-vitest <!-- omit in toc -->

## Overview?

[ddev-vitest](https://github.com/tyler36/ddev-vitest) is a helper add-on for DDEV that improves the developer experience for projects using Vitest.

[Vitest](https://vitest.dev/) describes itself as a "next generation testing framework", a fast "Vite-native" testing framework.

## Installation

```shell
ddev add-on get tyler36/ddev-vitest
ddev restart
```

After installation, make sure to commit the .ddev directory to version control.

## Usage

`ddev vitest` is a helper command to run Vitest from the host.
It accepts all flags accepted by vitest.
For example, to see the currently installed version of Vitest:

  ```shell
  ddev vitest --version
  ```

### Commands

| Command             | Description                                          |
| ------------------- | ---------------------------------------------------- |
| `ddev vitest`       | Run Vitest from host                                 |
| `ddev vitest-ui -s` | Start and launch Vitest UI server in default browser |
| `ddev vitest-ui`    | Launch Vitest UI server in default browser           |

> [!NOTE]
> If you attempt to start Vitest UI via `ddev vitest --ui`, this addon hijacks the command and re-writes it to be compatible with DDEV.

### Auto-start Vitest UI

Use DDEV's `post-start` hook to automatically start Vitest UI.

The following snippet starts the UI server and launches the test page.

```yaml
hooks:
  post-start:
    - exec-host: ddev vitest-ui
```

## Vite

Vitest is a great companion to Vite.
For more information about using Vite with DDEV,

- [tyler36/ddev-vite](https://github.com/tyler36/ddev-vite): a DDEV addon for Vite.
- Matthias Andrasch's excellent blog post - [Working with Vite in DDEV - an introduction](https://ddev.com/blog/working-with-vite-in-ddev/).

## Credits

**Contributed and maintained by [`tyler36`](https://github.com/tyler36)**
