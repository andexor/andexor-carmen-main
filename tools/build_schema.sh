#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Andexor Network, Inc.
# Author: Ed Jenkins <ed@andexor.net>

# Build every db/carmen/NNNN_name.sql from its .base.sql plus generated SRT triggers (migrations already
# on main are kept as they are), then regenerate the entity-relationship diagrams in doc/uml/.
# Run from the repo root.

set -euo pipefail

python3 tools/build_schema.py
python3 tools/gen_erd.py
