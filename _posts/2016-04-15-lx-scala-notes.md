---
layout: post
author: jtjeferreira
title: LX Scala
---

On April 9, Scala developers from Portugal, Spain and the UK gathered in Lisbon for [LX Scala](http://www.lxscala.com/) to discuss Scala's present and future trends. These are my notes from the talks...

## [Noel Welsh](https://twitter.com/noelwelsh) - Programming: For the People, By the People
The first talk was Noel's keynote with some inspiring quotes on being a Scala developer right now like "It's a great time to be a Scala developer" and "We're on the right side on history".

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Great way to open the <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://twitter.com/noelwelsh">@noelwelsh</a> <a href="https://t.co/uvXmNncFo1">pic.twitter.com/uvXmNncFo1</a></p>&mdash; rafa paradela (@rafaparadela) <a href="https://twitter.com/rafaparadela/status/718714860498890752">April 9, 2016</a></blockquote>

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/noelwelsh">@noelwelsh</a> <a href="https://twitter.com/hashtag/lxscala?src=hash">#lxscala</a> &quot;we&#39;re on the right side of history&quot; <a href="https://t.co/le98kLpq77">pic.twitter.com/le98kLpq77</a></p>&mdash; João Ferreira (@jtjeferreira) <a href="https://twitter.com/jtjeferreira/status/718715039126056961">April 9, 2016</a></blockquote>

Then Noel explained some issues he experienced when teaching Scala. Stating that human beings have "loss aversion", likewise programmers transitioning to FP from  OO have aversion on abandoning all those nice patterns from GoF (which Noel says "made sense at the time"). Separating concepts from code, by teaching the concepts using diagrams instead of code proved to be good approach.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">I&#39;ve walkways loved the way <a href="https://twitter.com/noelwelsh">@noelwelsh</a> teaches Applicative &amp; other useful type constructors with imgs. <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/N8w9YRDSKF">pic.twitter.com/N8w9YRDSKF</a></p>&mdash; Raúl Raja (@raulraja) <a href="https://twitter.com/raulraja/status/718720800090648576">April 9, 2016</a></blockquote>

He concluded that the "age of exploring (in Scala) is ending" and the community should agree on a Scala "way of doing things"

## [Nick Stanchenko](https://twitter.com/nickstanch) - Unzipping immutability
Nick's talk started by asking how immutable data structures can be fast since one is always copying things around. Using a very nice library called [reftree][reftree] which he wrote for visualizing immutable data structures, it is easy to understand how some operations on Lists, Queues, Vectors, etc are implemented in why they are very efficient.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Nice visualizations from <a href="https://twitter.com/nickstanch">@nickstanch</a> <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/ZgoInI1x29">pic.twitter.com/ZgoInI1x29</a></p>&mdash; João Ferreira (@jtjeferreira) <a href="https://twitter.com/jtjeferreira/status/718734543021154304">April 9, 2016</a></blockquote>

Then Nick introduced the motivation for using a lens library in Scala when doing modifications to immutable data structures, where one has to nest multiple `copy` calls. The examples used [monocle][monocle] but he also mentioned [quicklens][quicklens] to remove boilerplate. Again the usage of reftree made the explanation very clear. For recursive data structures he presented the _Zipper_ concept and a [Scala library that implements it][zipper]

[reftree]: https://github.com/stanch/reftree
[zipper]: https://github.com/stanch/zipper
[monocle]: https://github.com/julien-truffaut/Monocle
[quicklens]: https://github.com/adamw/quicklens

## [Noel Markham](https://twitter.com/noelmarkham) - Practical Scalacheck
Noel talk was about [ScalaCheck][scalacheck], which he called "A bridge between types and values" in the sense that ScalaCheck will generate the values for your richly typed API. The presentation was a very good user guide on using ScalaCheck, but also included very good advices on using the library, like how to avoid reimplementing your business logic again in your ScalaCheck tests, the usage of successful and failed generators, and increasing the number of generated tests in your CI server. He also mentioned the new Cogen typeclass introduced in ScalaCheck 1.13 that allows the creation of better Generators for functions.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Noel Markham of <a href="https://twitter.com/47deg">@47deg</a>: <a href="https://twitter.com/scalacheck">@scalacheck</a> is a bridge between types and values <a href="https://twitter.com/LX_Scala">@LX_Scala</a> <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/kQWYwkBW53">pic.twitter.com/kQWYwkBW53</a></p>&mdash; ussr.io (@ChiefScientist) <a href="https://twitter.com/ChiefScientist/status/718736283602780160">April 9, 2016</a></blockquote>

[scalacheck]: https://www.scalacheck.org/

## [Renato Cavalcanti](https://twitter.com/renatocaval) - Fun.CQRS: a CQRS/ES library for Scala built on top of Akka.
Renato presented a CQRS and EventSourcing library for Scala called [Fun.CQRS][funcqrs]. He started introducing the CQRS (hint: no whats in the tweet bellow) and ES concepts and then presenting a lottery application where the state was persisted between runs in a EventSourcing journal. This library differs from Akka-persistence because it is Akka agnostic and supports different backends, although currently it only supports an Akka backend and an in-memory backend for testing purposes (plans exists for supporting other backends). The library is still in its early stages, but it is currently used in production.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">How to &quot;Cecure your arse in Scala&quot; by <a href="https://twitter.com/renatocaval">@renatocaval</a> <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/YSLiPx4MKB">pic.twitter.com/YSLiPx4MKB</a></p>&mdash; João Ferreira (@jtjeferreira) <a href="https://twitter.com/jtjeferreira/status/718756905514958849">April 9, 2016</a></blockquote>

[funcqrs]: https://github.com/strongtyped/fun-cqrs


## [Michael Barton](https://twitter.com/mrb_barton) - Build your eventually consistent system from scratch
Michael, a self titled "Distributed Systems Amateur", presented how they built their distributed system from scratch using Akka technologies like Akka-cluster, Akka-cluster sharding and Akka-persistence. He also explored the CRDT's from Akka-distributed-data and how it didn't fit their requirements due to the constant propagation of state. Michael referenced some other projects to watch like [gearpump][gearpump] which recently joined Apache Foundation incubation and [orleans][orleans]

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Refreshing honesty at <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> by <a href="https://twitter.com/mrb_barton">@mrb_barton</a> :) <a href="https://t.co/nSVlLOTENc">pic.twitter.com/nSVlLOTENc</a></p>&mdash; Noel Welsh (@noelwelsh) <a href="https://twitter.com/noelwelsh/status/718767878766338048">April 9, 2016</a></blockquote>

