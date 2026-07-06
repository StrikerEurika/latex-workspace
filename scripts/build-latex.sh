#!/bin/bash
set -e

DOC="$1"
WORKSPACE="$2"
MODE="$3"

if [[ ! -f "$DOC" && -f "$DOC.tex" ]]; then
  DOC="$DOC.tex"
fi

DOC_DIR="$(dirname "$DOC")"
DOC_FILE="$(basename "$DOC")"
DOC_BASE="${DOC_FILE%.tex}"

PROJECT_NAME="$(basename "$DOC_DIR")"

OUTDIR="$WORKSPACE/build/$PROJECT_NAME"

mkdir -p "$OUTDIR"

cd "$DOC_DIR"

echo "================================================="
echo "Building project: $PROJECT_NAME"
echo "Source: $DOC_FILE"
echo "Output: $OUTDIR"
echo "Mode: $MODE"
echo "================================================="

XELATEX="${XELATEX:-xelatex}"
BIBER="${BIBER:-biber}"

echo "Using XeLaTeX: $(command -v "$XELATEX" || echo "$XELATEX not found")"
echo "Using Biber: $(command -v "$BIBER" || echo "$BIBER not found")"

if [[ "$MODE" == "fast" ]]; then
  "$XELATEX" \
    -interaction=nonstopmode \
    -halt-on-error \
    -synctex=1 \
    -shell-escape \
    -output-directory="$OUTDIR" \
    "$DOC_FILE"
else
  "$XELATEX" \
    -interaction=nonstopmode \
    -halt-on-error \
    -synctex=1 \
    -shell-escape \
    -output-directory="$OUTDIR" \
    "$DOC_FILE"

  "$BIBER" \
    --input-directory="$OUTDIR" \
    --output-directory="$OUTDIR" \
    "$DOC_BASE" || true

  "$XELATEX" \
    -interaction=nonstopmode \
    -halt-on-error \
    -synctex=1 \
    -shell-escape \
    -output-directory="$OUTDIR" \
    "$DOC_FILE"

  "$XELATEX" \
    -interaction=nonstopmode \
    -halt-on-error \
    -synctex=1 \
    -shell-escape \
    -output-directory="$OUTDIR" \
    "$DOC_FILE"
fi

echo "Done: $OUTDIR/$DOC_BASE.pdf"