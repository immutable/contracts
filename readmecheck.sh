#!/bin/sh
file_to_find=README.md
parent_dir=contracts
fail=0

find "$parent_dir" -type d |
{ 
  while IFS= read -r subdir; do
    if [ ! -f "$subdir/$file_to_find" ]; then
      echo README.md not found in "$subdir"
      fail=1
    fi
  done

  if [ $fail -eq 1 ]; then
    echo Found at least one directory missing a README.md.
    exit 1
  else
    echo All directories have a README.md file.
    exit 0
  fi
}
