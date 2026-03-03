# LeanArchitect: End-to-End Guide

This guide walks through building a minimal Lean project that uses
LeanArchitect and leanblueprint to produce an interactive web blueprint
with a dependency graph.

## Prerequisites

- **elan** (Lean version manager): https://github.com/leanprover/elan
- **Python 3.12+**
- **graphviz** system library (for the dependency graph):
  ```sh
  sudo apt install graphviz libgraphviz-dev
  ```

## 1. Create the project skeleton

```sh
mkdir -p LeanArchitectExample/Example
cd LeanArchitectExample
```

### lean-toolchain

Pin the Lean version (must match what LeanArchitect expects):

```
leanprover/lean4:v4.29.0-rc3
```

### lakefile.lean

Declare the project, pull in LeanArchitect, and define a library target
covering all files under `Example/`:

```lean
import Lake
open Lake DSL

package ExampleProject

require LeanArchitect from git
  "https://github.com/hanwenzhu/LeanArchitect.git" @ "main"

@[default_target]
lean_lib Example where
  globs := #[.submodules `Example]
```

### Example.lean

Root module that re-exports the two sub-modules:

```lean
import Example.F1
import Example.F2
```

## 2. Write the Lean source files

### Example/F2.lean — base definitions

```lean
import Architect

@[blueprint "def:double"
  (statement := /-- Doubles a natural number by adding it to itself. -/)]
def double (n : Nat) : Nat := n + n

@[blueprint "thm:double-zero"
  (statement := /-- Doubling zero yields zero. -/)]
theorem double_zero : double 0 = 0 := by rfl
```

### Example/F1.lean — theorems that depend on F2

```lean
import Architect
import Example.F2

@[blueprint "thm:double-succ"
  (statement := /-- Doubling a successor: $\text{double}(n+1) = \text{double}(n) + 2$. -/)]
theorem double_succ (n : Nat) : double (n + 1) = double n + 2 := by
  unfold double; omega

@[blueprint "thm:double-pos"
  (statement := /-- Doubling a positive number is positive. -/)]
theorem double_pos (n : Nat) (h : n > 0) : double n > 0 := by
  unfold double; omega
```

Key points:
- `import Architect` makes the `@[blueprint]` attribute available.
- The string `"def:double"` becomes the LaTeX label.
- The `statement` option provides the human-readable LaTeX description.
- Dependencies (e.g. `double_succ` uses `double`) are inferred automatically.

## 3. Fetch dependencies and build

```sh
lake update          # fetch LeanArchitect, batteries, Cli
lake build           # compile all Lean code
lake build :blueprint  # extract .tex fragments to .lake/build/blueprint/
```

After `lake build :blueprint`, the generated files are:

```
.lake/build/blueprint/
├── library/Example.tex              # index file that \input's all modules
└── module/Example/
    ├── F1.tex                       # module-level macros for F1
    ├── F1.artifacts/
    │   ├── thm:double-succ.tex      # individual node
    │   └── thm:double-pos.tex
    ├── F2.tex                       # module-level macros for F2
    └── F2.artifacts/
        ├── def:double.tex
        └── thm:double-zero.tex
```

Each artifact file contains the leanblueprint LaTeX commands (`\uses`,
`\lean`, `\leanok`, etc.) that were inferred from the Lean source.

## 4. Set up leanblueprint

### Install leanblueprint in a virtual environment

```sh
python3 -m venv .venv
source .venv/bin/activate
pip install leanblueprint
```

### Initialize a git repo (leanblueprint requires one)

```sh
git init
```

### Create the blueprint directory structure

```sh
mkdir -p blueprint/src/macros
```

### blueprint/src/macros/common.tex

Theorem-like environments shared by both PDF and web targets:

```latex
\usepackage{cleveref}

\newtheorem{theorem}{Theorem}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{corollary}[theorem]{Corollary}

