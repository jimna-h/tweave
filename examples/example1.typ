#import "@local/tweave:0.1.0": *
#show: tweave.with(
  title: "Simply an Example",
  author: "James Bruce",
)

```{r}
# Global Setup
set.seed(123) # for reproducibility
```

#nextquestion() //1
#questionbox[Let's say a boy took a typing test several times to see his wpm typing speed. His results were as follows: 32, 38, 40, 34, 37, 29]

#subquestion() //a
#questionbox[What was the boy's average typing speed?]

```{r}
y <- c(32, 38, 40, 34, 37, 29)
avg_type_speed <- mean(y)
```

The boy's average typing speed is `r avg_type_speed` wpm.

#subquestion() //b
#questionbox[Suppose those tests were done at ages 7, 9, 10, 10, 12, 12. Create a plot showing the boy's typing speed against his age.]

```{r}
x <- c(7, 9, 10, 10, 12, 12)

plot(x, y, 
     main = "Boy's Typing Speed vs. Age",
     xlab = "Age (years)", 
     ylab = "Typing Speed (wpm)",
     pch = 19, 
     col = "blue")

```

#nextquestion() //2
#questionbox[What are ease of life additions to this package you have made?]

These can all be seen in tweave/tweave/0.1.0/tweave.typ : 

=== Easy iid

In a math block, you can simply type "iid" and it will appear as: $iid$

=== Easy gap

Quickly create a gap of this size:
#gap
by typing "\#gap"

=== Easy derivative

This is mostly a solution to my own lazy problem, but for those variables that I most often use in derivatives (x, y, z, u, v, w, $theta$) can be written in math chunks as "dx" rather then "d x".

=== Easy line

This does remove customization features, but one can now create a quick line simply with "\#hline" (named so it doesn't shadow Typst's built-in `line()`):
#hline

=== Bar(x)

Another one that overwrites base Typst, writing "bar(x)" in a math chunk will now produce $bar(x)$ rather than $|x$

=== Choose

In a math chunk, $choose(x, y)$ can still be written as "binom(x, y)", but can now also be written with "choose(x, y)"

=== Question Handling

"\#nextquestion()" --- will go from question 1, question 2, and so on

"\#subquestion()" --- will go from 1a, 1b, and so on

"\#questionbox[]" --- a blue box to easily distinguish questions from the author's responses --- can contain code chunks and formulas:

#questionbox[
Code chunk:
```{r}
y <- c(1, 2, 3, 4, 5)
avg <- mean(y)
```

Formula:
$
  X iid "Normal"(mu, sigma^2)
$
]
