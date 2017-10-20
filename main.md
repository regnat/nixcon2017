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

### Motivation

#### At the very begining…

> Nix won't be complete until it has static typing^[Eelco Dolstra]

#### Maintenance needs

- `nixpkgs`: 1M sloc

- Errors hard to spot

### Why isn't it done yet

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

### We can do the same with types
\inlinetex{{\tiny (more or less)}}

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

## Base type-system

### Base stuff

```nix
let
  f /*: (Int $\to$ Int $\to$ Int) $\wedge$ (Bool $\to$ Bool $\to$ Bool) */
    = x: y: if isInt x then x + y else x && y;
in f
```

```nix
x /*: Int */:
  if x > 0
  then x-1
  else false
```

. . .

```
» Int -> (Int OR false)
```

## Data-structures

### Lists

#### Regular expression lists

```
[ 1 2 true ] /*: [ Int* true "bar"# ] */
[ true "bar" ] /*: [ Int* true "bar"# ] */
```

### Records − General form

#### Syntax of record types

```
{ $x_1$ $\approx$ $\tau_1$; …; $x_n$ $\approx$ $\tau_n$; _ =? $\tau$ }
```

Where `$\approx$` is `=` or `=?`

#### Syntactic sugar

- we can omitt `_ =? Empty` 
- we can replace `_ =? Any` by `..`

### Static records

```
{ x = 1; y = false; z = "foo" }
```

. . .

```
» { x = 1; y = false; z = "foo" }
```

### Dynamic records

```
let
  myFunction /*: Int -> String */ = …;
  x = getEnv "Foo";
in
{ DOLLAR{x} = 1; DOLLAR{myFunction 2} = true }
```

. . .

```
» { _ =? 1 OR true }
```
