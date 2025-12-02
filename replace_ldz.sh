#!/bin/bash

DIR="."

find "$DIR" -type f -print0 | while IFS= read -r -d '' file; do
    sed -i '' 's/lodz\.rb/alexscript\.rb/g' "$file"
done