#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Andexor Network, Inc.
# Author: Ed Jenkins <ed@andexor.net>

set -euo pipefail

PLANTUML_VERSION=1.2026.10
IMAGES=doc/uml/images

# Render beside the old images and swap only when rendering succeeds, so a failure keeps the old ones.
rm -r -f ${IMAGES}.new
java -jar .tools/plantuml-mit-${PLANTUML_VERSION}.jar -tsvg -o images.new doc/uml/*.puml
rm -r -f ${IMAGES}
mv ${IMAGES}.new ${IMAGES}
