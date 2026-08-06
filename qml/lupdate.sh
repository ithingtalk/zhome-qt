#!/bin/bash

TS_FILES=$(find . -type f -name "*.ts")
for TS_FILE in $TS_FILES; do
    BASENAME=$(basename "$TS_FILE")
    echo "Updating $BASENAME..."
    lupdate . -ts "$TS_FILE"
done

echo "All .ts files have been updated."
