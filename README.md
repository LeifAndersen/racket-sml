S-Markup Language
=================

The S-Markup Language is a simple markup language that embeds the full power of the Racket ecosystem.

The top level of an SML file is a set of key-value pairs, with possible definitions. For convenience, keys can be any identifier that ends in a colon (`:`), but technically can be any value. For example:

```
#lang sml

title: "A readme file"
author: me

(define me "Leif")
```

Any values inside of square brackets (`[` and `]`) become a list:

```
#lang sml
title: "A readme file"
author: ["Leif" "Ben"]
```

Any values inside of curly braces (`{` and `}`) becomes a dictionary:

```
#lang sml
title: "A readme file"
author: [{name: "Leif"
          location: "MA"}
         {name: "Ben"
          location: "MA"}]
```

Finally, double curly braces become strings, and can use Racket's `@-expressions` to escape to SML code. For example (using semi-colon for comments):

```
#lang sml ; readme.sml
title: "A readme file"
author: [{name: "Leif"
          location: {{Cambridge, @MA}}}
         {name: "Ben"
          location: {{Boston, @MA}}}]

(define MA "Massachusetts")
```

Otherwise the syntax is that of Racket with s-expressions enabled.

The data in each SML program is provided in a hash table called `doc`. Using the repl with the above program:

```
> (require "readme.sml")
> doc
'#hash((author . (#hash((location . "Cambridge, Massachusetts") (name . "Leif")) #hash((location . "Bostn, Massachusetts") (name . "Ben")))) (title . "A readme file"))
```

And you can get the data using Racket's dictionary API.

Additionally, if you need runtime parameters to build, this can be done with the `#:inputs` keyword:

```
#lang sml ; data.sml
#:inputs (hyperlink)

(define project
  {name: "SML"
   link: "https://github.com/LeifAndersen/racket-sml"})

text:
{{Find SML at @hyperlink[project].}}
```

Now doc is a function that takes the `#:inputs` expression:

```
> (require "data.sml")
> doc
#<procedure:doc>
> (doc (lambda (a) (hash-ref a 'link)))
'#hash((text . "Find SML at https://github.com/LeifAndersen/racket-sml"))
```


# FAQ
## Q: What does the S in SML stand for?

A: Small, Silly, Stupid, Smart, S-Expression, Stunning, Something else? I don't know, you pick.

## Q: How is this related to Standard ML?

A: It's not. Standard ML is awesome though, and you should check out [SML/NJ][smlnj].

## Q: Why another markup language?

A: I had a CV to write, and I got sick of every other markup language. And its only about 100 lines, why not?

[smlnj]: https://www.smlnj.org/
