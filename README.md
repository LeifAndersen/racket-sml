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

Any values inside of curly braces (`[` and `]`) becomes a dictionary:

```
#lang sml
title: "A readme file"
author: [{name: "Leif"
          location: "MA"}
         {name: "Ben"
          location: "MA"}]
```

Finally, double curly braces become strings, and can use Racket's `@-expressions` to escape to SML code. For example:

```
#lang sml
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
> (require readme.sml)
> (doc)
'#hash((author . (#hash((location . "Cambridge, Massachusetts") (name . "Leif")) #hash((location . "Bostn, Massachusetts") (name . "Ben")))) (title . "A readme file"))
```

And you can get the data using Racket's dictionary API.