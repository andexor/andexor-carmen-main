#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Andexor Network, Inc.
# Author: Ed Jenkins <ed@andexor.net>

# Installs or upgrades the Cloudflare CLI (cf) with npm. Requires Node.js (see setup.md).

set -euo pipefail

npm install -g cf@latest

echo "cf $(cf --version) installed"
