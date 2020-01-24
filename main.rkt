#lang racket/base

(require syntax/parse/define
         racket/format
         racket/list
         (for-syntax racket/base
                     syntax/location
                     racket/syntax
                     syntax/parse
                     syntax/kerncase))

(provide (rename-out [-app #%app]
                     [-top #%top]
                     [-module-begin #%module-begin])
         (except-out (all-from-out racket/base) #%app #%top #%module-begin)
         (all-from-out racket/format))

(define-syntax-parser -app
  [(_ #:ordered x:expr ...)
   #:when (eq? (syntax-property this-syntax 'paren-shape) #\{)
   (syntax/loc this-syntax (let () (sml-begin #f ordered-hash () x ...)))]
  [(_ x:expr ...)
   #:when (eq? (syntax-property this-syntax 'paren-shape) #\{)
   (syntax/loc this-syntax (let () (sml-begin #f hash () x ...)))]
  [(_ x:expr ...)
   #:when (eq? (syntax-property this-syntax 'paren-shape) #\[)
   (syntax/loc this-syntax (let () (sml-begin #f list () x ...)))]
  [(_ x ...+)
   (syntax/loc this-syntax (#%app x ...))])

(define-syntax-parser -top
  [(_ . x:id)
   (define x-str (symbol->string (syntax-e #'x)))
   (cond
     [(regexp-match? #rx":$" x-str)
      (define/syntax-parse new-x
        (format-id this-syntax (substring x-str 0 (sub1 (string-length x-str)))))
      #''new-x]
     [else #'(#%top . x)])])

(define-syntax-parser -module-begin
  [(_ x:id proc:id exprs body ...)
   #'(#%module-begin
      (provide x)
      (sml-begin x proc exprs body ...))])

(define-syntax-parser sml-begin
  [(_ #f proc:id (exprs ...))
   #:with (rev-exprs ...) (reverse (attribute exprs))
   #'(proc rev-exprs ...)]
  [(_ x:id proc:id (exprs ...))
   #:with (rev-exprs ...) (reverse (attribute exprs))
   #'(define x (proc rev-exprs ...))]
  [(_ x proc:id (exprs ...) b1 body ...)
   (define expanded (local-expand #'b1 'module
                                  (append (kernel-form-identifier-list)
                                          (list #'provide #'require))))
   (syntax-parse expanded
     #:literals (begin)
     [(begin b ...)
      #'(sml-begin x proc (exprs ...) b ... body ...)]
     [(id*:id . rest)
      #:when (ormap (lambda (kw) (free-identifier=? #'id* kw))
                    (syntax->list #'(require
                                      provide
                                      define-values
                                      define-syntaxes
                                      begin-for-syntax
                                      module
                                      module*
                                      #%require
                                      #%provide
                                      #%declare)))
      #`(begin #,expanded (sml-begin x proc (exprs ...) body ...))]
     [_
      #`(sml-begin x proc (b1 exprs ...) body ...)])])

(define (ordered-hash . elems)
  (let loop ([pairs '()]
             [elems elems])
    (cond [(null? elems) (reverse pairs)]
          [else
           (loop (cons (cons (first elems) (second elems)) pairs)
                 (cddr elems))])))

(module reader syntax/module-reader
  sml
  #:wrapper1 (λ (t)
               (parameterize ([current-readtable (scribble:make-at-readtable)])
                 (parameterize ([current-readtable (make-str-readtable)])
                   (list* 'doc 'hash '() (t)))))

  (require (prefix-in scribble: scribble/reader)
           syntax/readerr
           racket/list
           racket/port)

  (define (make-info key default use-default)
    (case key
      [(drracket:default-filters) '(("S-Markup Language Sources" "*.sml"))]
      [(drracket:default-extension) "sml"]
      [else (use-default key default)]))

  (define (make-str-readtable #:readtable [base-readtable (current-readtable)])
    (make-readtable base-readtable
                    #\{
                    'terminating-macro
                    (λ (ch port src line col pos)
                      (cond
                        [(eq? #\{ (peek-char port))
                         (define-values (in out) (make-pipe))
                         (write-string "@~a" out)
                         (close-output-port out)
                         (port-count-lines! in)
                         (set-port-next-location! in line col pos)
                         (define res
                           (with-handlers ([exn:fail:read?
                                            (λ (e)
                                              (raise-read-error
                                               "bad syntax"
                                               src
                                               line
                                               col
                                               pos
                                               (srcloc-span (first (exn:fail:read-srclocs e)))))])
                             (read-syntax/recursive
                              src (input-port-append #f in port) #f base-readtable)))
                         (define next (read-char port))
                         (unless (eq? next #\})
                           (raise-read-error "bad syntax" src line col pos 1))
                         res]
                        [else
                         (read-syntax/recursive src port #\{ base-readtable)])))))
