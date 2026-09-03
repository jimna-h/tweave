// example3 — R and Python in one document, sharing data live.
// Convention (see example2.typ): the rendered PDF reads as a plain report;
// tool commentary lives here in comments.
//
// R fits the model; Python re-plots the same fit with its own styling and
// hands a derived stat back to R -- via reticulate's r.<name> / py$<name>
// bridge, not by re-loading data twice.

#import "@local/tweave:0.1.0": bar

#set page(paper: "us-letter", margin: (x: 0.9in, y: 0.9in), numbering: "1")
#set text(font: "Libertinus Serif", size: 11pt)

#let slate = rgb("#33415c")
#let amber = rgb("#c96a1a")

// Placeholder for tweave::typst_vars() -- see "A value genuinely inside
// an equation" below. Keeps `vals.at(..., default: ...)` valid Typst even
// before that section's chunk has run, so the live preview never breaks.
#let vals = (:)

#show heading.where(level: 1): it => block(above: 1.6em)[
  #text(slate, weight: "bold")[#it.body]
  #box(width: 1fr, line(length: 100%, stroke: 0.5pt + slate.lighten(50%)))
]

#block(width: 100%, inset: (x: 22pt, y: 18pt), radius: 8pt, fill: slate)[
  #text(white, 22pt, weight: "bold")[Black Cherry Trees: Girth vs. Volume]
  #v(2pt)
  #text(white.transparentize(25%), 10pt)[
    R fits the model · Python re-renders it · one shared dataset
  ]
]

= The data and the fit

R's built-in `trees` dataset records girth, height, and usable timber
volume for 31 black cherry trees.

#block(
  fill: luma(240),
  inset: 8pt,
  radius: 4pt,
  width: 100%,
  raw("data(trees)
fit <- lm(Volume ~ Girth, data = trees)
slope <- coef(fit)[2]
r2 <- summary(fit)$r.squared
pred <- fitted(fit)   # plain numeric vector, for the Python bridge below", lang: "r")
)

A simple linear fit puts the slope at *5.0659 cubic ft of volume per
inch of girth* ($R^2 =$ 0.9353) — girth alone is a strong stand-in for a
tree's timber yield.

= The same fit, from Python

#block(
  fill: luma(240),
  inset: 8pt,
  radius: 4pt,
  width: 100%,
  raw("import numpy as np
import matplotlib.pyplot as plt

# r.trees and r.pred reach directly into the R chunk above -- no CSV
# round-trip, no re-fitting from scratch.
girth = np.array(r.trees[\"Girth\"])
volume = np.array(r.trees[\"Volume\"])
pred = np.array(r.pred)

order = np.argsort(girth)
plt.figure(figsize=(5, 3.6))
plt.scatter(girth, volume, color=\"#33415c\", s=28, label=\"observed\")
plt.plot(girth[order], pred[order], color=\"#c96a1a\", lw=2, label=\"R's fit\")
plt.xlabel(\"Girth (in)\")
plt.ylabel(\"Volume (cu ft)\")
plt.legend(frameon=False)
plt.tight_layout()
plt.show()", lang: "python")
)#align(center, image("figure/example3/unnamed-chunk-2-1.png", width: 80%))#block(
  fill: luma(240),
  inset: 8pt,
  radius: 4pt,
  width: 100%,
  raw("
residual_spread = float(np.std(volume - pred))", lang: "python")
)

Python isn't re-fitting anything here — `r.pred` is the fitted-values vector
R just computed, read straight across the bridge and re-drawn in
matplotlib's style. The residual spread computed on the Python side,
4.1125 cubic ft, is what R reports next.

= Back in R

#block(
  fill: luma(240),
  inset: 8pt,
  radius: 4pt,
  width: 100%,
  raw("py_resid <- reticulate::py$residual_spread", lang: "r")
)

Typical prediction error is about $bar(e) =$ 4.1125 cubic ft — small
enough, relative to a volume range of 66.8 cubic
ft, that girth alone is a serviceable field estimate for timber volume.

= A value genuinely inside an equation

The trick above (a symbol in math, its value right next to it in prose)
only works at the *edge* of a math expression. A standard-error formula
needs its values in the middle — under a square root, inside a fraction —
which has no edge to sit at. For that, tweave's `typst_vars()` exposes a
whole dictionary of values as real Typst source, referenced with
`.at("key", default: ...)` anywhere in the expression, including deep
inside one:

#block(
  fill: luma(240),
  inset: 8pt,
  radius: 4pt,
  width: 100%,
  raw("mse <- summary(fit)$sigma^2
sxx <- sum((trees$Girth - mean(trees$Girth))^2)
t_crit <- qt(0.975, df = fit$df.residual)", lang: "r")
)

#let vals = (mse: 18.0794, sxx: 295.4374, t_crit: 2.0452)


$
beta_1 plus.minus t^* dot
sqrt(vals.at("mse", default: 0) / vals.at("sxx", default: 0))
$

which gives a 95% CI of approximately
(4.56,
5.572) cubic ft per inch of
girth. `vals` is defined once, above the first place it's used
(`#let vals = (:)` near the top of this file provides a placeholder so
the live preview always has *something* to resolve `vals` to, even
before this chunk has run).
