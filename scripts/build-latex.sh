#!/bin/bash
set -e

# Usage: build-latex.shproject-name|path-to-main.tex|path-to-project-dir> [workspace] [mode] [clean]
# Mode: 'incremental' (default), 'fast', 'watch' (auto-compile on changes), or 'clean' to force rebuild

DOC_ARG="$1"
WORKSPACE="${2:-/workspace}"
MODE="${3:-incremental}"
CLEAN="$4"

# Handle input paths
if [[ -f "$DOC_ARG" ]]; then
  DOC="$DOC_ARG"
elif [[ -d "$DOC_ARG" ]]; then
  DOC="$DOC_ARG/main.tex"
elif [[ -d "$WORKSPACE/src/$DOC_ARG" ]]; then
  DOC="$WORKSPACE/src/$DOC_ARG/main.tex"
elif [[ -f "$WORKSPACE/src/$DOC_ARG/main.tex" ]]; then
  DOC="$WORKSPACE/src/$DOC_ARG/main.tex"
else
  echo "Error: Could not find main.tex for project '$DOC_ARG'"
  echo "Usage: $0project-name|path-to-main.tex|path-to-project-dir> [workspace] [mode] [clean]"
  echo "Mode: 'incremental' (default), 'fast', 'watch' (auto-compile on changes), or 'clean' to force rebuild"
  exit 1
fi

DOC_DIR="$(dirname "$DOC")"
DOC_BASE="${DOC_FAKEFILENAME%.tex}"
PROJECT_NAME="$(basename "$DOC_DIR")"
OUTDIR="$WORKSPACE/build/$PROJECT_NAME"

# Clean build if requested
if [[ "$CLEAN" == "clean" ]] || [[ "$MODE" == "clean" ]]; then
  echo "Clean build: removing output directory"
  rm -rf "$OUTDIR"
fi

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

build_pdf() {
  echo "-------------------------------------------------"
  echo "Building at $(date)"
  "$XELATEX" \
    -interaction=nonstopmode \
    -halt-on-error \
    -synctex=1 \
    -shell-escape \
    -aux-directory="$OUTDIR" \
    -output-directory="$OUTDIR" \
    "$DOC" || exit 1

  "$BIBER" \
    --input-directory="$OUTDIR" \
    --output-directory="$OUTDIR" \
    "$DOC_BASE" || true

  "$XELATEX" \
    -interaction=nonstopmode \
    -halt-on-error \
    -synctex=1 \
    -shell-escape \
    -aux-directory="$OUTDIR" \
    -output-directory="$OUTDIR" \
    "$DOC" || exit 1

  "$XELATEX" \
    -interaction=nonstopmode \
    -halt-on-error \
    -synctex=1 \
    -shell-escape \
    -aux-directory="$OUTDIR" \
    -output-directory="$OUTDIR" \
    "$DOC" || exit 1
}

# Build PDF
if [[ "$MODE" == "watch" ]]; then
  echo "Starting watch mode. Press Ctrl+C to stop."
  echo "Watching for changes in: $DOC_DIR"
  
  # Build once first
  build_pdf
  
  # Watch for changes
  while true; do
    # Wait a moment for file system to settle
    sleep 1
    
    # Check if any relevant files have been modified
    if find "$DOC_DIR" -type f \( -name "*.tex" -o -name "*.bib" -o -name "*.sty" -o -name "*.cls" \) -newer "$OUTDIR/watchmarker" 2>/dev/null | grep -q .; then
      # Update the watch marker timestamp
      touch "$OUTDIR/watchmarker" 2>/dev/null || mkdir -p "$OUTDIR" && touch "$OUTDIR/watchmarker"
      
      echo ""
      echo "Detected file changes. Rebuilding..."
      build_pdf
    fi
  done
else
  build_pdf
fi

echo "Done: $OUTDIR/$DOC_BASE.pdf"