// example2 — a polished report, to show WHY Typst.
// Everything decorative below (title band, stat cards, striped table,
// callout, two-column text) is a handful of lines each. Try that in LaTeX.
//
// We import tweave for its math shorthands but skip its document template —
// this file styles itself, to show you're never locked in.
//
// Convention: the rendered PDF reads as a straight report on the cars.
// All commentary about tweave/Typst lives in comments like this one, so
// read the source alongside the PDF for the tour.

#import "@local/tweave:0.1.0": iid, bar, Normal

#set page(
  paper: "us-letter", margin: (x: 0.9in, y: 0.9in), numbering: "1",
  // Running header from page 2 onward -- one context expression
  header: context if counter(page).get().first() > 1 [
    #text(9pt, luma(120))[Fuel Economy Report #h(1fr) 1974 _Motor Trend_ data]
    #v(-4pt)
    #line(length: 100%, stroke: 0.4pt + luma(200))
  ],
)
#set text(font: "Libertinus Serif", size: 11pt)
#set math.equation(numbering: "(1)")

#let navy = rgb("#1f3a5f")
#let teal = rgb("#0d7377")

// ---- reusable pieces: 3 lines each --------------------------------------
#let statcard(value, label) = block(
  fill: gradient.linear(navy.lighten(88%), teal.lighten(90%)),
  inset: 12pt, radius: 6pt, width: 100%,
)[#text(22pt, weight: "bold", navy)[#value] \ #text(9pt, luma(90))[#upper(label)]]

#let keyfinding(stat, body) = block(
  fill: teal.lighten(88%), stroke: (left: 4pt + teal),
  inset: 14pt, radius: 6pt, width: 100%,
)[#grid(columns: (auto, 1fr), gutter: 16pt, align: horizon,
  text(26pt, weight: "bold", teal.darken(20%))[#stat], body)]

#let note(body) = block(
  fill: rgb("#fff8e1"), stroke: (left: 3pt + rgb("#f9a825")),
  inset: 10pt, radius: 3pt, width: 100%,
)[#text(size: 10pt)[#body]]

#show heading.where(level: 1): it => block(above: 1.6em)[
  #text(navy, weight: "bold")[#it.body]
  #box(width: 1fr, line(length: 100%, stroke: 0.5pt + navy.lighten(50%)))
]

// ---- title band ----------------------------------------------------------
#block(width: 100%, inset: (x: 24pt, y: 20pt), radius: 8pt,
  fill: gradient.linear(navy, teal, angle: 30deg),
)[
  #text(white, 26pt, weight: "bold")[Fuel Economy Report]
  #v(2pt)
  #text(white.transparentize(25%), 11pt)[
    1974 _Motor Trend_ road tests · #datetime.today().display("[month repr:long] [year]") · prepared with tweave
  ]
]



#v(10pt)

// ---- stat cards: R values inside styled Typst blocks ---------------------
#grid(columns: (1fr, 1fr, 1fr), gutter: 12pt,
  statcard([20.09 mpg], [average fuel economy]),
  statcard([-0.87], [correlation, mpg vs.\ weight]),
  statcard([33.9 mpg], [best in test: Toyota Corolla]),
)

= Weight is the story

Across the 32 cars compiled for _Motor Trend_ by
#cite(<henderson1981>, form: "prose"), fuel economy falls sharply with
vehicle weight. A simple linear model

$ "mpg"_i = beta_0 + beta_1 "weight"_i + epsilon_i, quad epsilon_i iid Normal(0, sigma^2) $

estimates that each additional 1,000 lbs costs about
*5.34 mpg* ($R^2 = 0.75$).



#figure(
  image("figure/example2/trends-1.png", width: 96%),
  caption: [Fuel economy against weight (left, with fitted line) and by
    cylinder count (right). Heavier, higher-cylinder cars are thirstier.],
) <trends>

As @trends shows, the relationship is strong and close to linear over the
observed range.

#note[
  *Reading note:* the cylinder-count boxplot mostly restates the weight
  effect — heavier cars have more cylinders. Treat these as one finding,
  not two.
]

= Leaderboard

The efficiency podium is a clean sweep for light four-cylinder imports —
every car in the top five weighs under 2,300 lbs.

#table(
  columns: (1fr, auto, auto, auto),
  align: (left, right, right, right),
  stroke: none,
  fill: (_, y) => if calc.odd(y) { luma(246) },
  table.hline(stroke: 1pt),
  table.header([*Model*], [*MPG*], [*Cylinders*], [*Weight*]),
  table.hline(stroke: 0.5pt),
  [Toyota Corolla], [33.9], [4], [1.83],
  [Fiat 128], [32.4], [4], [2.20],
  [Honda Civic], [30.4], [4], [1.61],
  [Lotus Europa], [30.4], [4], [1.51],
  [Fiat X1-9], [27.3], [4], [1.94],
  table.hline(stroke: 1pt),
)


= Does the transmission matter?



#keyfinding([+7.24 mpg])[
  Manual-transmission cars average *7.24 mpg more* than automatics in
  this sample (Welch $t$-test: $t = 3.77$,
  $p = 0.0014$).
]

Before crowning the stick shift, note the confound: the manual cars here
are also much lighter#footnote[Mean weight 2.41 vs.
3.77 thousand lbs.] -- transmission choice and weight travel together in 1974's lineup.

#table(
  columns: (1fr, auto, auto),
  align: (left, right, right),
  stroke: none,
  fill: (_, y) => if calc.odd(y) { luma(246) },
  table.hline(stroke: 1pt),
  table.header([*Transmission*], [*Mean MPG*], [*Mean weight*]),
  table.hline(stroke: 0.5pt),
  [Automatic], [17.1], [3.77],
  [Manual], [24.4], [2.41],
  table.hline(stroke: 1pt),
)


= Discussion

// Two-column text is one function call; the References section below is a
// one-line #bibliography(...) against a plain BibTeX file (see refs.bib).
#columns(2, gutter: 16pt)[
  The efficiency leaders are all light four-cylinder imports; the sample
  mean of $bar(x) = 20.09$ mpg is dragged down by a tail
  of heavy V8s, several of which manage barely half that figure.

  For 1974 buyers the advice writes itself: weight, not engineering
  exotica, predicts what you'll spend at the pump. For modern readers,
  the dataset remains a friendly reminder that a single well-chosen
  covariate often explains most of the variance. All computation was
  done in R @rcore.
]

#v(6pt)
#bibliography("refs.bib", style: "apa")
