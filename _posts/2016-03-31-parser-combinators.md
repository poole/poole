---
layout: post
author: pedropramos
title: Building a lexer and parser with Scala's Parser Combinators
---


As part of an ongoing project at [**e.near**](http://www.enear.co/), one of our Scala teams was recently tasked with a requirement to build an interpreter for executing workflows which are modelled with a textual DSL. These workflows had to be validated for errors, compiled to a simpler bytecode-like representation and stored, in order to be interpreted with as little overhead as possible.

To deal with the parsing phases, we stumbled upon [Scala's Parser Combinators](https://github.com/scala/scala-parser-combinators), which turned out to be a great tool for writing modular and composable lexers and parsers in idiomatic Scala, with little to no boilerplate code.

While there are a few Web resources on how to use parser combinators for building simple parsers, there were none so far that describe how to build full lexical and syntactical analyzers from scratch.

We will be going through the process of building a lexer, to scan text into a sequence of tokens, and a parser, to parse said tokens into an abstract syntax tree (AST).


### Language overview

In this "workflow code", a program implements a workflow, i.e. an executable directed acyclic graph of instructions. Below is an example of a valid program. Keep in mind that blocks are delimited by [indentation](https://en.wikipedia.org/wiki/Off-side_rule), in a similar way to languages like Python.

```
read input name, country
switch:
  country == "PT" ->
    call service "A"
    exit
  otherwise ->
    call service "B"
    switch:
      name == "unknown" ->
        exit
      otherwise ->
        call service "C"
        exit
```

We want this to be parsed into:

```scala
AndThen(
  ReadInput(List(name, country)),
  Choice(List(
    IfThen(
      Equals(country, PT),
      AndThen(CallService(A), Exit)
    ),
    OtherwiseThen(
      AndThen(
        CallService(B),
        Choice(List(
          IfThen(Equals(name, unknown), Exit),
          OtherwiseThen(AndThen(CallService(C), Exit))
        ))
      )
    )
  ))
)
```

A possible [BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form) representation for this grammar is outlined below.

```
<block> ::= (<statement>)+

<statement> ::= "exit"
              | "read input" (<identifier> ",")* <identifier>
              | "call service" <stringLiteral>
              | "switch" ":" INDENT (<ifThen>)+ [otherwiseThen] DEDENT

<ifThen> ::= <condition> "->" INDENT <block> DEDENT

<otherwiseThen> ::= "otherwise" "->" INDENT <block> DEDENT

<condition> ::= <identifier> "==" <stringLiteral>
```


### Parser combinators

A [parser combinator](https://en.wikipedia.org/wiki/Parser_combinator) is simply a function which accepts parsers as input and returns a new parser as output, similarly to how higher-order functions rely on calling other functions that are passed as input to produce a new function as output.

As an example, assuming we have a parser `int` that recognizes integer literals and a parser `plus` that recognizes the '+' character, we can produce a parser that recognizes the sequence `int plus int` as an integer addition.

The Scala standard library includes an implementation of parser combinators which is hosted at:
<https://github.com/scala/scala-parser-combinators>

To use it, you will simply need the following dependency on your project:
`"org.scala-lang.modules" %% "scala-parser-combinators" % "1.0.4"`


### Building a Lexer

We will be needing tokens for identifiers and string literals, as well as all the reserved keywords and punctuation marks: `exit`, `read input`, `call service`, `switch`, `otherwise`, `:`, `->`, `==`, and `,`.

We also need to produce artifical tokens that represent increases and decreases in identation: `INDENT` and `DEDENT`, respectively. Please ignore these for now, as we will be going over them at later phase.

```scala
sealed trait WorkflowToken

case class IDENTIFIER(str: String) extends WorkflowToken
case class LITERAL(str: String) extends WorkflowToken
case class INDENTATION(spaces: Int) extends WorkflowToken
case object EXIT extends WorkflowToken
case object READINPUT extends WorkflowToken
case object CALLSERVICE extends WorkflowToken
case object SWITCH extends WorkflowToken
case object OTHERWISE extends WorkflowToken
case object COLON extends WorkflowToken
case object ARROW extends WorkflowToken
case object EQUALS extends WorkflowToken
case object COMMA extends WorkflowToken
case object INDENT extends WorkflowToken
case object DEDENT extends WorkflowToken
```

Our lexer extends from [RegexParsers](http://www.scala-lang.org/api/rc/index.html#scala.util.parsing.combinator.RegexParsers), a subtype of [Parsers](http://www.scala-lang.org/api/rc/index.html#scala.util.parsing.combinator.Parsers). `RegexParsers` is tailored for building character parsers using [regular expressions](https://en.wikipedia.org/wiki/Regular_expression). It provides implicit conversions from `String` and `Regex` to `Parser[String]`, allowing us to use them as the starting point for composing increasingly complex parsers.

```scala
object WorkflowLexer extends RegexParsers {
```

Let's start by specifying which characters should be ignored as whitespace. We cannot ignore `\n`, since we need it to recognize the level of identation defined by the number of spaces that follow it. Every other whitespace character can be ignored.

```scala
override def skipWhitespace = true
override val whiteSpace = "[ \t\r\f]+".r
```

Now let's try building a parser for identifiers:

```scala
def identifier: Parser[IDENTIFIER] = {
  "[a-zA-Z_][a-zA-Z0-9_]*".r ^^ { str => IDENTIFIER(str) }
}
```

The `^^` operator acts as a map over the parse result. The regex `"[a-zA-Z_][a-zA-Z0-9_]*".r` is implicitly converted to an instance of `Parser[String]`, on which we map a function `(String => IDENTIFIER)`, thus returning a instance of `Parser[IDENTIFIER]`.

The parsers for string literals and identations are similar:

```scala
def literal: Parser[LITERAL] = {
  """"[^"]*"""".r ^^ { str =>
    val content = str.substring(1, str.length - 1)
    LITERAL(content)
  }
}

def indentation: Parser[INDENTATION] = {
  "\n[ ]*".r ^^ { whitespace =>
    val nSpaces = whitespace.length - 1
    INDENTATION(nSpaces)
  }
}
```

Generating parsers for keywords is trivial:

```scala
def exit          = "exit"          ^^ (_ => EXIT)
def readInput     = "read input"    ^^ (_ => READINPUT)
def callService   = "call service"  ^^ (_ => CALLSERVICE)
def switch        = "switch"        ^^ (_ => SWITCH)
def otherwise     = "otherwise"     ^^ (_ => OTHERWISE)
def colon         = ":"             ^^ (_ => COLON)
def arrow         = "->"            ^^ (_ => ARROW)
def equals        = "=="            ^^ (_ => EQUALS)
def comma         = ","             ^^ (_ => COMMA)
```

We will now compose all of these into a parser capable of recognizing every token. We will take advantage the following operators:

 - `|` (or), for recognizing any of our token parsers;
 - `rep1`, which recognizes one or more repetitions of its argument;
 - `phrase`, which attempts to consume all input until no more is left.

```scala
def tokens: Parser[List[WorkflowToken]] = {
  phrase(rep1(exit | readInput | callService | switch | otherwise | colon | arrow
     | equals | comma | literal | identifier | indentation)) ^^ { rawTokens =>
    processIndentations(rawTokens)
  }
}
```

Note that the order of operands matters when dealing with ambiguity. If we were to place `identifier` before `exit`, `readInput`, etc., our parser would never recognize them as special keywords, since they would be successfully parsed as identifiers instead.


#### Processing indentation

We apply a brief post-processing step to our parse result with the `processIndentations` method. This is used to produce the artifical `INDENT` and `DEDENT` tokens from the `INDENTATION` tokens. Each increase in indentation level will be pushed to a stack, producing an `INDENT`, and decreases in indentation level will be popped from the indentation stack, producing `DEDENT`s.

```scala
private def processIndentations(tokens: List[WorkflowToken],
                                indents: List[Int] = List(0)): List[WorkflowToken] = {
  tokens.headOption match {

    // if there is an increase in indentation level, we push this new level into the stack
    // and produce an INDENT
    case Some(INDENTATION(spaces)) if spaces > indents.head =>
      INDENT :: processIndentations(tokens.tail, spaces :: indents)

    // if there is a decrease, we pop from the stack until we have matched the new level,
    // producing a DEDENT for each pop
    case Some(INDENTATION(spaces)) if spaces < indents.head =>
      val (dropped, kept) = indents.partition(_ > spaces)
      (dropped map (_ => DEDENT)) ::: processIndentations(tokens.tail, kept)

    // if the indentation level stays unchanged, no tokens are produced
    case Some(INDENTATION(spaces)) if spaces == indents.head =>
      processIndentations(tokens.tail, indents)

    // other tokens are ignored
    case Some(token) =>
      token :: processIndentations(tokens.tail, indents)

    // the final step is to produce a DEDENT for each indentation level still remaining, thus
    // "closing" the remaining open INDENTS
    case None =>
      indents.filter(_ > 0).map(_ => DEDENT)

  }
}
```

And we're all set! This token parser will produce a `ParseResult[List[WorkflowToken]]` by consuming a `Reader[Char]`. `RegexParsers` defines its own `Reader[Char]`, which is internally called by the `parse` method it provides. Let's then define an `apply` method for `WorkflowLexer`:

```scala
trait WorkflowCompilationError
case class WorkflowLexerError(msg: String) extends WorkflowCompilationError
```

```scala
object WorkflowLexer extends RegexParsers {
  ...

  def apply(code: String): Either[WorkflowLexerError, List[WorkflowToken]] = {
    parse(tokens, code) match {
      case NoSuccess(msg, next) => Left(WorkflowLexerError(msg))
      case Success(result, next) => Right(result)
    }
  }
}
```

Let's try our lexer on the example above:

```scala
scala> WorkflowLexer(code)
res0: Either[WorkflowLexerError,List[WorkflowToken]] = Right(List(READINPUT, IDENTIFIER(name), COMMA,
IDENTIFIER(country), SWITCH, COLON, INDENT, IDENTIFIER(country), EQUALS, LITERAL(PT), ARROW, INDENT, 
CALLSERVICE, LITERAL(A), EXIT, DEDENT, OTHERWISE, ARROW, INDENT, CALLSERVICE, LITERAL(B), SWITCH, COLON, 
INDENT, IDENTIFIER(name), EQUALS, LITERAL(unknown), ARROW, INDENT, EXIT, DEDENT, OTHERWISE, ARROW, 
INDENT, CALLSERVICE, LITERAL(C), EXIT, DEDENT, DEDENT, DEDENT, DEDENT))
```



### Building a Parser

Now that we have taken care of the lexical analysis, we are still missing the syntactic analysis step, i.e. transforming a sequence of tokens into an abstract syntax tree (AST). Unlike `RegexParsers` which generate `String` parsers, we will be needing a `WorkflowToken` parser.


```scala
object WorkflowParser extends Parsers {
  override type Elem = WorkflowToken
```


We also need to define a `Reader[WorkflowToken]` which will be used by the parser to read from a sequence of `WorkflowToken`s. This is pretty straightforward:


```scala
class WorkflowTokenReader(tokens: Seq[WorkflowToken]) extends Reader[WorkflowToken] {
  override def first: WorkflowToken = tokens.head
  override def atEnd: Boolean = tokens.isEmpty
  override def pos: Position = NoPosition
  override def rest: Reader[WorkflowToken] = new WorkflowTokenReader(tokens.tail)
}
```


Moving on with the parser implementation, the process is similar to the one used to build the lexer. We define simple parsers and compose them into more complex ones. Only this time around our parsers will be returning ASTs instead of tokens:


```scala
sealed trait WorkflowAST
case class AndThen(step1: WorkflowAST, step2: WorkflowAST) extends WorkflowAST
case class ReadInput(inputs: Seq[String]) extends WorkflowAST
case class CallService(serviceName: String) extends WorkflowAST
case class Choice(alternatives: Seq[ConditionThen]) extends WorkflowAST
case object Exit extends WorkflowAST

sealed trait ConditionThen { def thenBlock: WorkflowAST }
case class IfThen(predicate: Condition, thenBlock: WorkflowAST) extends ConditionThen
case class OtherwiseThen(thenBlock: WorkflowAST) extends ConditionThen

sealed trait Condition
case class Equals(factName: String, factValue: String) extends Condition
```


Being a `WorkflowToken` parser, we inherit an implicit conversion from `WorkflowToken` to `Parser[WorkflowToken]`. This is useful for parsing parameterless tokens, such as `EXIT`, `CALLSERVICE`, etc. For `IDENTIFIER` and `LITERAL` we can pattern match on these tokens with the `accept` method.


```scala
private def identifier: Parser[IDENTIFIER] = {
  accept("identifier", { case id @ IDENTIFIER(name) => id })
}

private def literal: Parser[LITERAL] = {
  accept("string literal", { case lit @ LITERAL(name) => lit })
}
```


Grammar rules may be implemented as such:


```scala
def condition: Parser[Equals] = {
  (identifier ~ EQUALS ~ literal) ^^ { case id ~ eq ~ lit => Equals(id, lit) }
}
```


This is similar to what we did previously to produce tokens; here we mapped the parse result (a composition of the results of parsers `identifier`, `EQUALS` and `literal`) to an instance of `Equals`. Notice how pattern matching may be used to expressively unpack the result of a parser composition by sequencing (i.e. the `~` operator).

The implementation of the remaining rules looks very much like the grammar we have specified above:


```scala
def program: Parser[WorkflowAST] = {
  phrase(block)
}

def block: Parser[WorkflowAST] = {
  rep1(statement) ^^ { case stmtList => stmtList reduceRight AndThen }
}

def statement: Parser[WorkflowAST] = {
  val exit = EXIT ^^ (_ => Exit)
  val readInput = READINPUT ~ rep(identifier ~ COMMA) ~ identifier ^^ {
    case read ~ inputs ~ IDENTIFIER(lastInput) => ReadInput(inputs.map(_._1.str) ++ List(lastInput))
  }
  val callService = CALLSERVICE ~ literal ^^ {
    case call ~ LITERAL(serviceName) => CallService(serviceName)
  }
  val switch = SWITCH ~ COLON ~ INDENT ~ rep1(ifThen) ~ opt(otherwiseThen) ~ DEDENT ^^ {
    case _ ~ _ ~ _ ~ ifs ~ otherwise ~ _ => Choice(ifs ++ otherwise)
  }
  exit | readInput | callService | switch
}

def ifThen: Parser[IfThen] = {
  (condition ~ ARROW ~ INDENT ~ block ~ DEDENT) ^^ {
    case cond ~ _ ~ _ ~ block ~ _ => IfThen(cond, block)
  }
}

def otherwiseThen: Parser[OtherwiseThen] = {
  (OTHERWISE ~ ARROW ~ INDENT ~ block ~ DEDENT) ^^ {
    case _ ~ _ ~ _ ~ block ~ _ => OtherwiseThen(block)
  }
}
```


Just like we did with the lexer, we also define a monadic apply method that we can later use to express a pipeline of operations:


```scala
case class WorkflowParserError(msg: String) extends WorkflowCompilationError
```

```scala
object WorkflowParser extends RegexParsers {
  ...

  def apply(tokens: Seq[WorkflowToken]): Either[WorkflowParserError, WorkflowAST] = {
    val reader = new WorkflowTokenReader(tokens)
    program(reader) match {
      case NoSuccess(msg, next) => Left(WorkflowParserError(msg))
      case Success(result, next) => Right(result)
    }
  }
}
```


### Pipelining

We have now covered both the lexical and syntactical analysers. All that's left is to chain them together:


```scala
object WorkflowCompiler {
  def apply(code: String): Either[WorkflowCompilationError, WorkflowAST] = {
    for {
      tokens <- WorkflowLexer(code).right
      ast <- WorkflowParser(tokens).right
    } yield ast
  }
}
```


Let's try it on our sample program:

```scala
scala> WorkflowCompiler(code)
res0: Either[WorkflowCompilationError,WorkflowAST] = Right(AndThen(ReadInput(List(name, country)),
Choice(List(IfThen(Equals(country,PT),AndThen(CallService(A),Exit)),OtherwiseThen(AndThen(CallService(B),
Choice(List(IfThen(Equals(name,unknown),Exit), OtherwiseThen(AndThen(CallService(C),Exit))))))))))
```

Great! Our compiler has proven to be capable of parsing valid programs.


### Error handling

Let's now try to parse a syntactically invalid program. Suppose that we had forgotten to quote `PT` on the first switch case:

```scala
scala> WorkflowCompiler(invalidCode)
res1: Either[WorkflowCompilationError,WorkflowAST] = Left(WorkflowParserError(string literal expected))
```

We get a clear error message reporting an expected string literal, but where? It would be good to know the source location of this error. Luckily for us, Scala's parser combinators supports recording a token's original source location when it is parsed.

In order to do this, and first of all, our `WorkflowToken` and `WorkflowAST` traits must be mixed in with [Positional](http://www.scala-lang.org/api/rc/index.html#scala.util.parsing.input.Positional). This provides a mutable `pos` variable and a `setPos` method which may be used once to decorate an instance with its line and column numbers.

Secondly, we must use the `positioned` operator on each of our parsers. For instance, the parser for the `IDENTIFIER` token would be written as:

```scala
def identifier: Parser[IDENTIFIER] = positioned {
  "[a-zA-Z_][a-zA-Z0-9_]*".r ^^ { str => IDENTIFIER(str) }
}
```

One ugly side effect of the `Positional` mixin is that all of our tokens must now become case classes instead of case objects, since each one now holds mutable state.

Our WorkflowCompilationError subtypes now include the location info...

```scala
case class WorkflowLexerError(location: Location, msg: String) extends WorkflowCompilationError
case class WorkflowParserError(location: Location, msg: String) extends WorkflowCompilationError

case class Location(line: Int, column: Int) {
  override def toString = s"$line:$column"
}
```

...which is reported by each phase's `apply` method:

```scala
def apply(code: String): Either[WorkflowLexerError, List[WorkflowToken]] = {
  parse(tokens, code) match {
    case NoSuccess(msg, next) => Left(WorkflowLexerError(Location(next.pos.line, next.pos.column), msg))
    case Success(result, next) => Right(result)
  }
}
```

Let's now try to parse some invalid code again:

```
scala> WorkflowCompiler(invalidCode)
res1: Either[WorkflowCompilationError,WorkflowAST] = Left(3:14,WorkflowParserError(string literal expected))
```



### Final notes

That's it! We went from a splitting a text stream into a sequence of tokens, to finally assemble them into a typed abstract syntax tree, resulting in a much more effective means to reason about a program.

We can now extend the compiler to perform other non-parsing related tasks, such as validation (for instance, making sure that all code paths end with the `exit` keyword) or the most obvious one: code generation, i.e. traversing this AST to generate a sequence of instructions.

In case you want to keep playing with Scala's parser combinators, the final code used for this tutorial is available at:
<https://github.com/enear/parser-combinators-tutorial>