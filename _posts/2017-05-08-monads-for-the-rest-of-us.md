---
layout: post
author: hssousa
title: Monads for the rest of us
---

There are a lot of articles around explaining functional programing and some of the theory and reasoning behind it. Most monad explanations are good if you understand the theory behind it. However, if you come from a practical standpoint, not so much. You will see the running joke that the first rule of Monads is that if once you understand the concept you lose the ability to explain it. This means you should not expect a lot from this post, because either I don’t understand the concept or the explanation is not very good. Either way, the aim here is to prescribe the monad as a good engineering tool.

When you first delve into the functional programing paradigm, there’s a shock. You come from a natural world where objects have a mutable state. You want food on your plate, you invoke “plate.put(food)” and your plate instance gets food on it. Now they want you to make a new plate, which already comes with the food on top!? What about the empty one!? These people must be out of this world! Then you play a little more with immutability and other functional programming concepts. Now one of two things happen: either you look at state and effects as something beautiful you want everywhere or you come to think of it as a necessary evil poison which should be kept within small areas with DANGER signs around. If you're the latter or in doubt, allow me to present you one of our comrades: the monad!

You can think of monads as the space I just described, a small dangerous area where we confine effects. We know we have a effect on a computation and we want to maneuver it with precaution. The multitude of existing monads are just different models created for handling different effects. However, we want this abstraction to hold a few properties (it comes from math after all). Let’s not worry so much about those and look at the implementation and what it can bring for us. Behold, the mighty monad:

```scala
trait Monad[F[_], A] {
  def apply(block: => A): F[A]
  def flatMap[B](f: A => F[B]): F[B]
}
```

Well, that doesn’t look so transcending. It may be confusing at first, so let’s clarify. “A” is the type of the result of the block abstracted within the monad. F[\_] is the type of our monad. Let’s say I’m making a new monad, named “Oven”. The declaration of the “Oven” monad would be:

```scala
sealed trait Oven[A] extends Monad[Oven, A]
```

The Monad trait also holds a couple methods. Let’s dive in on those. The “apply” method makes you able to build a Monad out of a value or a block. It’s a builder method. Then we have the “flatMap” method. This method brings composability between monads of the same type. It receives a function which takes the monad value and returns the same monad of a new type. Why does this bring composability? Because each time you call “flatMap” you will have a Monad, instead of a Monad of a Monad. For instance, using “flatMap” in an instance of Oven[A] with a function (A) => Oven[B] brings you Oven[B] (as opposed to Oven[Oven[B]], which would be the result of a  “map” operation). This makes you compose instead of adding unneeded nesting. We don't want to be cooking ovens, after all. In reality, since we’re dealing with Scala and one of the methods is a builder and the other an operation, we actually want to split this into two traits.

```scala
trait MonadCompanion[F[_]] {
  def apply[A](block: => A): F[A]
}

trait Monad[F[_], +A] {
  def flatMap[B](f: A => F[B]): F[B]
}
```

And our Oven monad would look as such:

```scala
object Oven extends MonadCompanion[Oven] {
  def apply[A](block: => A): Oven[A] = ??? // code that generates an Oven instance
}

class Oven[A] extends Monad[Oven, A] {
  def flatMap[B](f: A => Oven[B]): Oven[B] = ??? // code that composes Ovens.
}
```

Since I’ve given you a hint for monad usage, let’s dive into common monad examples and their use cases. I’ll start with the Option monad, then explain a few other useful Monads. After all we need to get some code written at the end of the day.

### Option

The Option Monad has the purpose of abstracting the presence (or absence) of a value. The value may or not be there. You can think of it as type-safe nullification. Let’s start by implementing our Option possibilities. Either we have Some(value) or None.

```scala
object Option extends MonadCompanion[Option] {
  override def apply[A](block: => A) = {
    val value = block
    if (value == null) None
    else Some(value)
  }
}

sealed trait Option[+A] extends Monad[Option, A]
```

We’re abstracting null by either having a wrapping instance of Some(value) or None if we have a null. You can pass Option around your code not caring whether you have a value. We defined the “apply” on the trait, but left the “flatMap” definition for the extending classes. None is easy:

```scala
case object None extends Option[Nothing] {
  override def flatMap[B](f: (Nothing) => Option[B]): Option[B] = None
}
```

What do you do when you have a function, but no value? You do nothing. Having no value is having no value, regardless of the expected type. “flatMap” does nothing because we don’t have an argument for “f”. In the end it doesn't even matter (good old Linkin Park, anyone?).

```scala
case class Some[A](value: A) extends Option[A] {
  override def flatMap[B](f: (A) => Option[B]): Option[B] = f(value)
}
```

Now we have a value. And “flatMap” is just applying the function to the value we have. Let’s see how it glues together in practice. Let’s say we have a person, that might have a job, which could be at a company (could be a freelancer) and we have the average salary value for some of the companies (they might not disclose it).

```scala
class Person {
  def job: Job = ???
}
class Job {
  def company: Company = ???
}
class Company {
  def averageSalary: Int = ???
}
```

When we have a person instance, how would we get the average salary of that person’s company, if known?

