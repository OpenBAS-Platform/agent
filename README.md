# OpenBAS agent

[![Website](https://img.shields.io/badge/website-openbas.io-blue.svg)](https://openbas.io)
[![CircleCI](https://circleci.com/gh/OpenBAS-Platform/agent.svg?style=shield)](https://circleci.com/gh/OpenBAS-Platform/agent/tree/master)
[![GitHub release](https://img.shields.io/github/release/OpenBAS-Platform/agent.svg)](https://github.com/OpenBAS-Platform/agent/releases/latest)
[![Slack Status](https://img.shields.io/badge/slack-3K%2B%20members-4A154B)](https://community.filigran.io)

The following repository is used to store the OpenBAS agent for the platform. For performance and low level access, the agent is written in Rust. Please start your journey with https://doc.rust-lang.org/book.

## Installation

Installation process will be done through the usage of OpenBAS platform.

### Linux installation

A admin execution is required.

`curl -s http://[OPENBAS_URI]/api/agent/installer/openbas/linux | sudo sh`

### Windows installation

An elevated powershell is required.

`iex (iwr "http://[OPENBAS_URI]/api/agent/installer/openbas/windows").Content`


## Development

The OpenBAS agent is written in [Rust](https://www.rust-lang.org/). If you're new to Rust, we recommend starting with [The Rust Book](https://doc.rust-lang.org/book/).

### Requirements

- [Rust](https://rustup.rs/) (latest stable)
- [Cargo](https://doc.rust-lang.org/cargo/)
- Linux, macOS or Windows

### Build

To build the agent:

```bash
cargo build
```

## Running Tests

To run all tests (unit and integration):

```bash
cargo test
```

To run one test (unit and integration):

```bash
cargo test test_name
```

### Code Coverage

To generate a code coverage report (requires [`cargo-llvm-cov`](https://github.com/taiki-e/cargo-llvm-cov)):

```bash
cargo install cargo-llvm-cov
cargo llvm-cov --html
```

## About

OpenCTI is a product designed and developed by the company [Filigran](https://filigran.io).

<a href="https://filigran.io" alt="Filigran"><img src="https://github.com/OpenCTI-Platform/opencti/raw/master/.github/img/logo_filigran.png" width="300" /></a>
