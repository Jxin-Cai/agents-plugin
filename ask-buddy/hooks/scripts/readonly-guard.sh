#!/bin/bash
# ask-buddy read-only guard
# Blocks Write/Edit/NotebookEdit unless targeting .ask-buddy/ directory

input=$(cat)

file_path=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('file_path') or data.get('notebook_path') or '')
except:
    print('')
" 2>/dev/null)

if [ -z "$file_path" ]; then
  echo "ask-buddy 是只读模式，不允许写入操作。如需修改请切换到其他工具。"
  exit 2
fi

if echo "$file_path" | grep -qE '(^|/)\.ask-buddy/'; then
  exit 0
fi

echo "ask-buddy 是只读模式，只允许输出到 .ask-buddy/ 目录。如需修改源码请切换到其他工具。"
exit 2
