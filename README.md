# tweave

**Write your statistics homework in Typst, with live R code — no Quarto required.**

tweave knits R code chunks embedded in a `.typ` file, then compiles the result straight to PDF. You get Typst's fast, clean typesetting plus reproducible R output: code blocks, console output, plots, and inline values that update every time you build.

It ships with a stats-homework-focused Typst package (also called `tweave`) that provides:

- **Auto-numbered questions** — `#nextquestion()` and `#subquestion()` produce `Question 1`, `1a.`, `1b.`, … with no manual bookkeeping
- **`#questionbox[...]`** — a tinted callout that visually separates the assignment prompt from your answer (works with code chunks and math inside)
- **Math shorthands** — `iid` (∼ with "iid" above it), `bar(x)` for sample means, `choose(x, y)` for binomial coefficients, and differentials `dx`, `dy`, `dtheta`, …
- **Inline R values** — `` `r mean(y)` `` in your prose, auto-rounded (set `digits` in R to control precision) with scientific notation rendered as proper Typst math
- **Sensible defaults** — styled code/output blocks, numbered equations, auto-linked URLs, a title block

See [`examples/example1.typ`](examples/example1.typ) and its [rendered PDF](examples/example1.knit.pdf).

## How it works

```
yourfile.typ  ──knitr──▶  yourfile.knit.typ  ──typst──▶  yourfile.knit.pdf
```

The `tweave` command runs your document through **knitr** (executing the R chunks and inserting their formatted results), then calls `typst compile` on the result. Under the hood, tweave is an R package — installing it pulls in everything R-side automatically.

---

## Installation

