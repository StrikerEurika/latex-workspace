# Multi-Project LaTeX Workspace

This repository is a reusable LaTeX workspace designed to manage multiple LaTeX projects in one clean structure.

The main idea is to keep all source files inside the `src/` folder and automatically generate compiled outputs inside the `build/` folder based on the project name.

For example:

```text
src/thesis/main.tex  →  build/thesis/main.pdf
src/slide/main.tex   →  build/slide/main.pdf
src/report/main.tex  →  build/report/main.pdf
```

This structure is useful for managing thesis documents, presentation slides, reports, papers, proposals, or any other LaTeX-based documents in the same workspace.

---

## Purpose

The purpose of this workspace is to provide a clean and scalable LaTeX project structure that supports:

* Multiple LaTeX projects in one repository.
* Separate source folders for each project.
* Separate build folders for each output.
* VS Code LaTeX Workshop integration.
* Docker-compatible LaTeX compilation.
* Reusable build scripts.
* Better organization of figures, chapters, sections, references, and style files.

Instead of keeping everything in the project root, each LaTeX project is placed inside its own folder under `src/`.

---

## General Structure

```text
project-root/
├── README.md
├── build/
│   ├── thesis/
│   ├── slide/
│   └── report/
│
├── scripts/
│   └── build-latex.sh
│
├── src/
│   ├── thesis/
│   │   ├── main.tex
│   │   ├── references.bib
│   │   ├── thesisstyle.sty
│   │   ├── chapters/
│   │   ├── frontmatter/
│   │   ├── appendices/
│   │   └── figures/
│   │
│   ├── slide/
│   │   ├── main.tex
│   │   ├── slidestyle.sty
│   │   ├── sections/
│   │   └── figures/
│   │
│   └── report/
│       ├── main.tex
│       ├── sections/
│       ├── figures/
│       └── references.bib
│
├── .vscode/
└── .devcontainer/
```

---

## Main Idea

Each folder inside `src/` represents one LaTeX project.

For example:

```text
src/thesis/
src/slide/
src/report/
```

Each project should have its own `main.tex` file.

The build system detects the project folder name and sends the output to the matching folder inside `build/`.

Example:

```text
src/thesis/main.tex
```

outputs to:

```text
build/thesis/main.pdf
```

and:

```text
src/slide/main.tex
```

outputs to:

```text
build/slide/main.pdf
```

This keeps the workspace clean and avoids mixing generated files with source files.

---

## Source Folder

The `src/` folder contains all editable LaTeX source files.

Each subfolder inside `src/` should represent one document project.

Example:

```text
src/
├── thesis/
├── slide/
└── report/
```

Recommended contents for a thesis project:

```text
src/thesis/
├── main.tex
├── references.bib
├── thesisstyle.sty
├── settings/
├── frontmatter/
├── chapters/
├── appendices/
└── figures/
```

Recommended contents for a slide project:

```text
src/slide/
├── main.tex
├── slidestyle.sty
├── sections/
└── figures/
```

---

## Build Folder

The `build/` folder contains generated files only.

Do not manually edit files inside `build/`.

Example:

```text
build/
├── thesis/
│   ├── main.pdf
│   ├── main.aux
│   ├── main.log
│   └── ...
│
└── slide/
    ├── main.pdf
    ├── main.aux
    ├── main.log
    └── ...
```

The final PDFs are usually:

```text
build/thesis/main.pdf
build/slide/main.pdf
```

---

## Build Script

The workspace uses a general build script:

```text
scripts/build-latex.sh
```

The script receives three inputs:

```text
document path
workspace path
build mode
```

Example:

```bash
./scripts/build-latex.sh "$PWD/src/thesis/main.tex" "$PWD" full
```

The script detects the folder name inside `src/` and builds to the matching folder inside `build/`.

Recommended script:

```bash
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
```

Make the script executable:

```bash
chmod +x scripts/build-latex.sh
```

---

## Build Modes

The build script supports two modes.

### Fast Mode

Fast mode runs XeLaTeX once.

