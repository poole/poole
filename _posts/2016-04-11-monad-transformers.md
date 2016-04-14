---
layout: post
author: lmreis89
title: Hands on function composition with monad transformers
---

When using functional programming languages like Scala, developers spend a lot of their time composing functions and effects. One of the most common ways to express composability is to use monads. However, composing functions that return different monads can become quite messy and, without the right tools, quickly turn into a massive headache. That's where **Monad Transformers**, which are the main focus of this post, come in handy!

The focus of this post is not to explain monads and their ability to be transformed as there are already dozens of posts that do that (I will reference some of them in the end of this post). The main goal is to show a concrete example of how transformers can help you in situations where the composability of your code becomes entangled. For the sake of keeping the scope of this text sane, you can think of monads as a design pattern that helps function composability. Furthermore, the only two monads I'll approach in this post are the `Future` and the `Option` monads which are commonly used if you're a Scala developer.

## Composing a simple API
Let's suppose we're using a simple API to query a database in a synchronous way:

```scala
sealed trait Employee {
  val id: String
}
final case class EmployeeWithoutDetails(id: String) extends Employee
final case class EmployeeWithDetails(id: String, name: String, city: String, age: Int) extends Employee

case class Company(companyName: String, employees: List[EmployeeWithoutDetails])

trait SyncDBOps {
  protected def getDetails(employeeId: String): Option[EmployeeWithDetails]
  protected def getCompany(companyName: String): Option[Company]
}
```

From this simple design, the following conclusions are derived:

 1. An `Employee` is either an `EmployeeWithDetails` or an `EmployeeWithoutDetails`
 2. A `Company` has a name and a list of employees without their details
 3. A `SyncDBOps` can fetch a `Company` by its name and an `EmployeeWithDetails` by its id.
 
Suppose we want to create a new software layer on top of this API and expose a single function with the following specification:

 1. Receives two strings - `companyName ; employeeId`
 2. Gets a company using `companyName`
 3. Verifies if that company has an employee with id equal to `employeeId`
 4. Retrieves the employee's age using the `employeeId`

A simple way to do this would be to use `for-comprehensions` and compose the two API calls:

```scala
def getEmployeeAge(employeeId: String, companyName: String): Option[Int] = {
    for {
      company <- getCompany(companyName)
      if company.employees map(_.id) contains employeeId
      details <- getDetails(employeeId)
    } yield details.age
  }
```
If any of the two functions we're calling - `getCompany` and `getDetails` - returns a `None`, the `getEmployeeAge` function will immediately terminate and return `None` as well. This code is quite simple and allows us to compose two function calls that return the `Option` monad in a readable way. 

## Raising the bar for function composition
Let's imagine that in order to try and raise the throughput of our service, we decided to switch our API layer into an asynchronous API that returns `Futures`. The data API would then change into the following code:

```scala
trait AsyncDBOps {
  protected def getDetails(employeeId: String): Future[Option[EmployeeWithDetails]]
  protected def getCompany(companyName: String): Future[Option[Company]]
}
```

We will now try to compose our two API calls and get our employee's age using `Future` of `Option`:

```scala
def getEmployeeAge(employeeId: String, companyName: String): Future[Option[Int]] = {
    for {
      companyOpt: Option[Company] <- getCompany(companyName)
      company: Company = companyOpt.getOrElse(Company("error", List()))
      if company.employees map(_.id) contains employeeId
      detailsOpt: Option[EmployeeWithDetails] <- getDetails(employeeId)
    } yield detailsOpt map (_.age)
  }
```

There are a lot of issues in this code snippet - First of all, we had to add error-case code for the case where the `getCompany` function returns `Future.successful(None)`. Secondly, we introduced a dummy `Company` in case the first function returns `None`. This dummy is introduced so that our `if-guard` isn't only computed when the first `Option` is `Some`. This would be a dramatic change in the semantics of our application as we would be getting an employee's age even if he didn't exist in the company (the company was returned as `None`). By adding the dummy company, we now force the `if-guard` to return false. However, we are forcing the `Future` monad to fail when it didn't! Software that uses this function will now have a hard time distinguishing cases where the `companyName` didn't exist from cases where the `Future` **really** failed.

