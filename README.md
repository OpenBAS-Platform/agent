# OpenBAS agent

[![Website](https://img.shields.io/badge/website-openbas.io-blue.svg)](https://openbas.io)
[![Slack Status](https://img.shields.io/badge/slack-3K%2B%20members-4A154B)](https://community.filigran.io)

The following repository is used to store the OpenBAS agent for the platform.
For performance and low level access, the agent is written in Rust. Please start your journey with https://doc.rust-lang.org/book

## License

**Unless specified otherwise**, agent are released under the Filigran License

## Installation

Installation process will be done through the usage of OpenBAS platform.

### Linux installation

A admin execution is required.

`curl -s http://[OPENBAS_URI]/api/agent/installer/openbas/linux/[OPENBAS_TOKEN] | sudo sh`

### Windows installation

An elevated powershell is required.

`iex (iwr "http://[OPENBAS_URI]/api/agent/installer/openbas/windows/[OPENBAS_TOKEN]").Content`

## About

OpenBAS is a product designed and developed by the company [Filigran](https://filigran.io).

<a href="https://filigran.io" alt="Filigran"><img src="https://github.com/OpenCTI-Platform/opencti/raw/master/.github/img/logo_filigran.png" width="300" /></a>