Setup takes about 10 minutes, once. If anything goes wrong, see [Troubleshooting](#troubleshooting).

> **Planning to use VS Code?** Do this setup first — it's required either way — then see [the VS Code section](#optional-a-nicer-setup-with-vs-code) for extensions, one-keystroke builds, and a starter snippet.

### Step 1 — Install R and Typst

1. **R** — download from [cran.r-project.org](https://cran.r-project.org/), run the installer, accept the defaults.
2. **Typst** — on Windows, open PowerShell (press Start, type `powershell`, Enter) and run:

   ```powershell
   winget install --id Typst.Typst
   ```

   On macOS with [Homebrew](https://brew.sh): `brew install typst`. Or download from the [Typst releases page](https://github.com/typst/typst/releases).

**Check it worked:** open a **new** terminal (it doesn't see freshly installed programs until restarted) and run `typst --version`. A version number means you're good.

### Step 2 — Install tweave

Open R (the "R" or "RStudio" app — not the terminal) and run these three lines in the console:

```r
install.packages("remotes")
remotes::install_github("jimna-h/tweave")
tweave::install()
```

What they do: line 1 installs a helper for installing packages from GitHub; line 2 installs tweave itself (plus knitr and anything else it needs — automatically); line 3 copies the Typst template package into place and sets up the `tweave` command.

**Read what `tweave::install()` prints.** On most machines it finishes silently and you're done. If the folder it installed to isn't on your PATH yet, it prints one manual step — exact folder, exact clicks — and you do that once. ("PATH" is the list of folders your terminal searches when you type a command.)

**Check it worked:** open a **new** terminal and run:

```
tweave --version
```

If it prints a version, everything is wired up.

### Updating later

Re-run lines 2 and 3 from Step 2. That's it.

---

## Writing and building a document

### A note on "the terminal"

Building happens in a *terminal* — a window where you type commands instead of clicking buttons.

- **Windows:** press Start, type `powershell`, Enter.
- **macOS:** press **Cmd + Space**, type `terminal`, Enter.

To run a command, type it (or paste — right-click pastes in PowerShell) and press **Enter**.

### Start a document

Create a file ending in `.typ` (in VS Code, RStudio, or even Notepad) that starts like this:

````typst
#import "@local/tweave:0.1.0": *
#show: tweave.with(
  title: "STAT 251 Homework 4",
  author: "Your Name",
)

#nextquestion()
#questionbox[Compute the sample mean of 32, 38, 40, 34, 37, 29.]

```{r}
y <- c(32, 38, 40, 34, 37, 29)
avg <- mean(y)
```

The average is `r avg` wpm.
````

Everything between ```` ```{r} ```` and ```` ``` ```` is R code that actually runs when you build. `` `r avg` `` in a sentence gets replaced by the value of `avg`, rounded to 4 digits.

### Build it

In your terminal, navigate to the folder containing your document, then build:

```sh
cd path/to/your/homework/folder
tweave homework4.typ
```

(`cd` means "change directory" — it moves your terminal into that folder. In VS Code you can skip this: open your folder in VS Code, then **Terminal → New Terminal** opens a terminal already in the right place.)

This produces:

- `homework4.knit.typ` — the intermediate file with R results baked in (you can ignore it)
- `homework4.knit.pdf` — **your finished PDF**
- a `figure/homework4/` folder holding any plots

Rebuild after every edit; it takes a second or two.

**Prefer to stay inside RStudio?** The same build is available as an R function — no terminal needed:

```r
tweave::weave("homework4.typ")
```

### Chunk options

Standard knitr options work in the chunk header:

- ```` ```{r, echo=FALSE} ```` — run the code but don't show it
- ```` ```{r, include=FALSE} ```` — run the code, show nothing at all
- ```` ```{r, results='hide'} ```` — show the code but not its output

Inline numbers round to 4 digits by default; put `digits <- 2` in any chunk to change that.

---

## Optional: a nicer setup with VS Code

You can write `.typ` files in any text editor, but [VS Code](https://code.visualstudio.com/) gives you syntax highlighting, a live preview, and a one-keystroke build. Setup takes about 5 minutes.

### Install the extensions

1. Open VS Code. On the left edge, click the icon that looks like four squares (or press **Ctrl + Shift + X**). This is the Extensions pane — a store of free add-ons.
2. In its search box, type **Tinymist Typst** and click **Install** on the first result. This gives you Typst syntax highlighting, error checking, and a live preview.
3. (Optional) Search **vscode-pdf** and install it, so finished PDFs open inside VS Code instead of a separate program.

### Open your homework folder

Use **File → Open Folder...** and pick the folder where your `.typ` files live. Opening the *folder* (not just a single file) matters: it makes the built-in terminal start in the right place and lets VS Code remember settings per project.

Then open a terminal inside VS Code with **Terminal → New Terminal** (or **Ctrl + `** — that's the backtick key, above Tab). It's the same PowerShell/Terminal from earlier, already in your project folder, so you can build with:

```sh
tweave homework4.typ
```

### One-keystroke builds (optional but great)

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

3. Save, then open your `.typ` file and press **Ctrl + Shift + B**: the terminal knits and compiles it. From now on, your edit-build-check loop is: make a change, **Ctrl + S**, **Ctrl + Shift + B**, look at the PDF.

A few notes:

- **It runs on whatever file is focused**, so pressing it with (say) a `.R` file open will just produce a knitr error — harmless, but if you'd rather be asked which task to run each time, change `"isDefault": true` to `false` and **Ctrl + Shift + B** will show a picker instead. (Tasks can't be automatically restricted to `.typ` files — VS Code doesn't scope tasks by file type.)
- **Per-project alternative:** if you ever want a task only for one folder (e.g., a shared repo), put the same JSON in a file at `.vscode/tasks.json` inside that folder. Folder tasks and your global task will both appear in the picker.

### Made a change and nothing happened?

Two different "restarts" trip people up in VS Code:

- **After installing an extension** or when settings/snippets/tasks don't seem to take effect: press **Ctrl + Shift + P** and run **Developer: Reload Window** (or just close and reopen VS Code).
- **After changing your PATH** (e.g., the manual step `tweave::install()` may ask for): reloading the window isn't enough — kill the old terminal (trash-can icon in the terminal panel) and open a new one, or fully restart VS Code.

When in doubt, fully close and reopen VS Code — that resets both.

### A starter snippet (optional)

Every homework file starts with the same six lines of boilerplate. VS Code *snippets* let you type a short word and press Tab to expand it into all of that, with the cursor jumping between the fill-in spots.

1. Press **Ctrl + Shift + P** (opens the Command Palette — a search box for every VS Code command), type **snippets**, and choose **Snippets: Configure Snippets**.
2. Pick **typst** from the list (it appears because you installed Tinymist). This opens a file called `typst.json`.
3. Paste this inside the outermost `{ }` (replacing the commented examples if you like):

   ```json
   "tweave homework setup": {
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

4. Save. Now in any `.typ` file, type `tweave` and press **Tab**: the whole header appears, your cursor lands on the title, **Tab** jumps to the author, and a final **Tab** drops you below the setup chunk, ready to write `#nextquestion()`.

### One important gotcha: the live preview doesn't run R

Tinymist's preview button (top-right when a `.typ` file is open) compiles your document *directly*, skipping the R step — so R chunks show up as plain code blocks, inline `` `r ...` `` values appear as literal text, and plots are missing. This is normal, not a bug.

Use the preview for checking **layout, math, and prose**, and use `tweave` / **Ctrl + Shift + B** whenever you need to see **actual R results**. If you want a live-ish view of the real output, run a build and open `yourfile.knit.pdf` in a VS Code tab — it refreshes each time you rebuild.

---

## Troubleshooting

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
tweave homework4.typ
```

## License

MIT — see [LICENSE](LICENSE.md).
