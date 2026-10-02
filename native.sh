#!/bin/bash

set -e

BUILD_DIR="build"
OUTPUT_JAR="lwjgl-natives.jar"

cd "$BUILD_DIR"
jar cf "../$OUTPUT_JAR" ./android
cd ..

echo "Package finish: $OUTPUT_JAR"
