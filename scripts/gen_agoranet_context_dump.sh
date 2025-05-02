#!/usr/bin/env bash

# File: scripts/gen_agoranet_context_dump.sh
# Purpose: Generate a comprehensive context dump for LLM integration (e.g., Cursor, ChatGPT)
# Target: AgoraNet Repository

OUTPUT_FILE="llm_context_dump_agoranet.txt"
TIMESTAMP=$(date)

echo "Generating Comprehensive LLM context dump in $OUTPUT_FILE..."
echo "Repository Root: $(pwd)" > $OUTPUT_FILE
echo "Timestamp: $TIMESTAMP" >> $OUTPUT_FILE
echo "========================================" >> $OUTPUT_FILE

# File Inclusion/Exclusion Rules
echo "Included File Types: *.rs *.toml *.md *.json *.yml *.ts *.tsx *.sh .gitignore LICENSE* README* .editorconfig .eslintrc.js" >> $OUTPUT_FILE
echo "Excluded Dirs: ./.git ./target ./.vscode ./.idea ./.cursor_journal ./node_modules ./build" >> $OUTPUT_FILE
echo "Excluded Files: ./Cargo.lock yarn.lock package-lock.json" >> $OUTPUT_FILE
echo "========================================" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# List and concatenate matching files into the output
find . \
  -type f \
  \( -name "*.rs" -o -name "*.toml" -o -name "*.md" -o -name "*.json" -o -name "*.yml" -o -name "*.ts" -o -name "*.tsx" -o -name "*.sh" -o -name ".gitignore" -o -name "LICENSE*" -o -name "README*" -o -name ".editorconfig" -o -name ".eslintrc.js" \) \
  ! -path "./.git/*" ! -path "./target/*" ! -path "./.vscode/*" ! -path "./.idea/*" ! -path "./.cursor_journal/*" ! -path "./node_modules/*" ! -path "./build/*" \
  ! -name "Cargo.lock" ! -name "yarn.lock" ! -name "package-lock.json" \
  | sort | while read file; do
    echo "--- File: $file ---" >> $OUTPUT_FILE
    cat "$file" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
  done

echo "✅ AgoraNet LLM context dump written to $OUTPUT_FILE"
