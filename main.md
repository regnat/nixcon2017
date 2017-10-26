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
- \usepackage{tikz}
- \usepackage{forest}
- \definecolor{c55ff55}{RGB}{85,255,85}
- \definecolor{cff5555}{RGB}{255,85,85}
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
    y = elemAt lst 1;
  in
  if isString x
  then y.DOLLAR{x}
  else x + y
```

### Impossible to type everything

![nixpkgs loc](img/printscreen-sloc-nixpkgs.png)\ 

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

### Set-theory to the rescue

\begin{center}
\begin{tikzpicture}
  \Huge
  \path[draw=c55ff55,fill=c55ff55,miter limit=4.00,fill opacity=0.392]
    (0,0) ellipse (3 and 2);
  \path[draw=cff5555,fill=cff5555,miter limit=4.00,fill opacity=0.392]
    (3,0) ellipse (3 and 2);
  \path (-1,0) node {A};
  \path (4,0) node {B};

    \path (-1,-4) node (dummy) {};
    \path<2-> (-1,-3) node (ACAPB) {A$\cap$B};
    \path[->,line width=2]<2-> (ACAPB) edge (1,-1);
\end{tikzpicture}
\end{center}
 

### We can do the same with types
\inlinetex{{\tiny (more or less)}}

- `$\cup,\cap,\backslash,\subseteq$` → `$\vee,\wedge,\backslash,\subtype$`
- Singleton types `1`, `true`, `"blah"`, …

### Back to our example

```nix
let
  f = x: y: if isInt x then x + y else x && y;
in f
```

`f` is of type `(Int -> Int -> Int) AND (Bool -> Bool -> Bool)`

## Gradual type

### Gradual type { - }

#### Let's introduce "`?`"

- Represents unknown types

- Used to type untypeable expressions

```
let x = getEnv "X"; in {y = 1}.DOLLAR{x}
```

## Bidirectional typing

### Inference alone not always enough

```
x (*\only<2->{\color{lsttype}/*: \textbf{Int} */ }*): x+1
» (*\color{lstanswer}\textbf{\only<1>{?}\only<2->{Int}}*) -> Int
```

\def\iob{\textbf{Int} $\vee$ \textbf{Bool}}
```
x (*\only<3->{\color{lsttype}/*: \iob */ }*):
  if isInt x then -x else not x
» (*\color{lstanswer}\only<-2>{\textbf{?}}\only<3->{\iob}*) -> (Int OR Bool)
```

### Type reconstruction

\begin{columns}
\begin{column}{0.3\textwidth}
\only<4-7>{\lstinline!$t_x$ = Int!}

\only<6>{\lstinline!$t_y$ = Int!}
\end{column}
\begin{column}{0.7\textwidth}
\begin{forest}
  for tree={fit=rectangle}
[Lambda,tikz={\only<8>{\redbox{Int -> Int -> Int};}} [x]
  [Lambda,fit=rectangle,tikz={\only<7>{\redbox{Int -> Int};}}  [y]
    [Apply,fit=rectangle,tikz={\only<6>{\redbox{Int};}}
      [Apply,tikz={\only<4-5>{\redbox{Int -> Int};}}
        [(+),tikz={\only<2-3>{\redbox{Int -> Int -> Int};}}]
        [x,tikz={\only<3>{\redbox[east][right]{$t_x$};}}] ]
      [y,tikz={\only<5>{\redbox{$t_y$};}}]
    ]
  ]
]
\end{forest}
\end{column}
\end{columns}

### Type checking

\begin{columns}
\begin{column}{0.3\textwidth}
\only<4-10>{\lstinline!$t_x$ = Int!}
\end{column}
\begin{column}{0.7\textwidth}
  \begin{forest}
  for tree={fit=rectangle}
  [Lambda [x]
    [If-then-else
      [Apply
        [isInt] \only<6>{\redbox{(Int -> true) AND ($\lnot$Int -> false)}}
        [x] \only<7>{\redbox{Int}}
      ] \only<5>{\redbox{??}}\only<8-10>{\redbox{true}}
      [-x] \only<9>{\bluebox{Int}}
      [not x] \only<10>{\bluebox(black,fill){}}
    ] \only<4>{\bluebox{Int}}
  ] \only<2>{\bluebox{(Int -> Int) AND (Bool -> Bool)}}
    \only<3>{\bluebox{Int -> Int}}
    \only<11>{\bluebox{Bool -> Bool}}
  \end{forest}

\only<12>{\color{green}
\begin{tikzpicture}[remember picture,overlay,shift={(current page.center)},scale=3]
  \fill(-.5,-.15) -- (-.25,-.5) -- (.5,.2) -- (-.25,-.35) -- cycle;
\end{tikzpicture}
}
\end{column}
\end{columns}

### Checking to the rescue


```
let f /*: (Int -> Int) AND (Bool -> Bool) */
  = x: if isInt x then -x else not x;
in f
» (Int -> Int) AND (Bool -> Bool)
```

### More precision

```
let f(* \only<2>{\color{lsttype}/*: Int $\to$ Bool */} *) = x (* \only<1>{\color{lsttype}/*: Int */} *): ((y: y) x (*\only<1>{\color{lsttype}/*: Bool*/}*))); in f
```

→ \only<1>{Pass}\only<2>{Error}

# What

## Base type-system

### Summary of the features

- Types in comments in normal nix code

- (Hopefully) powerful enough type-system

- Lax by default and safe when needed

    `x: e` $\Leftrightarrow$ `x /*: ? */: e`

## Data-structures

### Lists

#### Regular expression lists

```
[ 1 2 true ] /*: [ Int* true "bar"# ] */
[ true "bar" ] /*: [ Int* true "bar"# ] */
```

. . .

```
[ Int Bool ] $\approx$ (Int, Bool)
```

### Static attribute sets

```
{ x = 1; y = false; z = "foo" }
```

. . .

```
» { x = 1; y = false; z = "foo" }
```

### More attribute sets

```
{ x /*: Int */
, y /*: Int */ ? 1
, ... }:
  x + y
```

. . .

```
» { x = Int, y =? Int, .. } -> Int
```

### Dynamic attribute sets

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

## Extensible system

### Gradual type sometimes unwanted

`(x: x)` is basically an unsafe cast

→ We would sometimes like to have more guaranties

- Don't automatically add gradual types everywhere

- Or even disable the gradual type

### Strict mode {-}

#### Gradual type

```
((x: x) 1) (*\only<2->{\color{blue}/*\# strict-mode */} *)/*: Bool */
```

\only<1>{Typechecks}
\only<2->{Error}

. . .

. . .

#### Records definition

```
let
  x = getEnv "FOO";
  y = getEnv "BAR";
in
{ DOLLAR{x} = 1; DOLLAR{y} = 2; } (*\only<4->{\color{blue}/*\# strict-mode */} *)
```

\only<3>{Typechecks}
\only<4->{Error}

### Control of the gradual type

```
let
  cast = x: x;
in
(*\only<3->{(from\_gradual }*)(cast (*\only<3->{(to\_gradual }*)1(*\only<3->{))}*))
  (*\only<2->{\color{blue}/*\# no-gradual */} *) /*: Bool */
```

\only<1>{Typechecks}
\only<2>{Error}
\only<3->{Typechecks}

### And that's all for today...

#### POC implementation in OCaml

> https://github.com/regnat/tix

#### (Very wip) rewrite in Haskell

> https://github.com/regnat/ptyx
