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

`build.R` runs your document through **knitr** (an R package that executes the R chunks and inserts their formatted results), then calls `typst compile` on the result. You'll set up a one-word command, `tweave`, that does both steps for you.

---

## Setup guide (no experience required)

The setup takes about 15 minutes and you only ever do it once. If you get stuck at any step, the [Troubleshooting](#troubleshooting) section at the bottom covers the most common problems.

> **Planning to use VS Code?** See [the VS Code section](#optional-a-nicer-setup-with-vs-code) further down for extensions, one-keystroke builds, and a starter snippet.

### A note on "the terminal"

Several steps below happen in a *terminal* — a window where you type commands instead of clicking buttons.

- **Windows:** press the **Start** key, type `powershell`, and hit Enter. A blue or black window opens with something like `PS C:\Users\You>` waiting for you to type. That's PowerShell.
- **macOS:** press **Cmd + Space**, type `terminal`, hit Enter.

To run a command, type it (or paste it — right-click pastes in PowerShell) and press **Enter**. That's the whole trick.

### Step 0 — Install the prerequisites

You need two programs installed before anything else:

1. **R** — download from [cran.r-project.org](https://cran.r-project.org/), run the installer, accept all the defaults.
2. **Typst** — the easiest route on Windows is to open PowerShell and run:

   ```powershell
   winget install --id Typst.Typst
   ```

   On macOS with [Homebrew](https://brew.sh): `brew install typst`. Or download it manually from the [Typst releases page](https://github.com/typst/typst/releases).

Then install the **knitr** package inside R: open R (or RStudio, or VS code if you've installed the R extension), and in the console type:

```r
install.packages("knitr")
```

**Check it worked:** close and reopen your terminal (important — it doesn't see newly installed programs until restarted), then run:

```
typst --version
```

If it prints a version number like `typst 0.13.0`, you're good. If it says the command isn't recognized, see Troubleshooting.

### Step 1 — Download this repository

Click the green **Code** button at the top of this GitHub page and choose **Download ZIP**. Unzip it somewhere permanent — somewhere you won't delete or move it later, because the `tweave` command you set up in Step 3 will point at this folder forever.

Good choice: `C:\Users\YourName\tweave` (Windows) or `~/tweave` (macOS).
Bad choice: your Downloads folder or your Desktop clutter pile.

(If you know git: `git clone https://github.com/jimna-h/tweave` does the same thing.)

### Step 2 — Install the Typst package

Typst looks for locally-installed packages in one specific folder on your computer. We need to copy the *inner* `tweave` folder (the one containing `0.1.0`) from this repo into it.

**Windows:**

1. Press **Win + R** (opens the "Run" dialog), paste this, and hit Enter:

   ```
   %LOCALAPPDATA%\typst\packages\local
   ```

   *If Windows says the folder doesn't exist:* open File Explorer, paste `%LOCALAPPDATA%` in the address bar, hit Enter, and create the folders yourself — a folder named `typst`, inside it `packages`, inside that `local`.

2. Copy the inner `tweave` folder (the one that contains `0.1.0`) from the repo you downloaded into this `local` folder.

**macOS:** in Finder, press **Cmd + Shift + G**, paste `~/Library/Application Support/typst/packages/local` (create the folders if needed), and copy the inner `tweave` folder in.

**Linux:** copy the inner `tweave` folder into `~/.local/share/typst/packages/local/`.

**Check it worked:** you should be able to navigate to a file at

```
...\typst\packages\local\tweave\0.1.0\tweave.typ
```

The `0.1.0` folder in the middle matters — don't flatten it out.

### Step 3 — Create the `tweave` command

Right now, building a document would mean typing a long, ugly command every time. Instead we'll teach your terminal a shortcut: `tweave`.

#### Windows (PowerShell)

PowerShell has a *profile* — a script file it runs automatically every time it starts. We'll add our shortcut there so it's always available.

1. **Find where R installed itself.** In PowerShell, run:

   ```powershell
   Get-ChildItem "C:\Program Files\R" -Filter Rscript.exe -Recurse | Select-Object FullName
   ```

   This searches your R installation for a program called `Rscript.exe` (the version of R that runs script files). It prints a path like:

   ```
   C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe
   ```

   Copy that path — you need it in a moment.

2. **Open your PowerShell profile in Notepad.** Run:

   ```powershell
   notepad $PROFILE
   ```

   (`$PROFILE` is just PowerShell's nickname for the path to that startup script. This command means "open my profile file in Notepad.")

   If Notepad asks *"Do you want to create a new file?"* — say **Yes**. That just means you've never had a profile before, which is normal.

   > **If Notepad shows an error instead, or your changes won't save:** the *folder* the profile lives in probably doesn't exist yet, and Notepad can't create folders. Create the file properly first:
   >
   > ```powershell
   > New-Item -Path $PROFILE -Type File -Force
   > ```
   >
   > (this creates the file *and* any missing folders along the way), then run `notepad $PROFILE` again.

3. **Add the shortcut.** Paste this into Notepad, replacing both paths with *your* Rscript path from step 1 and the folder where *you* unzipped the repo:

   ```powershell
   function tweave {
       & "C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe" "C:\Users\YourName\tweave\build.R" $args
   }
   ```

   Save the file (**Ctrl + S**) and close Notepad.

4. **Restart PowerShell** (close the window, open a new one). The profile only runs at startup, so the shortcut doesn't exist until you restart.

   > **If you see a red error about "running scripts is disabled":** Windows blocks profile scripts by default. Fix it once by running:
   >
   > ```powershell
   > Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   > ```
   >
   > answer `Y`, then restart PowerShell again. This allows scripts you wrote yourself while still blocking unsigned scripts from the internet.
   >
   > On some machines (especially school or work PCs with stricter defaults) that isn't enough. If the error persists, open PowerShell **as Administrator** (right-click it in the Start menu → *Run as administrator*) and run:
   >
   > ```powershell
   > Set-ExecutionPolicy -Scope LocalMachine RemoteSigned -Force
   > ```
   >
   > then restart PowerShell. If even that is blocked, your machine is centrally managed by Group Policy and you'll need IT's help.

**Check it worked:** type `tweave` and hit Enter. If you see an R error about a missing file (rather than *"tweave is not recognized"*), the shortcut works — it just has no document to build yet.

#### macOS / Linux

The repo includes a small launcher script at `bin/tweave`. You just need to make it reachable from anywhere. In Terminal, run (adjust the path to where you put the repo):

```sh
chmod +x ~/tweave/bin/tweave
sudo ln -s ~/tweave/bin/tweave /usr/local/bin/tweave
```

Line one marks the script as executable; line two creates a link to it in a folder your terminal already searches for commands (`sudo` will ask for your login password — typing it shows nothing on screen, that's normal, just type it and hit Enter).

**Check it worked:** run `tweave` from any folder. An R error about a missing input file = success.

---

## Writing and building a document

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

```powershell
cd C:\Users\YourName\Documents\stat251
tweave homework4.typ
```

(`cd` means "change directory" — it moves your terminal into that folder. In VS Code you can skip this: open your folder in VS Code, then **Terminal → New Terminal** opens a terminal already in the right place.)

This produces:

- `homework4.knit.typ` — the intermediate file with R results baked in (you can ignore it)
- `homework4.knit.pdf` — **your finished PDF**
- a `figure/homework4/` folder holding any plots

Rebuild after every edit; it takes a second or two.

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

> **Windows users:** if `tweave` isn't recognized here but works in a regular PowerShell window, VS Code may be using a different shell. Click the `∨` next to the `+` in the terminal panel and choose **PowerShell**.

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
- **After editing your PowerShell profile** (the `tweave` function from Step 3): reloading the window isn't enough — the profile only loads when a *terminal* starts. Kill the old terminal (trash-can icon in the terminal panel) and open a new one.

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

**`typst : The term 'typst' is not recognized...`**
Typst isn't installed, or your terminal was open when you installed it. Close and reopen the terminal first. If it persists, reinstall via `winget install --id Typst.Typst`.

**`tweave : The term 'tweave' is not recognized...`**
The profile function didn't load. Restart PowerShell. If it still fails, run `notepad $PROFILE` and confirm your function is actually saved there, and check for the execution-policy error described in Step 3.

**Red error mentioning `Rscript.exe` not found**
The path in your `tweave` function doesn't match your installed R version (R updates change the folder name, e.g. `R-4.5.2` → `R-4.6.0`). Re-run the `Get-ChildItem` search from Step 3 and update the path in `notepad $PROFILE`.

**`error: package not found ... @local/tweave:0.1.0`**
The Typst package isn't where Typst expects. Re-check Step 2 — the most common mistake is a missing `0.1.0` folder level or a typo'd folder name.

**`there is no package called 'knitr'`**
Run `install.packages("knitr")` in R.

**Plots missing from the PDF**
Make sure you build from the folder containing your `.typ` file (figures are saved relative to it), and don't delete the `figure/` folder between knitting and compiling.

---

## Repository layout

```
tweave/0.1.0/      the Typst package (template + shorthands)
build.R            knit + compile driver
qmdhooks.r         knitr → Typst output hooks
bin/tweave         launcher script (macOS/Linux)
examples/          worked example with rendered PDF
```

## Why "tweave"?

[Sweave](https://en.wikipedia.org/wiki/Sweave) was the original literate-programming tool for statistics — S (the language R grew out of) + *weave*, running code inside LaTeX documents. knitr carried the wordplay forward (knit + R). tweave is the same idea with Typst taking LaTeX's chair: **T**ypst + **weave**. It also works as a verb, the way `knit` does:

```sh
tweave homework4.typ
```

## License

MIT — see [LICENSE](LICENSE).
