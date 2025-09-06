#!/usr/bin/env bash
# macOS-focused cleaner for stray "$@" module-level directives in TS/TSX
set -euo pipefail

FRONTEND_DIR="frontend"
SRC="$FRONTEND_DIR/src"

[ -d "$SRC" ] || { echo "❌ Not found: $SRC"; exit 1; }

echo "→ Scanning $SRC for TS/TSX files…"
# На macOS вместо mapfile используем обычный массив через while/read
FILES=()
while IFS= read -r -d '' f; do
  FILES+=("$f")
done < <(find "$SRC" -type f \( -name '*.ts' -o -name '*.tsx' \) -print0 | sort -z)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "⚠️  No TS/TSX files found under $SRC"
  exit 0
fi

CHANGED=()

# Регекс для строки, содержащей только $@ (в любых кавычках/пробелах)
REGEX='^[\p{Space}\x{FEFF}\x{200B}-\x{200D}\x{202F}\x{2060}]*[\"'\''`“”„«»′″’‘]*\s*\$@\s*[\"'\''`“”„«»′″’‘]*[\p{Space}\x{200B}-\x{200D}\x{202F}\x{2060}]*\R?$'

echo "→ Cleaning stray directives…"
for f in "${FILES[@]}"; do
  BEFORE_SHA="$(shasum "$f" | awk '{print $1}')"

  # 1) remove BOM
  perl -i -pe 'binmode(STDIN, ":utf8"); binmode(STDOUT, ":utf8"); s/^\x{FEFF}//;' "$f"

  # 2) normalize CRLF → LF
  perl -i -pe 's/\r\n/\n/g' "$f"

  # 3) drop lines with only $@-variants
  perl -CSD -0777 -i -pe '
    use utf8;
    my $rx = q{'"$REGEX"'};
    my @out;
    for my $line (split /\n/, $_, -1) {
      my $test = $line . "\n";
      if ($test =~ /$rx/uo) { next; }
      push @out, $line;
    }
    $_ = join("\n", @out);
  ' "$f"

  AFTER_SHA="$(shasum "$f" | awk '{print $1}')"
  if [ "$BEFORE_SHA" != "$AFTER_SHA" ]; then
    CHANGED+=("$f")
  fi
done

if [ "${#CHANGED[@]}" -gt 0 ]; then
  echo "✅ Modified files (${#CHANGED[@]}):"
  printf ' - %s\n' "${CHANGED[@]}"
else
  echo "✅ Nothing to change — already clean."
fi

echo "→ Verifying there are no remaining lines with only $@…"
if grep -R --line-number -E '^[[:space:]]*("\$@"|'\''\$@'\''|`\$@`|\$@)[[:space:]]*$' "$SRC" >/dev/null 2>&1; then
  echo "❌ Still found suspicious lines:"
  grep -R --line-number -E '^[[:space:]]*("\$@"|'\''\$@'\''|`\$@`|\$@)[[:space:]]*$' "$SRC" || true
  exit 2
else
  echo "✅ No stray $@ directives remain."
fi

echo "→ Building frontend…"
( cd "$FRONTEND_DIR" && npm run build )

echo "🎯 Done."