```scala
var avgSalary: Int = null
val job = person.job
if (job != null) {
  val company = job.company
  if (company != null)
    avgSalary = company.averageSalary
}
if (avgSalary != null) {
  // do logic using the salary
}
```

If we want to change the above code to take advantage of the Option, we can do so:

```scala
val avgSalary: Option[Int] = Option(person.job)
  .flatMap(job => Option(job.company))
  .flatMap(company => Option(company.averageSalary))
```

But we can do better. Let’s refactor our classes to use the Option monad.

```scala
class Person {
  def job: Option[Job] = ???
}
class Job {
  def company: Option[Company] = ???
}
class Company {
  def averageSalary: Option[Int] = ???
}
```

Now let’s get the average salary again, if existent:

```scala
val avgSalary: Option[Int] = person.job.flatMap(_.company).flatMap(_.averageSalary)
```

The functionality is there and as long as you’re familiar with the syntax, it’s simple and easy to read. And whenever you need to extract the value you can use pattern matching.

```scala
val avgSalary: Option[Int] = person.job.flatMap(_.company).flatMap(_.averageSalary)
avgSalary match {
  case Some(salary) => // do logic using salary
  case None =>
}
```

### Try

Let’s look at another monad which makes our lives easier: Try. Where Option abstracts nullification, Try encapsulates exception handling. Let’s see the implementation:

```scala
object Try extends MonadCompanion[Try] {
  override def apply[A](block: => A): Try[A] = {
    try {
      Success(block)
    } catch {
      case e: Exception => Failure(e)
    }
  }
}

sealed trait Try[A] extends Monad[Try, A]

case class Success[A](value: A) extends Try[A] {
  override def flatMap[B](f: (A) => Try[B]): Try[B] = f(value)
}

case class Failure[A](exception: Exception) extends Try[A] {
  override def flatMap[B](f: (A) => Try[B]): Try[B] = this.asInstanceOf[Try[B]]
}
```

When writing a try-catch block, you're not forced to deal with the failure. As such, a very common pitfall is that people don't design their code with the assumption that it will fail. Also, multiple exceptions bubbling up is not something easy to reason about when building complex applications.

Using Try you can propagate the error through your application in a simple and explicit way, dealing with the possibility of failure where it is appropriate. If you're building an MVC application maybe you want to deal with the possibility of error on the controller and show a generic error to the user.

Let's say you're building an application where you want to load database configurations from a file, then access the database to do some query, using credentials from that file (please don't try this at home). Both the file and database accesses may throw Exceptions.

```scala
def loadCredentialsFromFile(): Try[DatabaseCredentials] = ???

def executeQuery(query: Query, dbCredentals: DatabaseCredentials): Try[QueryResult] = ???

def queryDB(query: Query): Try[QueryResult] = {
    val credentials: Try[DatabaseCredentials] = loadCredentialsFromFile()
    val queryResult: Try[QueryResult] = credentials.flatMap(executeQuery(query,_))
    queryResult
}
```

Now we can safely deal with whatever happens in the attempt to query the database.

```scala
val queryResult = queryDB(someQueryInstance)
queryResult match {
  case Success(result) => println(s"Yay we have result $result")
  case Failure(e) => println(s"Oh snap! We had an exception saying: ${e.getMessage}")
}
```

After getting used to these constructs you realize that they really offer you a simpler way to reason about what you're developing, more than anything else. I'll give you a last Monad example and then you can go back to being a human (or whatever you are).

### Future

The last Monad that I want to talk to you about is Future. The Future is a Monad which encapsulates asynchronous computations which may fail. It's a non-blocking Try. As a model for asynchronous computations, it receives an implicit ExecutionContext, which determines in the thread that executes it. As the source is harder to grasp on this one, I'll just show you how to use it. First you can import an ExecutionContext provided by the Scala standard library.

```scala
import ExecutionContext.Implicits.global
```

Then you can do instantiate and compose Futures in that scope. Let's say you want to get the first video on YouTube by a given search String and post it on your Facebook account.

```scala
def searchYouTubeAndPostOnFacebook(searchStr: String): Unit = {
  val youtubeSearchResultLink: Future[String] = feelingLuckyOnYoutube(searchStr)
  val post: Future[FacebookStatusUpdate] = youtubeSearchResultLink.flatMap(postToFacebook(_))
  post.forEach { fbStatusUpdate =>
    println("Yay, you have a new Facebook status! Go check it out!")
  }
}
```

The above code will do the print once it's finished posting to Facebook. But wait, what if something fails and it doesn't actually post? It won't print anything. Let's fix that. How can we fix that? I challenge you now to delve into the standard library documentation and do some experiments for yourself. Have fun!

### Wrap up

I've given you an intuition for Monads and why they're a useful engineering tool. If you don't want to go in-depth on the theory behind it, this should be enough for you to get a hands-on start. The Scala standard library contains the Monads presented here but the Monad trait itself is not an actual part of the Scala standard library. The Option, Try and Future implementations provided here are not the same as the actual implementations. These were simplified for the explanation. Also note that the functional programming libraries which do implement a Monad trait do so in a slightly different fashion. I hope to have spiked your interest in these constructs. Have fun!
