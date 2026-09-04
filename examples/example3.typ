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

```{r}
data(trees)
fit <- lm(Volume ~ Girth, data = trees)
slope <- coef(fit)[2]
r2 <- summary(fit)$r.squared
pred <- fitted(fit)   # plain numeric vector, for the Python bridge below
```

A simple linear fit puts the slope at *`r slope` cubic ft of volume per
inch of girth* ($R^2 =$ `r r2`) — girth alone is a strong stand-in for a
tree's timber yield.

= The same fit, from Python

```{python, fig.width=5, fig.height=3.6, dpi=150}
import numpy as np
import matplotlib
matplotlib.use("Agg")  # headless-safe backend; plt.show() just discards
import matplotlib.pyplot as plt

# r.trees and r.pred reach directly into the R chunk above -- no CSV
# round-trip, no re-fitting from scratch.
girth = np.array(r.trees["Girth"])
volume = np.array(r.trees["Volume"])
pred = np.array(r.pred)

order = np.argsort(girth)
plt.figure(figsize=(5, 3.6))
plt.scatter(girth, volume, color="#33415c", s=28, label="observed")
plt.plot(girth[order], pred[order], color="#c96a1a", lw=2, label="R's fit")
plt.xlabel("Girth (in)")
plt.ylabel("Volume (cu ft)")
plt.legend(frameon=False)
plt.tight_layout()
plt.show()

residual_spread = float(np.std(volume - pred))
```

Python isn't re-fitting anything here — `r.pred` is the fitted-values vector
R just computed, read straight across the bridge and re-drawn in
matplotlib's style. The residual spread computed on the Python side,
`r reticulate::py$residual_spread` cubic ft, is what R reports next.

= Back in R

```{r}
py_resid <- reticulate::py$residual_spread
```

Typical prediction error is about $bar(e) =$ `r py_resid` cubic ft — small
enough, relative to a volume range of `r diff(range(trees$Volume))` cubic
ft, that girth alone is a serviceable field estimate for timber volume.
