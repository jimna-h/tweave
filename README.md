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

`build.R` runs your document through **knitr** (which executes the R chunks and injects formatted Typst blocks via the hooks in `qmdhooks.r`), then calls `typst compile` on the result.

## Prerequisites

- [R](https://cran.r-project.org/) with the `knitr` package (`install.packages("knitr")`)
- [Typst CLI](https://github.com/typst/typst/releases) on your `PATH`

## Installation

**1. Install the Typst package locally.** Copy the `rsetup` folder into your local Typst packages directory:

| OS      | Path |
|---------|------|
| Windows | `%LOCALAPPDATA%\typst\packages\local\` |
| macOS   | `~/Library/Application Support/typst/packages/local/` |
| Linux   | `~/.local/share/typst/packages/local/` |

You should end up with `.../local/rsetup/0.1.0/rsetup.typ`.

**2. Set up the `rbuild` command.** Keep `build.R` and `qmdhooks.r` together in this repo (or any folder — `build.R` finds `qmdhooks.r` next to itself).

*macOS / Linux:* add the repo to your `PATH`, or symlink the launcher:

```sh
ln -s /path/to/QMDTemplate/rbuild /usr/local/bin/rbuild
```

*Windows (PowerShell):* add a function to your profile (`notepad $PROFILE`):

```powershell
function rbuild {
    & "C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe" "C:\path\to\QMDTemplate\build.R" $args
}
```

(Find your `Rscript.exe` with: `Get-ChildItem "C:\Program Files\R" -Filter Rscript.exe -Recurse | Select FullName`)

## Usage

Start your document like this:

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

Then build from your project folder:

```sh
rbuild homework4.typ
```

This produces `homework4.knit.typ` (intermediate) and `homework4.knit.pdf`. Figures land in `figure/homework4/`.

### Chunk options

Standard knitr options work: `echo=FALSE` hides code, `include=FALSE` hides everything, `results='hide'` hides console output. Inline numbers round to 4 digits by default; set `digits <- 2` in any chunk to change it.

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
