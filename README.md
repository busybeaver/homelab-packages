# HomeLab: Packages, Services, and Applications

Building, packaging, and publishing services and applications for the personal HomeLab.

**Note:** The original licenses of all services/packages below stay untouched/intact. Please refer to the websites/repositories of each service to get more information about the respective licenses.

## Target Systems/Environments

- [Ubuntu Core](https://ubuntu.com/core) ([Snap Packages](https://snapcraft.io/))
- [Docker](https://www.docker.com/) ([Images](https://hub.docker.com/))

## Snap Packages

_Update 2024-03-04:_ Temporary unmaintained since those currently aren't used anymore in the local setup/environment.

Published to the [Snapcraft store](https://snapcraft.io/) (right now privately/unlisted).

- HashiCorp [Nomad](https://www.nomadproject.io/)
- HashiCorp [Consul](https://www.consul.io/)

_Note:_ Canonical provides a HashiCorp [Vault snap package](https://snapcraft.io/vault), so no need to build/create it.

## Docker Images

Docker images are pushed/published to GitHub packages (the ghcr.io registry) within this repository.

- A modified [HomeAssistant](https://www.home-assistant.io/) version that can be run as non-root user
- A [Caddy](https://caddyserver.com/) server bundling multiple plugins and the possibility to run against port 80 and 443 as non-root user
- A minimal act runner environment with Python 3 installed
- A modified [Homebridge](https://homebridge.io) version that has already a couple of plugins build in so it can be run in a read-only filesystem with a non-root user on privileged ports.
- A custom [Node-RED](https://nodered.org) version that has already a couple of plugins build in so it can be run in a read-only filesystem with a non-root user on privileged ports.
- A [Uptime Kuma](https://uptime.kuma.pet) version that allows running the services on port 80 and 443 as non-root user.

## Scripts

Some scripts that automate frequently conducted tasks.

## Setup

The tooling and the tasks of this repository are defined in [`mise.toml`](mise.toml); the tools are locked with their
checksums in [`mise.lock`](mise.lock). Install [mise](https://mise.jdx.dev) (on macOS: `brew install mise`), then set up
the repository:

```shell
# installs the tools and the git hooks
mise run init
# only to build the snaps: installs snapcraft and multipass with brew (macOS only; on other operating systems install
# these manually)
mise run install:snap
```

The pre-commit hook formats the changed files with oxfmt and runs `mise run check:actions` for changed workflows.

## Development

For a list of available tasks, run `mise tasks` within the Git repository. `mise run check` runs the checks of the CI
locally: formatting, Markdown, Dockerfiles, EditorConfig and secrets; it lints and audits the workflows (actionlint,
zizmor) and tests the CI scripts. `mise run commit <type> <message> [scope]` creates a conventional commit with
[cocogitto](https://docs.cocogitto.io); the commit-msg hook verifies the commit messages with it as well.

Pull requests merge only with green required checks; `CI Gate` aggregates the jobs of the Docker CI, so its matrix can
change without touching the branch protection.

`mise run ci` runs the GitHub Actions CI flow locally with [act](https://github.com/nektos/act).