[gearpump]: http://www.gearpump.io/overview.html
[orleans]: http://dotnet.github.io/orleans/

## [Alexy Khrabrov](https://twitter.com/ChiefScientist) - Functional Data with Scala

Alexy talked about Scala and functional programming as Killer App for Data, stating that Scala is currently the best language to do data pipelines. He talked about  several interesting projects like [abstract_data][abstract_data], [FiloDB][filo_db], [framian][framian], [algebird][algebird] and other twitter OSS projects, and [deeplearning4j][deeplearning4j]. He mentioned the SMACK stack for big data pipelines, which stands for Scala/Spark, Mesos, Akka, Cassandra and Kafka, and the [noETL][noetl] movement. Finally he played an inspirational video on how Scala is contributing to advances in cancer research.

<iframe width="560" height="315" src="https://www.youtube.com/embed/7vky0HWxMiE" frameborder="0" allowfullscreen></iframe>

[abstract_data]: https://github.com/malcolmgreaves/abstract_data
[filo_db]: https://github.com/tuplejump/FiloDB
[framian]: https://github.com/tixxit/framian
[algebird]: https://github.com/twitter/algebird
[deeplearning4j]: http://deeplearning4j.org/
[noetl]: http://noetl.org/

## [Johann Egger](https://github.com/johannegger) - Scala code analysis at Codacy: Before and after scala.meta