What a nightmare!

## Monad Transformers

It turns out that this a classical problem in functional programming when composing monads. The answer to it is a design construct called **Monad Transformer**. Summing it up - as there are also multiple posts that cover monad transformers in depth - it allows you to compose functions that return two or more monads. Unfortunately, Scala doesn't come with monad transformers in its standard library. However, there are two functional programming libraries that provide them in Scala: **scalaz** and **cats**. I will be using cats in this post as I found their documentation more detailed than the one provided by scalaz. Now we can change the previous code and start using monad transformers, in particular `OptionT`, to refactor the code:

```scala
import cats.data.OptionT
import cats.std.future._

  def getEmployeeAge(employeeId: String, companyName: String): Future[Option[Int]] = {
    (for {
      company <- OptionT(getCompany(companyName))
      if company.employees map(_.id) contains employeeId
      details <- OptionT(getDetails(employeeId))
    } yield details.age).value
  }
```

As you can see, this snippet is nearly equal to the one provided in the first example! The only code introduced here is that we're now calling the apply function from the `OptionT` monad. The "magic" being done here is that after applying `OptionT(getCompany(companyName))` we now get a `Company`. Not a `Future`, not an `Option`, a `Company`, just like the first example! Scala's `for-comprehension` automatically calls the `flatMap` function for the `OptionT` monad, which is applying the `Future` monad followed by the `Option` monad `flatMap` functions.

With `OptionT`, if the `Future` returns `Failure` or the `Option` returns `None`, the function will immediatelly return with that value. Other than the `OptionT` apply function, only the `.value` function is called. This function transforms the `OptionT` monad back into a `Future[Option[Company]]`. By using `OptionT` we have removed our biggest issue in the previous example where we were changing the semantics of the application when composing functions that used two monads. You can get more details about the implementation of `OptionT` and other monad transformers by going to the cats documentation provided at the end of this post.

## More use cases for monad transformation
Monad transformers aren't only used when composing functions that return two monads in the form `M[F[T]]` where `M` and `F` are distinct monads like in our previous example of `Future[Option[Company]]`. Suppose the API was changed into the following two functions:

```scala
trait HybridDBOps {
  protected def getDetails(employeeId: String): Future[EmployeeWithDetails]
  protected def getCompany(companyName: String): Option[Company]
}
```

This is also a common use case for monad transformers - composing functions that return **different** monads. Let's implement the `getEmployeeAge`  function using `OptionT`:

```scala
def getEmployeeAge(employeeId: String, companyName: String): Future[Option[Int]] = {
    (for {
      company <- OptionT.fromOption(getCompany(companyName))
      if company.employees map(_.id) contains employeeId
      details <- OptionT.liftF(getDetails(employeeId))
    } yield details.age).value
  }
```

The only changes here when compared to the previous example is that we're now using the `OptionT.fromOption` function in the first case, and the `OptionT.liftF` function in the second one. The `fromOption` function creates an `OptionT` from an `Option` monad. It is internally wrapping the return of the `getCompany` function in a `Future.successful` call. The `liftF` function lifts any monad `F` into an `OptionT`. Internally, it is calling the `map` function from the `Future` monad and wrapping the returned `EmployeeWithDetails` in a `Some`. It is important to note that this is just an example and there are more monad transformers like `EitherT`, `ListT`, etc, in both cats and scalaz.

## Conclusion
I hope you enjoyed this post and feel like getting started with function composition using multiple monads. The code used for this post is available at [E.Near's Monad Transformers](https://github.com/enear/Monad-Transformers-Tutorial).

Detailed explanations about monads and monad transformation can be found at:

- [Stephen Boyer blog](https://www.stephanboyer.com/post/83/monads-for-dummies)
- [A Neighborhood of Infinity](http://blog.sigfpe.com/2006/08/you-could-have-invented-monads-and.html)
- [Cats Monad docs](http://typelevel.org/cats/tut/monad.html)
- [Cats OptionT docs](http://typelevel.org/cats/tut/optiont.html)
- [Noel Welsh blog](http://noelwelsh.com/programming/2013/12/20/scalaz-monad-transformers/)
