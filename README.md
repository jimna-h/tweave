# tweave

**Write your statistics documents in Typst, with live R code — no Quarto required.**

tweave knits R (and optionally Python) code chunks embedded in a `.typ` file, then compiles the result straight to PDF. You get Typst's fast, clean typesetting plus reproducible code output: code blocks, console output, plots, and inline values that update every time you build — for analyses, reports, assignments, exams, or anything you'd once have reached for Sweave to write.

It ships with a stats-focused Typst package (also called `tweave`) that provides:

- **Math shorthands** — `iid` (∼ with "iid" above it), `bar(x)` for sample means, `choose(x, y)` for binomial coefficients, hypotheses `H0`/`HA`, upright distribution names (`Normal`, `Poisson`, `Binomial`, …), and differentials `dx`, `dt`, `dtheta`, …
- **Inline R values** — `` `r mean(y)` `` in your prose, auto-rounded (set `digits` in R to control precision) with scientific notation rendered as proper Typst math
- **`typst_vars()`** — for values that need to sit *inside* a complex math expression (a fraction, a square root, an exponent) rather than next to one — [details below](#values-inside-complex-equations-typst_vars)
- **Python chunks alongside R ones** — ```` ```{python} ```` chunks weave through the same pipeline (via [reticulate](https://rstudio.github.io/reticulate/)), with shared state and matplotlib figure capture, if you'd rather work in Python for a given analysis — [details below](#python-chunks-optional). Already have Python packages installed? `tweave::use_system_python()` points reticulate at your existing setup instead of its own isolated environment, permanently, in one line.
- **Sensible defaults** — styled code/output blocks, numbered equations, auto-linked URLs, a title block

tweave deliberately does *not* impose document structure like question numbering, prompt boxes, or point tallies. It composes with any of the templates on [Typst Universe](https://typst.app/universe/) — grape-suite, tinyset, adaptable-pset, and others — or with a few `#let` definitions of your own (the example shows this pattern).

Two examples: [`example1.typ`](examples/example1.typ) ([PDF](examples/example1.pdf)) is a plain homework-style document — the Quarto-parity baseline. [`example2.typ`](examples/example2.typ) ([PDF](examples/example2.pdf)) is the reason to switch: a styled report with a gradient title band, stat cards fed by inline R, running page headers, captioned cross-referenced figures, R-*generated* striped tables (`results='asis'`), a key-finding banner, footnotes, two-column text, and a one-line APA bibliography from a plain `.bib` file — each of which is a few lines of Typst rather than a LaTeX preamble battle.

## How it works

```
yourfile.typ  ──knitr──▶  (yourfile.knit.typ)  ──typst──▶  yourfile.pdf
                           removed after a
                           successful build
```

The `tweave` command runs your document through **knitr** (executing the R chunks and inserting their formatted results), then calls `typst compile` on the result. Under the hood, tweave is an R package — installing it pulls in everything R-side automatically.

---

## Installation

Setup takes about 15 minutes. If anything goes wrong, see [Troubleshooting](#troubleshooting).

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

- `analysis.pdf` — **your finished PDF**
- a `figure/analysis/` folder holding any plots (safe to delete; it's regenerated every build)

Rebuild after every edit; it takes a second or two. (An intermediate `analysis.knit.typ` exists briefly during the build and is removed on success; if compilation *fails*, it's kept so the error's line numbers have a file to point at. `tweave --keep analysis.typ` keeps it always, if you want to inspect what knitr produced.)

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

If you'll be starting documents with Python instead of R, add a second entry to the same `typst.json` (right after the one above, separated by a comma):

```json
   "tweave document setup (python)": {
     "prefix": "tweavepy",
     "body": [
       "#import \"@local/tweave:0.1.0\": *",
       "#show: tweave.with(",
       "  title: \"${1:Title}\",",
       "  author: \"${2:Your Name}\",",
       ")",
       "",
       "```{python}",
       "# Global Setup",
       "import numpy as np",
       "np.random.seed(123)  # for reproducibility",
       "```",
       "",
       "$0"
     ],
     "description": "tweave template import + global Python setup chunk"
   }
```

Type `tweavepy` and Tab for the Python-flavored version. Mixed documents just start with whichever engine's setup you need most and add ```` ```{r} ```` or ```` ```{python} ```` chunks freely after that.

### One important gotcha: the live preview doesn't run R (or Python)

Tinymist's preview button (top-right when a `.typ` file is open) compiles your document *directly*, skipping the knit step — so code chunks show up as plain code blocks, inline `` `r ...` `` / `` `py ...` `` values appear as literal text, and plots are missing. This is normal, not a bug.

**One case is worse than "looks wrong": an inline value inside math mode (`$...$`) will show a red squiggly error, not just odd text.** For example, `$R^2 = `r r2`$` previews as:

```
error: unknown variable: r2
```

This is a fundamental Typst rule, not a bug or a missing setting — [per Typst's own docs](https://typst.app/docs/reference/math/), a bare multi-letter run inside `$...$` is *always* resolved as a variable or function name, with no raw/escape syntax available (backticks mean nothing special in math mode; there's no compiler flag or Tinymist setting to turn this off). And it's not cosmetic to just that line: **a single unresolved error like this fails the *entire* compile**, so the whole document's preview goes blank, not just that equation, until you fix or work around it.

**The fix that keeps the preview working: put the value outside the math zone, not inside it.** A knit-time value can never appear *inside* a live `$...$`, only next to one — but you can put the `=` (or any other trailing operator) inside math and leave only the bare number in prose right after, which keeps the spacing and sizing visually identical to writing it all as one expression:

```typst
A simple linear fit gives ($R^2 =$ `r r2`).
```

instead of

```typst
A simple linear fit gives ($R^2 = `r r2`$).
```

There's no live `$...$` zone containing unresolved syntax in the raw source this way, so the preview compiles and renders normally at every point while you're editing — no more blank preview. And because this still uses a plain `` `r r2` `` inline substitution (not a hand-built string), tweave's automatic `digits`-rounding keeps working with no extra effort.

**The real tradeoff:** this means no knit-time value can ever sit *inside* Typst math syntax written the ordinary way — only immediately before or after a self-contained math zone. For a trailing `=`-then-value pattern like the one above, that costs nothing visually. For a value that needs to sit in the *middle* of an expression — under a square root, inside a fraction, as part of an exponent — there's a second tool for exactly that case.

### Values inside complex equations: `typst_vars()`

`tweave::typst_vars()` exposes a whole dictionary of R values as real, static Typst source, referenced with `.at("key", default: ...)` — valid Typst syntax at *any* position in a math expression, including deeply nested ones, and safe pre-knit because `default:` supplies a placeholder before the real value exists.

Once, near the top of the document:

```typst
#let vals = (:)
```

In a chunk, after the values are computed:

```typst
```{r, results='asis', echo=FALSE}
cat(tweave::typst_vars(list(mse = mse, sxx = sxx, t_crit = t_crit)))
```
```

Then anywhere — including buried inside a square root:

```typst
$ beta_1 plus.minus t^* dot sqrt(vals.at("mse", default: 0) / vals.at("sxx", default: 0)) $
```

The pre-knit source always has *something* to resolve `vals` to (the empty placeholder, or an earlier `results='asis'` call), so the preview never breaks — and `typst_vars()` rounds numbers using the same `digits` convention as inline substitution, so there's no separate rounding step to remember. See [`examples/example3.typ`](examples/example3.typ) for the full worked pattern.

This is more setup than the trailing-`=` trick, so reach for it only when a value genuinely needs to sit inside an expression rather than next to one.

If you'd rather not restructure existing math, or run into another case Typst won't parse pre-knit, the fallback is simply: ignore the preview error on that line and use the preview for everything else.

Use the preview for checking **layout, math, and prose**, and use **Ctrl + Shift + B** whenever you need to see **actual results**. If you want a live-ish view of the real output, run a build and open `yourfile.pdf` in a VS Code tab — it refreshes each time you rebuild.

**Chunk fence spacing:** both ```` ```{r} ```` and ```` ``` {r} ```` (with a space) are knitted identically by tweave — but the space avoids one extra Tinymist warning ("no whitespace before raw text") when previewing un-knitted source, since Typst would otherwise read `{r}` as an attempted (invalid) syntax-highlighting language tag. Either form works; the space just makes the live preview a little quieter.

### Chunk options

Standard knitr options work in the chunk header:

- ```` ```{r, echo=FALSE} ```` — run the code but don't show it
- ```` ```{r, include=FALSE} ```` — run the code, show nothing at all
- ```` ```{r, results='hide'} ```` — show the code but not its output

Inline numbers round to 4 digits by default; put `digits <- 2` in any chunk to change that.

### Python chunks (optional)

tweave also weaves ```` ```{python} ```` chunks, side by side with ```` ```{r} ```` ones in the same document — same pipeline, no extra setup beyond installing [reticulate](https://rstudio.github.io/reticulate/):

```r
install.packages("reticulate")
```

```typst
#import "@local/tweave:0.1.0": *
#show: tweave.with(title: "Mixed R and Python", author: "Your Name")

```{python}
import numpy as np
y = np.array([1, 2, 3, 4, 5])
y.mean()
```

The Python mean is `r py$y.mean()`.
```

Python chunks share state with each other (a variable set in one chunk is visible in the next), and matplotlib figures are captured the same way R plots are — just call `plt.show()`. To read a Python value into R prose, use reticulate's `py` object as shown above. If reticulate isn't installed, ```` ```{r} ```` chunks are completely unaffected; a ```` ```{python} ```` chunk is simply left un-run, the same as any unknown knitr engine.

**Already have Python set up, with packages installed via a plain `pip install`?** By default, reticulate creates and uses its *own* isolated virtual environment — separate from whatever Python you've been installing packages into directly, which is why a chunk can fail with `ModuleNotFoundError` even for a package you know you've installed. Run this **once**, in the R console (not a terminal):

```r
tweave::use_system_python()
```

This finds the Python that a plain `pip install` targets, points reticulate at it, and — by default — saves that choice to your `.Renviron`, so every future `tweave` build uses it automatically. You won't need to repeat this per document, or even remember you did it.

**Want a specific interpreter or virtual environment instead** (a named conda env, a project-specific venv)? Add this near the top of your document (in an `include=FALSE` chunk, before any other Python chunk):

```{r, include=FALSE}
reticulate::use_python("/path/to/python")      # a specific interpreter, or
reticulate::use_virtualenv("myenv")            # a named virtualenv, or
reticulate::use_condaenv("myenv")              # a named conda environment
```

Run `reticulate::py_config()` in the R console to see which Python reticulate is currently finding and why.

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

**A `{python}` chunk is silently skipped, or errors about an unknown engine**
`reticulate` isn't installed — run `install.packages("reticulate")` and rebuild. If it *is* installed but errors about modules it can't find, reticulate is likely using an isolated venv instead of your real Python — run `tweave::use_system_python()` once (see [Python chunks](#python-chunks-optional) above), and check `reticulate::py_config()`.

**`ModuleNotFoundError: No module named 'matplotlib'`** (or `numpy`, or any other package)
Reticulate found *a* Python on your system — usually its own isolated virtual environment, not the one you've been `pip install`-ing into. Two fixes, pick one:

- **If you already have the package installed elsewhere:** run `tweave::use_system_python()` once in the R console (see [Python chunks](#python-chunks-optional) above) to point reticulate at that Python permanently.
- **If you'd rather install into reticulate's own environment:** run `reticulate::py_install(c("numpy", "matplotlib"))` in the R console instead.

**`Using Python: ...\AppData\Local\Microsoft\WindowsApps\python.exe`, then a warning that the file can't be accessed**
`tweave::use_system_python()` (0.6.3+) correctly skips this on its own: it runs each candidate and requires a real `Python 3.x.y`-style version string, not just any output. (Versions 0.6.1–0.6.2 tried to verify candidates too, but were fooled by the alias's own rejection message — "Python was not found; run without arguments to install..." — which happens to contain the word "Python"; if you're on one of those versions, update first.) If you still see this after updating, it's a Windows-only trap regardless: Windows puts a fake placeholder `python.exe` on PATH by default (an "App Execution Alias"), even if you've never touched the Microsoft Store, and it isn't a real interpreter. Turn it off at **Settings > Apps > Advanced app settings > App execution aliases**, switching off the entries for `python.exe` and `python3.exe`, then rerun `tweave::use_system_python()`.

**`error: unknown variable: r2`** (or similar, pointing at an inline `` `r ...` `` inside `$...$`)
This is the VS Code *preview*, not a real build — see [the live preview gotcha](#one-important-gotcha-the-live-preview-doesnt-run-r-or-python) above for why, and for a rewrite that keeps the preview working (put the value outside the `$...$`, not inside it).

**`error: package not found ... @local/tweave:0.1.0`**
The Typst template package isn't installed. Run `tweave::install()` in R — it places it in the right folder for your OS automatically.

**Errors during `remotes::install_github(...)`**
Check your internet connection and that you typed the repo name exactly: `jimna-h/tweave`. Corporate/campus networks sometimes block GitHub; try another network.

**Compile error mentioning a `.knit.typ` file**
That's the intermediate file tweave keeps around when compilation fails — the error's line numbers refer to it. Fix your `.typ` source (the intermediate mirrors it, plus R output) and rebuild; it's cleaned up automatically on the next success.

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