Use it when editing normal text, figures, or layout:

```bash
./scripts/build-latex.sh "$PWD/src/thesis/main.tex" "$PWD" fast
```

### Full Mode

Full mode runs:

```text
xelatex → biber → xelatex → xelatex
```

Use it when updating:

* References.
* Citations.
* Table of contents.
* List of figures.
* List of tables.
* Cross-references.

Example:

```bash
./scripts/build-latex.sh "$PWD/src/thesis/main.tex" "$PWD" full
```

---

## VS Code Setup

This workspace is designed to work with the **LaTeX Workshop** extension in VS Code.

Recommended `.vscode/settings.json`:

```json
{
  "latex-workshop.latex.autoBuild.run": "onFileChange",

  "latex-workshop.latex.autoBuild.interval": 1000,

  "latex-workshop.latex.outDir": "%WORKSPACE_FOLDER%/build",

  "latex-workshop.latex.autoBuild.onSave.files.ignore": [],
  "latex-workshop.latex.rootFile.useSubFile": false,

  "latex-workshop.latex.recipe.default": "general: xelatex + biber",

  "latex-workshop.latex.recipes": [
    {
      "name": "general: xelatex + biber",
      "tools": [
        "general-full"
      ]
    },
    {
      "name": "general: xelatex fast",
      "tools": [
        "general-fast"
      ]
    }
  ],

  "latex-workshop.latex.tools": [
    {
      "name": "general-full",
      "command": "/bin/bash",
      "args": [
        "%WORKSPACE_FOLDER%/scripts/build-latex.sh",
        "%DOC%",
        "%WORKSPACE_FOLDER%",
        "full"
      ],
      "env": {}
    },
    {
      "name": "general-fast",
      "command": "/bin/bash",
      "args": [
        "%WORKSPACE_FOLDER%/scripts/build-latex.sh",
        "%DOC%",
        "%WORKSPACE_FOLDER%",
        "fast"
      ],
      "env": {}
    }
  ],

  "latex-workshop.view.pdf.viewer": "tab",
  "latex-workshop.synctex.afterBuild.enabled": true,

  "latex-workshop.formatting.latex": "latexindent",
  "latex-workshop.latex.autoClean.run": "never",

  "latex-workshop.intellisense.package.enabled": true,

  "[latex]": {
    "editor.formatOnSave": false,
    "editor.wordWrap": "on",
    "editor.rulers": [100]
  }
}
```

---

## How to Build in VS Code

Open the workspace root folder in VS Code.

Example:

```bash
code .
```

Then open the `main.tex` file of the project you want to build.

Examples:

```text
src/thesis/main.tex
src/slide/main.tex
src/report/main.tex
```

Then run:

```text
Cmd + Shift + P
→ LaTeX Workshop: Build with recipe
→ general: xelatex + biber
```

For fast drafting:

```text
Cmd + Shift + P
→ LaTeX Workshop: Build with recipe
→ general: xelatex fast
```

---

## How to Build from Terminal

From the workspace root:

```bash
cd project-root
```

### Essential Commands for `ngt`

Run these commands from the workspace root (`/workspace`):

```bash
# Make the build script executable (first time only)
chmod +x scripts/build-latex.sh

# Fast build for normal text and layout changes
./scripts/build-latex.sh "$PWD/src/ngt/main.tex" "$PWD" "$PWD/build/ngt" fast

# Full build with bibliography and cross-references
./scripts/build-latex.sh "$PWD/src/ngt/main.tex" "$PWD" "$PWD/build/ngt" full

# Clean rebuild after a terminated or broken build
./scripts/build-latex.sh "$PWD/src/ngt/main.tex" "$PWD" "$PWD/build/ngt" full clean

# Open the generated PDF
xdg-open build/ngt/main.pdf
```

The generated document is located at `build/ngt/main.pdf`.

Build a thesis project:

```bash
./scripts/build-latex.sh "$PWD/src/thesis/main.tex" "$PWD" full
```

Build a slide project:

