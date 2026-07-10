// rsetup — R + Typst for statistics homework
// Document template + stats-flavored shorthands

#let qmdtemplate(
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

// A tinted box to visually separate the assignment prompt from your answer
#let questionbox(body) = {
  block(
    fill: rgb("#eef4ff").lighten(30%),
    stroke: (left: 3pt + rgb("#2d5da1").lighten(25%)),
    inset: (x: 12pt, y: 10pt),
    width: 100%,
    radius: 2pt,
    [
      #set text(style: "italic", weight: "medium")
      #body
    ]
  )
}

// Auto-numbered question / subquestion headers
#let question_counter = counter("question")
#let subquestion_counter = counter("subquestion")

#let nextquestion() = {
  question_counter.step()
  subquestion_counter.update(0)
  context [= Question #question_counter.display()]
}

#let subquestion() = {
  subquestion_counter.step()
  context [== #question_counter.display()#subquestion_counter.display("a").]
}

// Math shorthands ------------------------------------------------------

// binom(x, y) can also be written choose(x, y)
#let choose = math.binom

// bar(x) renders as overline(x) (sample mean) instead of |x
#let bar = math.overline

// Quick horizontal rule. Named hline so it doesn't shadow Typst's
// built-in line() function.
#let hline = line(length: 100%, stroke: 0.5pt)

// Differentials: dx instead of "d" x in math mode
#let dx = $"d"x$
#let dy = $"d"y$
#let dz = $"d"z$
#let du = $"d"u$
#let dv = $"d"v$
#let dw = $"d"w$
#let dtheta = $"d"theta$

// Quick vertical gap
#let gap = v(0.5in)

// X iid Normal(mu, sigma^2)
#let iid = $limits(tilde)^"iid"$
