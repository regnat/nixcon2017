---
title: A type-system for Nix
author:
- Théophane Hufschmitt
date: October 28 2017
section-titles: false
theme: metropolis
header-includes:
- \usepackage{listings-setup}
- \usepackage{beamer-setup}
- \usepackage{aliases}
- \newcommand{\inlinetex}[1]{#1}
---

# Why

## Nix origins

> Nix won't be complete until it has static typing^[Eelco Dolstra]

### Why it is hard

```nix
lst:
  let
    x = head lst;
    y = head (tail lst);
  in
  if isString x
  then y.DOLLAR{x}
  else x + y
```

# How

### Requirements

- No compilation

- No syntax extension

- Type as much code as possible

- The ill-typed code must still be accepted

## Set-theoretic types

### Need for powerful types <!-- FIXME: very bad title -->

```nix
let
  f = x: y: if isInt x then x + y else x && y;
in f
```

→ Type of `f`?

`Int -> Int -> Int`, but also `Bool -> Bool -> Bool`

### Set-theory to the rescue (1)

IMAGE

## Set-theory to the rescue (2)

#### We can do the same with types
\inlinetex{\tiny (more or less)}

- Union `$\cup$` → `$\vee$`
- Intersection `$\cap$` → `$\wedge$`
- Difference `$\backslash$` → `$\backslash$`
- Inclusion `$\subset$` → `$\subtype$`

### Back to our example

```nix
let
  f = x: y: if isInt x then x + y else x && y;
in f
```

`f` is of type `(Int -> Int -> Int) AND (Bool -> Bool -> Bool)`

## Gradual type

### Impossible to type everything

![nixpkgs loc](img/printscreen-sloc-nixpkgs.png)\ 

### Gradual type { - }

#### Let's introduce "`?`"

- Meaning: "I don't know what the type of this is, I trust you're only
  doing sane things with it"

- Used to type untypeable expressions

\begin{lstlisting}
  let x (*\only<2>{\color{lsttype}/*: ? */ }*)= getEnv "X"; in {y = 1}.DOLLAR{x}
\end{lstlisting}

# What