```bash
./scripts/build-latex.sh "$PWD/src/slide/main.tex" "$PWD" fast
```

Build another project:

```bash
./scripts/build-latex.sh "$PWD/src/report/main.tex" "$PWD" full
```

---

## Docker Support

This workspace can be used inside Docker or a VS Code Dev Container.

The build script does not hard-code macOS paths such as:

```text
/Library/TeX/texbin/xelatex
```

Instead, it uses:

```bash
XELATEX="${XELATEX:-xelatex}"
BIBER="${BIBER:-biber}"
```

This makes the build system portable across:

* macOS
* Linux
* Docker
* VS Code Dev Containers

---

## Docker Dependencies

For a Debian or Ubuntu-based Docker image, install the following packages:

```dockerfile
RUN apt-get update && apt-get install -y \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-other \
    biber \
    latexmk \
    python3-pygments \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*
```

`python3-pygments` is required when using the LaTeX package `minted`.

---

## Recommended LaTeX Project Pattern

Each project should have one main file:

```text
main.tex
```

The main file should load smaller files using `\input`.

Example:

```latex
\documentclass{report}

\usepackage{thesisstyle}
\addbibresource{references.bib}

\begin{document}

\input{frontmatter/01_cover}
\input{chapters/ch1_introduction}
\input{chapters/ch2_methodology}

\printbibliography

\end{document}
```

For slides:

```latex
\documentclass{beamer}

\usepackage{slidestyle}

\title{Presentation Title}
\author{Author Name}

\begin{document}

\begin{frame}
    \titlepage
\end{frame}

\input{sections/01_introduction}
\input{sections/02_methodology}

\end{document}
```

---

## Root Comments for Subfiles

For better root detection in VS Code, add this line at the top of subfiles:

```latex
% !TEX root = ../main.tex
```

Example:

```latex
% !TEX root = ../main.tex

\chapter{Introduction}

Content here.
```

Use this for files inside:

```text
chapters/
frontmatter/
appendices/
sections/
```

---

## Recommended Editing Workflow

For normal editing:

1. Open the workspace root in VS Code.
2. Edit the relevant file inside `src/{project-name}/`.
3. Build using the general recipe.
4. Check the generated PDF inside `build/{project-name}/`.
5. Avoid editing generated files inside `build/`.

Example workflow for thesis:

```text
Edit:   src/thesis/chapters/ch1_introduction.tex
Build:  src/thesis/main.tex
Check:  build/thesis/main.pdf
```

Example workflow for slides:

```text
Edit:   src/slide/sections/01_intro.tex
Build:  src/slide/main.tex
Check:  build/slide/main.pdf
```

---

## Best Practices

Use this workspace with the following habits:

* Keep source files inside `src/`.
* Keep generated files inside `build/`.
* Use one folder per LaTeX project.
* Use one `main.tex` per project.
* Use `fast` build for quick edits.
* Use `full` build before final submission.
* Do not manually edit files in `build/`.
* Do not compile chapter or section files directly.
* Keep figures inside the related project folder.
* Keep formatting commands inside a `.sty` file.
* Keep project metadata in a separate file when needed.
* Use clear labels for figures, tables, equations, and sections.

---

## Example Output

After building, the workspace may look like this:

```text
build/
├── thesis/
│   ├── main.pdf
│   ├── main.aux
│   ├── main.bbl
│   ├── main.log
│   └── ...
│
├── slide/
│   ├── main.pdf
│   ├── main.aux
│   ├── main.log
│   └── ...
│
└── report/
    ├── main.pdf
    ├── main.aux
    ├── main.bbl
    ├── main.log
    └── ...
```

Only the PDF files are usually needed for reading or submission. The other files are generated by LaTeX and can be cleaned or ignored when needed.

---

## Final Notes

This workspace is intended to make LaTeX project management cleaner and easier.

The key principle is simple:

```text
src/{project-name}/main.tex → build/{project-name}/main.pdf
```

By following this pattern, multiple LaTeX documents can be managed in one repository without mixing source files, generated files, figures, references, and outputs.
