#import "@local/tweave:0.1.0": *
#show: tweave.with(
  title: "STAT 251 — Homework 4",
  author: "James Bruce",
)

// A little local convenience for prompts — define your own, or pair tweave
// with any homework template from Typst Universe (grape-suite, tinyset, ...)
#let prompt(body) = block(
  fill: luma(246), stroke: (left: 3pt + luma(180)),
  inset: (x: 12pt, y: 10pt), width: 100%,
)[#emph(body)]

```{r}
# Global setup
set.seed(123)   # for reproducibility
digits <- 3     # inline values round to 3 digits
```

= Question 1
#prompt[
  The built-in `faithful` dataset records 272 eruptions of the Old
  Faithful geyser: the duration of each eruption and the waiting time until
  the next one (both in minutes).
]

== (a)
#prompt[Report the mean and standard deviation of the waiting times.]

```{r}
wait <- faithful$waiting
n <- length(wait)
```

Across the `r n` recorded eruptions, the mean waiting time is
`r mean(wait)` minutes with a standard deviation of `r sd(wait)` minutes.

== (b)
#prompt[Plot a histogram of the waiting times. What do you notice?]

```{r}
hist(wait,
     breaks = 20,
     main = "Waiting Time Between Eruptions",
     xlab = "Minutes",
     col = "steelblue")
```

The distribution is clearly _bimodal_: eruptions cluster around short
(about 55 min) and long (about 80 min) waits, so the mean alone is a poor
summary of a "typical" wait.

#line(length: 100%, stroke: 0.5pt)

= Question 2
#prompt[
  Suppose 65% of eruptions are "long" (waiting time above 68 minutes). If a
  visitor watches 8 independent eruptions, what is the probability that
  exactly 6 of them are long?
]

Let $X$ be the number of long eruptions. Then $X ~ "Binomial"(8, 0.65)$, so

$
  P(X = 6) = choose(8, 6) (0.65)^6 (0.35)^2
$ <binom>

```{r}
p6 <- dbinom(6, size = 8, prob = 0.65)
```

Evaluating @binom gives $P(X = 6) = `r p6`$.

#line(length: 100%, stroke: 0.5pt)

= Question 3
#prompt[
  Construct a 95% confidence interval for the true mean waiting time.
]

With $n = `r n`$ observations, the interval is

$
  bar(x) plus.minus t^*_(n-1) s / sqrt(n)
$

```{r, results='hide'}
ci <- t.test(wait)$conf.int   # results='hide': compute now, report inline
```

which evaluates to (`r ci[1]`, `r ci[2]`) minutes. We are 95% confident the
true mean waiting time lies in this interval — though given the bimodality
from Question 1b, the _mean_ wait is not a wait any visitor is likely to
experience.

#line(length: 100%, stroke: 0.5pt)

= Question 4
#prompt[
  Fit the simple linear regression of waiting time on eruption duration.
  State the model, report the fitted slope, and assess its significance.
]

The model is

$
  Y_i = beta_0 + beta_1 x_i + epsilon_i, quad epsilon_i iid "Normal"(0, sigma^2)
$

where $Y_i$ is the waiting time and $x_i$ the duration of eruption $i$.

```{r}
fit <- lm(waiting ~ eruptions, data = faithful)
slope <- coef(fit)[2]
pval <- summary(fit)$coefficients[2, 4]

plot(faithful$eruptions, faithful$waiting,
     main = "Waiting Time vs. Eruption Duration",
     xlab = "Eruption duration (min)",
     ylab = "Waiting time (min)",
     pch = 19, col = "steelblue")
abline(fit, lwd = 2)
```

Each additional minute of eruption predicts a `r slope`-minute longer wait.
The slope is overwhelmingly significant ($p = `r pval`$ — tiny inline values
are rendered automatically in scientific notation), which matches the strong
linear trend visible in the plot.

#v(0.5in)

= Appendix: tweave shorthand cheat sheet

All of these come from the `tweave` Typst package and work in any math block:

#table(
  columns: (auto, auto, auto),
  align: (left, center, left),
  table.header([*Write*], [*Get*], [*Meaning*]),
  [`X iid "Normal"(mu, sigma^2)`], [$X iid "Normal"(mu, sigma^2)$],
    [i.i.d. distribution statement],
  [`bar(x)`], [$bar(x)$], [sample mean (overline, not `|x`)],
  [`choose(n, k)`], [$choose(n, k)$], [binomial coefficient (alias of `binom`)],
  [`integral x f(x) dx`], [$integral x f(x) dx$],
    [`dx`, `dy`, `dz`, `du`, `dv`, `dw`, `dtheta` render as differentials],
)

For question numbering, prompt boxes, and other homework structure, tweave
composes with anything: a homework template from Typst Universe, or a few
`#let` definitions of your own (like `prompt` at the top of this file).