\theoremstyle{definition}
\newtheorem{definition}[theorem]{Definition}
```

### blueprint/src/macros/print.tex

Dummy macros so the PDF compiler ignores web-only commands:

```latex
\newcommand{\lean}[1]{}
\newcommand{\discussion}[1]{}
\newcommand{\leanok}{}
\newcommand{\mathlibok}{}
\newcommand{\notready}{}
\ExplSyntaxOn
\NewDocumentCommand{\uses}{m}
 {\clist_map_inline:nn{#1}{\vphantom{\ref{##1}}}%
 \ignorespaces}
\NewDocumentCommand{\proves}{m}
 {\clist_map_inline:nn{#1}{\vphantom{\ref{##1}}}%
 \ignorespaces}
\ExplSyntaxOff
```

### blueprint/src/macros/web.tex

Empty (web macros are provided by the leanblueprint plugin):

```latex
% Macros for web version only.
```

### blueprint/src/web.tex

Top-level document for the web build:

```latex
\documentclass{report}

\usepackage{amssymb, amsthm, amsmath}
\usepackage{hyperref}
\usepackage[showmore, dep_graph]{blueprint}

\input{macros/common}
\input{macros/web}

\title{Example Blueprint}
\author{LeanArchitect Demo}

\begin{document}
\maketitle
\input{content}
\end{document}
```

### blueprint/src/print.tex

Top-level document for the PDF build (requires xelatex):

```latex
\documentclass[a4paper]{report}

\usepackage{geometry}
\usepackage{expl3}
\usepackage{amssymb, amsthm, mathtools}
\usepackage[unicode,colorlinks=true,linkcolor=blue,urlcolor=magenta,citecolor=blue]{hyperref}
\usepackage[warnings-off={mathtools-colon,mathtools-overbracket}]{unicode-math}

\input{macros/common}
\input{macros/print}

\title{Example Blueprint}
\author{LeanArchitect Demo}

\begin{document}
\maketitle
\input{content}
\end{document}
```

### blueprint/src/content.tex

The actual content — this is where the LeanArchitect output gets wired in:

```latex
\input{../../.lake/build/blueprint/library/Example}

\chapter{Double}

\inputleanmodule{Example.F2}

\inputleanmodule{Example.F1}
```

The `\input` line loads the generated macros (`\inputleannode`,
`\inputleanmodule`). Then `\inputleanmodule{Example.F2}` expands into
all the `@[blueprint]`-tagged nodes from that Lean module, in source order.

### blueprint/src/plastex.cfg

Configuration for the plasTeX renderer:

```ini
[general]
renderer=HTML5
copy-theme-extras=yes
plugins=plastexdepgraph plastexshowmore leanblueprint

[document]
toc-depth=3
toc-non-files=True

[files]
directory=../web/
split-level= 0

[html5]
localtoc-level=0
extra-css=extra_styles.css
mathjax-dollars=False
```

### blueprint/src/extra_styles.css

Optional CSS for nicer theorem styling:

```css
div.theorem_thmcontent {
 border-left: .15rem solid black;
}

div.definition_thmcontent {
 border-left: .15rem solid black;
}

div.proof_content {
 border-left: .08rem solid grey;
}
```

### blueprint/src/latexmkrc

Configuration for `latexmk` (PDF build):

```perl
$pdf_mode = 1;
$pdflatex = 'xelatex -synctex=1';
@default_files = ('print.tex');
```

### blueprint/src/blueprint.sty

Stub package file:

```latex
\DeclareOption*{}
\ProcessOptions
```

### blueprint/lean_decls

List of Lean declaration names (used by `leanblueprint checkdecls`):

```
double
double_zero
double_succ
double_pos
```

## 5. Build the web blueprint

```sh
source .venv/bin/activate
leanblueprint web
```

This generates `blueprint/web/` containing the full HTML site.

## 6. View the result

```sh
leanblueprint serve
```

Then open in your browser:

- **http://localhost:8000/** — chapter page with definitions and theorems
- **http://localhost:8000/dep_graph_document.html** — interactive dependency graph

The graph shows:

```
        ┌────────┐
        │ double │      (definition, green box)
        └───┬────┘
       ╱    │    ╲
      ▼     ▼     ▼
  ┌──────┐ ┌──────┐ ┌──────┐
  │zero  │ │succ  │ │pos   │   (theorems, green ellipses)
  └──────┘ └──────┘ └──────┘
```

All nodes are dark green because every declaration is sorry-free (`\leanok`).

## Summary of commands

```sh
# One-time setup
mkdir -p LeanArchitectExample/Example
cd LeanArchitectExample
# ... create all files above ...
python3 -m venv .venv
source .venv/bin/activate
pip install leanblueprint
git init

# Build pipeline (repeat after changing Lean source)
lake update
lake build
lake build :blueprint
leanblueprint web
leanblueprint serve
```
