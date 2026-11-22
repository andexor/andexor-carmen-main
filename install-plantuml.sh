#!/bin/bash

set -euo pipefail

# Adapted from https://plantuml.com/en-dark/download

# NOTE: If you have not done so already, install Java first.
# See setup.md for details.

# NOTE: You should periodically check the website mentioned above for updates.
# Once per year should be often enough.
# If a newer version is available,
# you may want to update the PLANTUML_VERSION variable
# and run this script to download it.
# Then be sure to update plantuml.sh and VS Code to match.

mkdir -p .tools
PLANTUML_VERSION=1.2026.10
# SHA-256 of the jar for the version above. Update both together.
PLANTUML_SHA256=30a66b81a16127fd3ec560992f31964fe9ae3f1233c614ef4558a4558a21489e
JAR=./.tools/plantuml-mit-${PLANTUML_VERSION}.jar

curl -fL -o "${JAR}" "https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-mit-${PLANTUML_VERSION}.jar"
echo "${PLANTUML_SHA256}  ${JAR}" | sha256sum -c -
