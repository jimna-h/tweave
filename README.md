# QMDTemplate (`rsetup`)

**Write your statistics homework in Typst, with live R code — no Quarto required.**

QMDTemplate knits R code chunks embedded in a `.typ` file, then compiles the result straight to PDF. You get Typst's fast, clean typesetting plus reproducible R output: code blocks, console output, plots, and inline values that update every time you build.

It ships with a stats-homework-focused Typst package (`rsetup`) that provides:

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

`build.R` runs your document through **knitr** (an R package that executes the R chunks and inserts their formatted results), then calls `typst compile` on the result. You'll set up a one-word command, `rbuild`, that does both steps for you.

---

## Setup guide (no experience required)

The setup takes about 15 minutes and you only ever do it once. If you get stuck at any step, the [Troubleshooting](#troubleshooting) section at the bottom covers the most common problems.

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

Then install the **knitr** package inside R: open R (or RStudio), and in the console type:

```r
install.packages("knitr")
```

**Check it worked:** close and reopen your terminal (important — it doesn't see newly installed programs until restarted), then run:

```
typst --version
```

If it prints a version number like `typst 0.13.0`, you're good. If it says the command isn't recognized, see Troubleshooting.

### Step 1 — Download this repository

Click the green **Code** button at the top of this GitHub page and choose **Download ZIP**. Unzip it somewhere permanent — somewhere you won't delete or move it later, because the `rbuild` command you set up in Step 3 will point at this folder forever.

Good choice: `C:\Users\YourName\QMDTemplate` (Windows) or `~/QMDTemplate` (macOS).
Bad choice: your Downloads folder or your Desktop clutter pile.

(If you know git: `git clone https://github.com/jimna-h/QMDTemplate` does the same thing.)

### Step 2 — Install the Typst package

Typst looks for locally-installed packages in one specific folder on your computer. We need to copy the `rsetup` folder from this repo into it.

**Windows:**

1. Press **Win + R** (opens the "Run" dialog), paste this, and hit Enter:

   ```
   %LOCALAPPDATA%\typst\packages\local
   ```

   *If Windows says the folder doesn't exist:* open File Explorer, paste `%LOCALAPPDATA%` in the address bar, hit Enter, and create the folders yourself — a folder named `typst`, inside it `packages`, inside that `local`.

2. Copy the entire `rsetup` folder from the repo you downloaded into this `local` folder.

**macOS:** in Finder, press **Cmd + Shift + G**, paste `~/Library/Application Support/typst/packages/local` (create the folders if needed), and copy `rsetup` in.

**Linux:** copy `rsetup` into `~/.local/share/typst/packages/local/`.

**Check it worked:** you should be able to navigate to a file at

```
...\typst\packages\local\rsetup\0.1.0\rsetup.typ
```

The `0.1.0` folder in the middle matters — don't flatten it out.

### Step 3 — Create the `rbuild` command

Right now, building a document would mean typing a long, ugly command every time. Instead we'll teach your terminal a shortcut: `rbuild`.

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

3. **Add the shortcut.** Paste this into Notepad, replacing both paths with *your* Rscript path from step 1 and the folder where *you* unzipped the repo:

   ```powershell
   function rbuild {
       & "C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe" "C:\Users\YourName\QMDTemplate\build.R" $args
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

**Check it worked:** type `rbuild` and hit Enter. If you see an R error about a missing file (rather than *"rbuild is not recognized"*), the shortcut works — it just has no document to build yet.

#### macOS / Linux

The repo includes a small launcher script called `rbuild`. You just need to make it reachable from anywhere. In Terminal, run (adjust the path to where you put the repo):

```sh
chmod +x ~/QMDTemplate/rbuild
sudo ln -s ~/QMDTemplate/rbuild /usr/local/bin/rbuild
```

Line one marks the script as executable; line two creates a link to it in a folder your terminal already searches for commands (`sudo` will ask for your login password — typing it shows nothing on screen, that's normal, just type it and hit Enter).

**Check it worked:** run `rbuild` from any folder. An R error about a missing input file = success.

---

## Writing and building a document

### Start a document

Create a file ending in `.typ` (in VS Code, RStudio, or even Notepad) that starts like this:

````typst
#import "@local/rsetup:0.1.0": *
#show: qmdtemplate.with(
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
rbuild homework4.typ
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

## Troubleshooting

**`typst : The term 'typst' is not recognized...`**
Typst isn't installed, or your terminal was open when you installed it. Close and reopen the terminal first. If it persists, reinstall via `winget install --id Typst.Typst`.

**`rbuild : The term 'rbuild' is not recognized...`**
The profile function didn't load. Restart PowerShell. If it still fails, run `notepad $PROFILE` and confirm your function is actually saved there, and check for the execution-policy error described in Step 3.

**Red error mentioning `Rscript.exe` not found**
The path in your `rbuild` function doesn't match your installed R version (R updates change the folder name, e.g. `R-4.5.2` → `R-4.6.0`). Re-run the `Get-ChildItem` search from Step 3 and update the path in `notepad $PROFILE`.

**`error: package not found ... @local/rsetup:0.1.0`**
The Typst package isn't where Typst expects. Re-check Step 2 — the most common mistake is a missing `0.1.0` folder level or a typo'd folder name.

**`there is no package called 'knitr'`**
Run `install.packages("knitr")` in R.

**Plots missing from the PDF**
Make sure you build from the folder containing your `.typ` file (figures are saved relative to it), and don't delete the `figure/` folder between knitting and compiling.

---

## Repository layout

```
rsetup/0.1.0/      the Typst package (template + shorthands)
build.R            knit + compile driver
qmdhooks.r         knitr → Typst output hooks
rbuild             bash launcher (macOS/Linux)
examples/          worked example with rendered PDF
```

## License

MIT — see [LICENSE](LICENSE).
