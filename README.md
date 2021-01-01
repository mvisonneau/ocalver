# 🏷 ocalver - Opinionated CalVer generator

[![PkgGoDev](https://pkg.go.dev/badge/github.com/mvisonneau/ocalver)](https://pkg.go.dev/mod/github.com/mvisonneau/ocalver)
[![Go Report Card](https://goreportcard.com/badge/github.com/mvisonneau/ocalver)](https://goreportcard.com/report/github.com/mvisonneau/ocalver)
[![Docker Pulls](https://img.shields.io/docker/pulls/mvisonneau/ocalver.svg)](https://hub.docker.com/r/mvisonneau/ocalver/)
[![Build Status](https://cloud.drone.io/api/badges/mvisonneau/ocalver/status.svg)](https://cloud.drone.io/mvisonneau/ocalver)
[![Coverage Status](https://coveralls.io/repos/github/mvisonneau/ocalver/badge.svg?branch=main)](https://coveralls.io/github/mvisonneau/ocalver?branch=main)

`ocalver` generates strings/versions based on the status of a git repository and the current date. I attempted to get a format which is [SemVer 2.x](https://semver.org/) compliant, although as the [CalVer](https://calver.org/) definition doesn't seem strictly define it implements an opinionated interpretation of it.

## Format

```bash
                                              + YEAR - 2000
                                              |
                                              |  + DAY OF THE YEAR
                                              |  |
                                              |  |   + RELEASE ITERATION / DAY
                                              |  |   |
                                              |  |   | + PRERELEASE KEY (CONFIGURABLE)
     + YEAR - 2000                            |  |   | |
     |                                        |  |   | |  + PRELEASE ITERATION / DAY
     |  + DAY OF THE YEAR                     |  |   | |  |
     |  |                                     |  |   | |  | + PRERELEASE COMMIT HASH
     |  |   + RELEASE ITERATION / DAY         |  |   | |  | |
     +> +-> v                                 +> +-> v +> v +------>
     20.315.0                                 20.315.0-rc.0+5971883a

     ^ RELEASE                                ^ PRERELASE
```

## TL:DR

```bash
~$ date
Tue 10 Nov 2020 15:58:09 GMT

~$ git init
Initialized empty Git repository in /tmp/demo/.git/

~$ touch .gitkeep ; git add . ; git commit -m"init"
[main (root-commit) 5971883] init
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 .gitkeep

~$ git tag $(ocalver)
~$ git tag | cat
20.315.0

~$ ocalver
20.315.1

~$ ocalver -p rc
20.315.1-rc.1+5971883a
```

## Install

### Go

```bash
~$ go get -u github.com/mvisonneau/ocalver/cmd/ocalver
```

### Homebrew

```bash
~$ brew install mvisonneau/tap/ocalver
```

### Docker

```bash
~$ docker run -it --rm docker.io/mvisonneau/ocalver
or
~$ docker run -it --rm ghcr.io/mvisonneau/ocalver
```

### Scoop

```bash
~$ scoop bucket add https://github.com/mvisonneau/scoops
~$ scoop install ocalver
```

### Binaries, DEB and RPM packages

Have a look onto the [latest release page](https://github.com/mvisonneau/ocalver/releases/latest) to pick your flavor and version. Here is an helper to fetch the most recent one:

```bash
~$ export VERSION=$(curl -s "https://api.github.com/repos/mvisonneau/ocalver/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
```

```bash
# Binary (eg: linux/amd64)
~$ wget https://github.com/mvisonneau/ocalver/releases/download/${VERSION}/ocalver_${VERSION}_linux_amd64.tar.gz
~$ tar zxvf ocalver_${VERSION}_linux_amd64.tar.gz -C /usr/local/bin

# DEB package (eg: linux/386)
~$ wget https://github.com/mvisonneau/ocalver/releases/download/${VERSION}/ocalver_${VERSION}_linux_386.deb
~$ dpkg -i ocalver_${VERSION}_linux_386.deb

# RPM package (eg: linux/arm64)
~$ wget https://github.com/mvisonneau/ocalver/releases/download/${VERSION}/ocalver_${VERSION}_linux_arm64.rpm
~$ rpm -ivh ocalver_${VERSION}_linux_arm64.rpm
```

## Usage

```bash
~$ ocalver --help
NAME:
   ocalver - Opinionated CalVer generator

USAGE:
   ocalver [global options] command [command options] [arguments...]

COMMANDS:
   help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --pre pre, -p pre                generates a pre release using the provided value as a key
   --repository-path path, -r path  path where your git repository is available (default: ".")
   --help, -h                       show help (default: false)
```

## Develop / Test

If you use docker, you can easily get started using :

```bash
~$ make dev-env
# You should then be able to use go commands to work onto the project, eg:
~docker$ make fmt
~docker$ ocalver
```

## Contribute

Contributions are more than welcome! Feel free to submit a [PR](https://github.com/mvisonneau/ocalver/pulls).
