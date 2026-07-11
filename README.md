# tweave

**Write your statistics documents in Typst, with live R code — no Quarto required.**

tweave knits R code chunks embedded in a `.typ` file, then compiles the result straight to PDF. You get Typst's fast, clean typesetting plus reproducible R output: code blocks, console output, plots, and inline values that update every time you build — for analyses, reports, assignments, exams, or anything you'd once have reached for Sweave to write.

It ships with a stats-focused Typst package (also called `tweave`) that provides:

- **Math shorthands** — `iid` (∼ with "iid" above it), `bar(x)` for sample means, `choose(x, y)` for binomial coefficients, hypotheses `H0`/`HA`, upright distribution names (`Normal`, `Poisson`, `Binomial`, …), and differentials `dx`, `dt`, `dtheta`, …
- **Inline R values** — `` `r mean(y)` `` in your prose, auto-rounded (set `digits` in R to control precision) with scientific notation rendered as proper Typst math
- **Sensible defaults** — styled code/output blocks, numbered equations, auto-linked URLs, a title block

tweave deliberately does *not* impose document structure like question numbering, prompt boxes, or point tallies. It composes with any of the templates on [Typst Universe](https://typst.app/universe/) — grape-suite, tinyset, adaptable-pset, and others — or with a few `#let` definitions of your own (the example shows this pattern).

Two examples: [`example1.typ`](examples/example1.typ) ([PDF](examples/example1.knit.pdf)) is a plain homework-style document — the Quarto-parity baseline. [`example2.typ`](examples/example2.typ) ([PDF](examples/example2.knit.pdf)) is the reason to switch: a styled report with a gradient title band, stat cards fed by inline R, running page headers, captioned cross-referenced figures, R-*generated* striped tables (`results='asis'`), a key-finding banner, footnotes, two-column text, and a one-line APA bibliography from a plain `.bib` file — each of which is a few lines of Typst rather than a LaTeX preamble battle.

## How it works

```
yourfile.typ  ──knitr──▶  yourfile.knit.typ  ──typst──▶  yourfile.knit.pdf
```

The `tweave` command runs your document through **knitr** (executing the R chunks and inserting their formatted results), then calls `typst compile` on the result. Under the hood, tweave is an R package — installing it pulls in everything R-side automatically.

---

## Installation

Setup takes about 10 minutes. If anything goes wrong, see [Troubleshooting](#troubleshooting).

**This guide assumes you work in [VS Code](https://code.visualstudio.com/)** — it's free, and it gives you Typst syntax highlighting, a live preview, an R console, and one-keystroke builds, so everything from install to daily writing happens in one window. tweave itself doesn't care what editor you use, though; if you prefer something else, do Steps 2–3 from any terminal and see [Not using VS Code?](#not-using-vs-code).

### Step 1 — Set up VS Code

1. Install VS Code from [code.visualstudio.com](https://code.visualstudio.com/) if you don't have it.
2. On the left edge, click the icon that looks like four squares (or press **Ctrl + Shift + X**). This is a store of free add-ons called *extensions*.
3. In its search box, type **Tinymist Typst** and click **Install** on the first result. This gives you Typst syntax highlighting, error checking, and a live preview.
4. Search **R** and install the first result (by REditorSupport). This lets you run R code from inside VS Code.
5. (Optional) Search **vscode-pdf** and install it, so finished PDFs open inside VS Code instead of a separate program.

### Step 2 — Install R and Typst

1. **R** — download from [cran.r-project.org](https://cran.r-project.org/), run the installer, accept the defaults.
2. **Typst** — in VS Code, open a *terminal* — a panel where you type commands and press Enter to run them — with **Terminal → New Terminal** (or **Ctrl + `**, the backtick key above Tab). On Windows, run:

   ```powershell
   winget install --id Typst.Typst
   ```

   On macOS with [Homebrew](https://brew.sh): `brew install typst`. Or download from the [Typst releases page](https://github.com/typst/typst/releases).

**Check it worked:** open a **new** terminal (trash-can icon kills the old one; terminals don't see freshly installed programs until restarted) and run `typst --version`. A version number means you're good.

### Step 3 — Install tweave

Still in VS Code, open any folder (**File → Open Folder...** — an existing project is fine). Create a file named `setup.R`, paste in these three lines, and run them one at a time by putting your cursor on each line and pressing **Ctrl + Enter** (the R extension opens an R console for you):

```r
install.packages("remotes")
remotes::install_github("jimna-h/tweave")
tweave::install()
```

What they do: line 1 installs a helper for installing packages from GitHub; line 2 installs tweave itself (plus knitr and anything else it needs); line 3 copies the Typst template package into place and sets up the `tweave` command.

(If **Ctrl + Enter** can't find R, restart VS Code once — it detects R at startup. You can also run the same three lines in RStudio or the plain R app; they work anywhere R does.)

**Read what `tweave::install()` prints.** On most machines it finishes silently and you're done. If the folder it installed to isn't on your PATH yet, it prints one manual step — exact folder, exact clicks — and you do that once. ("PATH" is the list of folders your terminal searches when you type a command.)

**Check it worked:** open a **new terminal** — the terminal panel, not the R console — and run:

```
tweave --version
```

If it prints a version, everything is wired up. (Typing `tweave --version` into the R console instead gives `Error: object 'tweave' not found` — that's R telling you it's a terminal command, not an R command.)

### Step 4 — One-keystroke builds (recommended)

VS Code can run your build when you press **Ctrl + Shift + B**, using a small config called a *task*. You set this up **once, globally** — it then works in every folder you ever open, no per-project files needed.

1. Press **Ctrl + Shift + P**, type **user tasks**, and choose **Tasks: Open User Tasks**. (If it asks for a task template, pick **Others**.) This opens your personal, global `tasks.json`.
2. Replace the file's contents with:

   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "tweave: build current file",
         "type": "shell",
         "command": "tweave",
         "args": ["${fileBasename}"],
         "options": { "cwd": "${fileDirname}" },
         "group": { "kind": "build", "isDefault": true }
       }
     ]
   }
   ```

   You don't need to understand this file — it just tells VS Code: "when asked to build, run `tweave` on whatever file is currently open, from that file's folder."

3. Save, then open a `.typ` file and press **Ctrl + Shift + B**: the terminal knits and compiles it. From now on, your edit-build-check loop is: make a change, **Ctrl + Shift + B**, look at the PDF.

A few notes:

- **The task builds what's on your screen, not the last save.** VS Code saves all unsaved files before running a task (the `task.saveBeforeRun` setting, on by default) — so **Ctrl + Shift + B** always sees your latest edits. Building from the terminal doesn't do this: a manually typed `tweave file.typ` reads whatever was last *saved*, and an unsaved file can even be empty on disk (tweave will refuse it with a "did you save?" error). If you prefer terminal builds, consider turning on **File → Auto Save**.
- **It runs on whatever file is focused**, so pressing it with (say) a `.R` file open will just produce a knitr error — harmless, but if you'd rather be asked which task to run each time, change `"isDefault": true` to `false` and **Ctrl + Shift + B** will show a picker instead. (Tasks can't be automatically restricted to `.typ` files — VS Code doesn't scope tasks by file type.)
- **Per-project alternative:** if you ever want a task only for one folder (e.g., a shared repo), put the same JSON in a file at `.vscode/tasks.json` inside that folder. Folder tasks and your global task will both appear in the picker.

#### Made a change and nothing happened?

Two different "restarts" trip people up in VS Code:

- **After installing an extension** or when settings/snippets/tasks don't seem to take effect: press **Ctrl + Shift + P** and run **Developer: Reload Window** (or just close and reopen VS Code).
- **After changing your PATH** (e.g., the manual step `tweave::install()` may ask for): reloading the window isn't enough — kill the old terminal (trash-can icon in the terminal panel) and open a new one, or fully restart VS Code.

When in doubt, fully close and reopen VS Code — that resets both.

### Updating later

Re-run lines 2 and 3 from Step 3. That's it.

---

## Writing and building a document

### Open your project folder

Use **File → Open Folder...** and pick the folder where your `.typ` files live. Opening the *folder* (not just a single file) matters: it makes the built-in terminal start in the right place and lets VS Code remember settings per project.

### Start a document

Create a file ending in `.typ` that starts like this:

````typst
#import "@local/tweave:0.1.0": *
#show: tweave.with(
  title: "Eruption Analysis",
  author: "Your Name",
)

= Summary statistics

```{r}
wait <- faithful$waiting
```

Across `r length(wait)` recorded eruptions of Old Faithful, the mean waiting
time is `r mean(wait)` minutes.
````

Everything between ```` ```{r} ```` and ```` ``` ```` is R code that actually runs when you build. `` `r ...` `` in a sentence gets replaced by the value of the expression, rounded to 4 digits.

### Build it

Press **Ctrl + Shift + B** (the build task from Step 4), or type `tweave analysis.typ` in the VS Code terminal.

This produces:

- `analysis.knit.typ` — the intermediate file with R results baked in (you can ignore it)
- `analysis.knit.pdf` — **your finished PDF**
- a `figure/analysis/` folder holding any plots

Rebuild after every edit; it takes a second or two.

**Prefer to stay inside RStudio?** The same build is available as an R function — no terminal needed:

```r
tweave::weave("analysis.typ")
```

### A starter snippet (optional)

Every tweave document starts with the same few lines of boilerplate. VS Code *snippets* let you type a short word and press Tab to expand it into all of that, with the cursor jumping between the fill-in spots.

1. Press **Ctrl + Shift + P** (opens the Command Palette — a search box for every VS Code command), type **snippets**, and choose **Snippets: Configure Snippets**.
2. Pick **typst** from the list (it appears because you installed Tinymist). This opens a file called `typst.json`.
3. Paste this inside the outermost `{ }` (replacing the commented examples if you like):

   ```json
   "tweave document setup": {
     "prefix": "tweave",
     "body": [
       "#import \"@local/tweave:0.1.0\": *",
       "#show: tweave.with(",
       "  title: \"${1:Title}\",",
       "  author: \"${2:Your Name}\",",
       ")",
       "",
       "```{r}",
       "# Global Setup",
       "set.seed(123) # for reproducibility",
       "```",
       "",
       "$0"
     ],
     "description": "tweave template import + global R setup chunk"
   }
   ```

4. Save. Now in any `.typ` file, type `tweave` and press **Tab**: the whole header appears, your cursor lands on the title, **Tab** jumps to the author, and a final **Tab** drops you below the setup chunk, ready to write.

### One important gotcha: the live preview doesn't run R

Tinymist's preview button (top-right when a `.typ` file is open) compiles your document *directly*, skipping the R step — so R chunks show up as plain code blocks, inline `` `r ...` `` values appear as literal text, and plots are missing. This is normal, not a bug.

Use the preview for checking **layout, math, and prose**, and use **Ctrl + Shift + B** whenever you need to see **actual R results**. If you want a live-ish view of the real output, run a build and open `yourfile.knit.pdf` in a VS Code tab — it refreshes each time you rebuild.

### Chunk options

Standard knitr options work in the chunk header:

- ```` ```{r, echo=FALSE} ```` — run the code but don't show it
- ```` ```{r, include=FALSE} ```` — run the code, show nothing at all
- ```` ```{r, results='hide'} ```` — show the code but not its output

Inline numbers round to 4 digits by default; put `digits <- 2` in any chunk to change that.

### Not using VS Code?

Everything works from any editor plus any terminal. Open a terminal (Windows: press Start, type `powershell`, Enter; macOS: **Cmd + Space**, type `terminal`, Enter), move into your document's folder, and build:

```sh
cd path/to/your/project/folder
tweave analysis.typ
```

(`cd` means "change directory". To run a command, type or paste it and press **Enter**.) One habit matters more without VS Code: **save your file before building** — the terminal builds what's on disk, not what's on your screen.

---

## Troubleshooting

**`Error: object 'tweave' not found`**
You typed a terminal command into the R console. `tweave --version` and `tweave file.typ` go in the terminal; inside R, use `tweave::weave("file.typ")` and `packageVersion("tweave")` instead.

**`tweave : The term 'tweave' is not recognized...`** (or `command not found`)
The shim folder isn't on your PATH, or your terminal predates the install. Open a **new** terminal first. If it persists, re-run `tweave::install()` in R and follow the PATH instructions it prints, then open a new terminal again.

**`typst : The term 'typst' is not recognized...`** or tweave says the Typst CLI is missing
Typst isn't installed, or your terminal was open when you installed it. Close and reopen the terminal. If it persists, reinstall via `winget install --id Typst.Typst` (Windows) or `brew install typst` (macOS).

**`tweave: could not find R`**
The Windows shim looks for R on your PATH, then in the registry. This message means R isn't installed (or was installed in a very unusual way). Install R from [cran.r-project.org](https://cran.r-project.org/) with default options.

**`error: package not found ... @local/tweave:0.1.0`**
The Typst template package isn't installed. Run `tweave::install()` in R — it places it in the right folder for your OS automatically.

**Errors during `remotes::install_github(...)`**
Check your internet connection and that you typed the repo name exactly: `jimna-h/tweave`. Corporate/campus networks sometimes block GitHub; try another network.

**Plots missing from the PDF**
Don't delete the `figure/` folder between knitting and compiling — plots are stored there and referenced by the PDF build.

---

## Uninstalling

In R, two commands:

```r
tweave::uninstall()          # removes the Typst template package and the tweave command
remove.packages("tweave")    # removes the R package itself
```

(In that order — `uninstall()` needs the package still installed to run.) If you added a folder to your PATH during setup on Windows, the leftover entry is harmless, but `uninstall()` prints where to remove it if you want a fully clean exit.

## For developers

tweave is a standard R package:

```
R/                 weave() pipeline, knitr→Typst hooks, CLI, installer
inst/typst/        the bundled Typst template package (@local/tweave)
inst/bin/          CLI shims (sh + .cmd) — thin wrappers over tweave::main()
tests/testthat/    unit tests + an end-to-end fixture
.github/workflows/ R CMD check on Windows, macOS, and Linux
```

Run the tests with `devtools::test()`. Pull requests welcome.

## Why "tweave"?

[Sweave](https://en.wikipedia.org/wiki/Sweave) was the original literate-programming tool for statistics — S (the language R grew out of) + *weave*, running code inside LaTeX documents. knitr carried the wordplay forward (knit + R). tweave is the same idea with Typst taking LaTeX's chair: **T**ypst + **weave**. It also works as a verb, the way `knit` does:

```sh
tweave analysis.typ
```

## License

MIT — see [LICENSE](LICENSE.md).
