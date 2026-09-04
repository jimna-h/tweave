// tweave — R + Typst for statistics documents
// Document template + stats-flavored shorthands

#let tweave(
  title: "Statistics Homework",
  author: "Your Name",
  body
) = {
  // 1. Page & font setup
  set page(
    paper: "us-letter",
    margin: (x: 1in, y: 1in),
    numbering: "1 / 1",
  )
  // "Libertinus Serif" is the current name; "Linux Libertine" kept as a
  // fallback for older Typst installs
  set text(font: ("Libertinus Serif", "Linux Libertine"), size: 12pt)

  // 2. Title block
  align(center)[
    #block(inset: 2.4em)[
      #text(weight: "bold", size: 1.6em)[#title] \
      #v(0.5em)
      #text(size: 1.2em, gray.darken(50%))[#author]
    ]
  ]

  // 3. Heading styling
  show heading: it => {
    set text(blue.darken(70%))
    block(it)
    v(0.5em)
  }

  // 4. Raw block styling (R code and output)
  show raw.where(block: true): it => {
    block(
      width: 100%,
      fill: luma(248),
      inset: 10pt,
      radius: 4pt,
      stroke: 0.5pt + luma(200),
      it
    )
  }

  // 5. Math styling
  set math.equation(numbering: "(1)")

  // 6. Pretty URLs: style links and auto-link bare domains
  show link: underline
  show link: set text(eastern)
  show regex("\b[\w-]+\.[a-z]{2,}(\/\S*)?\b"): it => {
    let txt = it.text
    link("https://" + txt, txt)
  }

  body
}

// Math shorthands ------------------------------------------------------

// binom(x, y) can also be written choose(x, y)
#let choose = math.binom

// bar(x) renders as overline(x) (sample mean) instead of |x
#let bar = math.overline

// Differentials, using Typst's built-in upright dif
#let dx = $dif x$
#let dy = $dif y$
#let dz = $dif z$
#let dt = $dif t$
#let du = $dif u$
#let dv = $dif v$
#let dw = $dif w$
#let dtheta = $dif theta$
#let dphi = $dif phi$
#let dlambda = $dif lambda$

// Hypotheses
#let H0 = $H_0$
#let h0 = $H_0$
#let HA = $H_A$
#let Ha = $H_A$
#let ha = $H_A$

// Distribution names, rendered upright: $X ~ Normal(mu, sigma^2)$
// NB: Gamma and Beta are deliberately NOT defined here -- they would
// shadow Typst's Greek capitals, breaking the gamma function Γ(α) etc.
// Define them yourself if you accept that tradeoff.
#let Normal = math.op("Normal")
#let Uniform = math.op("Uniform")
#let Exponential = math.op("Exponential")
#let Bernoulli = math.op("Bernoulli")
#let Binomial = math.op("Binomial")
#let Poisson = math.op("Poisson")
#let StudentT = math.op("Student-t")
#let ChiSquared = math.op("Chi-squared")
#let FDist = math.op("F")

// X iid Normal(mu, sigma^2)
#let iid = $limits(tilde)^"iid"$

// Support for tweave::typst_vars() -- values that need to sit *inside*
// a complex math expression (a fraction, a square root, an exponent)
// rather than next to one.
//
// Built on Typst's state() rather than a plain dictionary: a plain
// `#let vals = (:)` can't work here, because a package-defined function
// referencing `vals` is bound to *that* variable at its own definition
// site -- it can never see a same-named variable an importing document
// redefines later (val(dict, key), passing the dict explicitly, was an
// earlier, more verbose fix for this same problem). State values are
// specifically designed to be updated later in a document and read
// correctly from anywhere, which is exactly what's needed here.
//
// A results='asis' R chunk calling `typst_vars()` emits
// `#set_vals((...))`, which updates this; val("key") then reads
// whatever was most recently set, from anywhere in the document,
// including deep inside a math expression.
#let tweave-vals = state("tweave-vals", (:))

// Read a value set by typst_vars() / set_vals(). Returns `default`
// (0 unless given) if nothing has set that key yet -- including before
// any asis chunk has run, and in a live preview that never runs R at
// all -- so val("key") is always valid Typst.
#let val(key, default: 0) = context tweave-vals.get().at(key, default: default)

// Set (replace) the values val() reads. Only really meant to be called
// from typst_vars()-generated code, but nothing stops you from calling
// it directly with your own dictionary.
#let set_vals(dict) = tweave-vals.update(dict)