Johann described Codacy's Scala static analysis engine evolution. First they attempted an universal AST (to rule them all?), that would allow Codacy to write generic patterns for all the languages, but in the end the universal AST was not expressive enough because it was too simple and was losing information specific to the language. The second version used [scala.reflect][scala.reflect] to parse the source code to the scala AST, the AST was converted to Json, and the patterns written in Javascript would be executed in node.js or in the browser. However the Json AST and the Javascript patterns were too complex. Enter [scala.meta][scala.meta], where patterns are written in Scala and matching code is much simpler by pattern matching quasiquotes.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Johann Egger from <a href="https://twitter.com/codacy">@Codacy</a> thanking <a href="https://twitter.com/xeno_by">@xeno_by</a> for his great work on Scala.meta <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/bo6zq5PA8J">pic.twitter.com/bo6zq5PA8J</a></p>&mdash; Jaime Jorge (@jaimefjorge) <a href="https://twitter.com/jaimefjorge/status/718816307848720384">April 9, 2016</a></blockquote>

[scala.reflect]: http://docs.scala-lang.org/overviews/reflection/overview.html
[scala.meta]: https://github.com/scalameta/scalameta

## [Patrick Di Loreto](https://twitter.com/patricknoir) - Going Reactive

Patrick described William Hill's new reactive architecture that uses [lambda architecture][lambda_arch] and SMACK stack, which they named _omnia_ platform. The presentation shared many good advices for building an highly scalable platform.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Patrick Di Loreto from <a href="https://twitter.com/williamhill">@williamhill</a> shows the SMACK stack in action!<a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/RublNTlpWM">pic.twitter.com/RublNTlpWM</a></p>&mdash; ussr.io (@ChiefScientist) <a href="https://twitter.com/ChiefScientist/status/718828361951236097">April 9, 2016</a></blockquote>

[lambda_arch]: http://lambda-architecture.net/

## [Danielle Ashley](https://twitter.com/daniashers) - Notes from inappropriate projects
Danielle shared with the audience some personnel projects that she implemented in Scala, and referenced them as inappropriate because choosing Scala to implement an mp3 decoder or a Gameboy emulator isn't a first choice. She shared some tips on the balance between functional purity and runtime performance, like implementing some mutable computation but hide it in a functional API, or avoid object instantiation.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">And then Danielle went for a Nintendo emulator too!!! (Yes, in Scala) <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/EuhKK1uzQ6">pic.twitter.com/EuhKK1uzQ6</a></p>&mdash; Paulo Gaspar (@PauloGaspar7) <a href="https://twitter.com/PauloGaspar7/status/718846162506276864">April 9, 2016</a></blockquote>

## [João Cavalheiro](https://twitter.com/JMCavalheiro) - From no services to MicroServices

João guided us in a journey of transforming a FinTech application from a monolith to a micro-services architecture. He explained the advantages of using Scala in the FinTech industry, due to its complex business models and the required quality of service like high availability, and the easiness to move a team with Java knowledge to a Scala team and the best ways to do that. He explained the migration process and the technologies used to create the first micro-services and the embrace of eventual consistency.

<blockquote class="twitter-tweet" data-lang="en"><p lang="pt" dir="ltr">João Cavalheiro of e.near on Scala in FinTech <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/tM4Qlcpwmq">pic.twitter.com/tM4Qlcpwmq</a></p>&mdash; ussr.io (@ChiefScientist) <a href="https://twitter.com/ChiefScientist/status/718854662712008704">April 9, 2016</a></blockquote>


## [Eric Torreborre](https://twitter.com/etorreborre) - The Eff monad, one monad to rule them all

The last talk was a Keynote from Eric (author of Specs2 test library) about his work on implementing the Eff monad in Scala. He started with the usage of Monad transformers to compose monads, but highlighted its drawbacks, in this way presented the motivating example. The Eff Monad is based on Oleg Kiselyov paper [Freer Monads, More Extensible Effects][freer-paper]. The Eff library is implemented for both cats and scalaz library and provides effects for `Reader`, `Writer`, `Option`, `State` and other monads.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/etorreborre">@etorreborre</a> &quot;eff one monad to rule them all&quot; <a href="https://twitter.com/hashtag/LXScala?src=hash">#LXScala</a> <a href="https://t.co/QnzwP87oGA">pic.twitter.com/QnzwP87oGA</a></p>&mdash; João Ferreira (@jtjeferreira) <a href="https://twitter.com/jtjeferreira/status/718861007863427074">April 9, 2016</a></blockquote>

[freer-paper]: http://okmij.org/ftp/Haskell/extensible/more.pdf

<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
