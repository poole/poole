---
title: "Book Review: Functional and Reactive Domain Modelling"
author: ragb
---

The Book [Functional and Reactive Domain Modeling][book] ([Debasish Ghosh][debasish]) is one of the most interesting books I have read lately, in the realm of Scala.
This is not another beginner Scala book, neither a functional programming primer. It is a much needed tour on domain modeling with functional patterns and concepts, reactive systems and modern software development in Scala. If you want to know how in the world one can use Akka streams, free monads and actors interacting with each other, this book is a great starting point :).

The book is divided roughly into two parts: the first covering functional domain modeling and the second one reactive systems.

It starts with an introduction to [Domain Driven Design][ddd] (DDD) and how it can be applied in a functional context. A Personal Banking domain is introduced which is used through out the text to show examples. The three main traits of reactive applications - Resilience, responsiveness and elasticity - are explained.

Then, basic topics such as purity, thinking in expressions, function composition, effects as values  and  parameterization with generic  types are approached. One really good advice given from the start is to design APIs in an abstract and composable way (including types) decoupling all definitions from the implementation and evaluation. Dependency Injection with the *reader monad* is introduced early on in chapter three.

Chapters 4 and 5, which I recommend for anyone
 working in Scala nowaday, covers typed functional programming topics such as *applicatives*, *Monads*, the *state Monad*, and modeling components as algebras, to encode domain logic and behavior.
Many features of Scala's powerful type system are also pushed further to express complex domain constraints (think phantom types, for instance).

Especially chapter five gives some insight on how to properly organize  functional Scala code, define modules and bounded contexts, compose module behaviors using Kleisli arrows and even further separation of domain definition and implementation using the famous *Free Monad*.

From chapter 6 onwards the book shifts to the reactive applications route. Beginning with asynchronous programming with Futures (and monad transformers!), message driven systems and reativve stream processing  and the actor model are introduced, with [Akka Streams][akkastreams] and [Akka Actors][akkaactors] as the basis. Back pressure on streams is also thoroughly explained.

One relevant lesson from chapter 6, further developed afterwards, is the outlining of the advantages of the actor model (location transparency, mutual exclusion, ...) and, more importantly, its drawbacks (no type safety, not composable,   ...).

Chapters 7 and 8 look in more depth on designing reactive domains and systems, using Akka Streams for most implementation needs, Akka actors when applicable and  failure handling with supervision strategies.

Chapter 8 approaches [Event Sourcing][eventSourcing] and [CQRS][cqrs] for persistence of domain entities and events, comparing it to the usual *CRUD* model and relational database  persistence and querying. Decoupling of Write and Read models is fairly considered, including synchronization patterns.
One major takeaway from this chapter is the modeling of *CQRS* commands as free monads over event algebras.

Chapter 9 talks about testing functional domains. It covers mainly property testing and dataset generation with [Scalacheck][scalacheck]. The last chapter recaps the book contents, with some forward looking considerations on Haskell purity and dependent typing for domain modeling (think languages such as [Idris][idris]).

To end this review, I'd emphasise the fact that the book is filled with examples, patterns and references for material for further exploration. The [acompanying source code repository][code] is, by itself, a very good foundation of patterns and best-practices for functional and reactive programming in Scala.

**Disclaymer**: Neither me  or [e.Near][enear] have any affiliation with the book's author or the publisher.


[enear]: http://www.enear.co
[book]: https://www.manning.com/books/functional-and-reactive-domain-modeling
[code]: https://github.com/debasishg/frdomain
[debasish]: http://debasishg.blogspot.pt
[ddd]: https://en.wikipedia.org/wiki/Domain-driven_design
[akkastreams]: http://doc.akka.io/docs/akka/2.4/scala/stream/index.html
[akkaactors]: http://doc.akka.io/docs/akka/2.4/scala/index-actors.html
[eventSourcing]: https://martinfowler.com/eaaDev/EventSourcing.html
[cqrs]: https://martinfowler.com/bliki/CQRS.html
[scalacheck]: https://www.scalacheck.org
[idris]: http://www.idris-lang.org
