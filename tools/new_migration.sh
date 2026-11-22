#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Andexor Network, Inc.
# Author: Ed Jenkins <ed@andexor.net>

# Create the next numbered migration file. Usage: ./tools/new_migration.sh short_name
# Run from the repo root.

set -euo pipefail

name=${1:?usage: ./tools/new_migration.sh short_name}
[[ $name =~ ^[a-z0-9_]+$ ]] || { echo "Use lowercase letters, digits, and underscores only." >&2; exit 1; }

last=$(ls db/carmen/[0-9][0-9][0-9][0-9]_*.base.sql | sed 's|.*/\([0-9]*\)_.*|\1|' | sort | tail -1)
file=db/carmen/$(printf '%04d' $((10#$last + 1)))_${name}.base.sql

cat > "$file" <<SQL
-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: ${name}.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

SQL
echo "Created $file"
