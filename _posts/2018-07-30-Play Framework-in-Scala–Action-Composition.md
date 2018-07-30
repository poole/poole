---
layout: post
author: cmteixeira
title: Play Framework in Scala - Action Composition
---


I write this post as a way to consolidate my knowledge on Actions.
Most of what I write is explained on the Play Framework <a href="#play_docs"> docs</a>, although I believe you can benefit from my explanation. The last chapter, <strong><a href="#chaining_actionbuilders">Chaining ActionBuilders</a></strong>, is the most interesting. This topic is under-explained on the docs, making it the most valuable.

<h2> Overview </h2>

In a MVC framework, the Controllers are one of the its 3 layers. They are a bridge between the incoming requests and the business logic.
In the PlayFramework, each controller is a class which is able to generate various <small><strong>Actions</strong></small>. <small><strong>Actions</strong></small> are traits that define how a request should be dealt with. They can be viewed as a function from a Request to a Result.
Action Composition is useful when many of the <small><strong>Actions</strong></small> you want to build share a part of logic.

Imagine for instance, that <strong>no matter</strong> which request you receive to any provided endpoint, you want to log this request and perhaps persist it on a Database.
This logic should be centralized and easily extendable for each action that needs it:

<img class=" size-full wp-image-396 aligncenter" src="https://aerodatablog.files.wordpress.com/2018/06/logging_actionbuilder.png" alt="Logging_ActionBuilder" /> 

<h2> The ActionBuilder </h2>
The trait ActionBuilder facilitates the creation of these Actions that share logic.
Referring to the figure above, for logging to be easily used by any other Action, one creates a custom ActionBuilder trait:


```scala
class LoggingActionBuilder[B](val bodyParser: BodyParser[B])
                             (implicit val executationContext: ExecutionContext) extends ActionBuilder[Request, B]
```

Don't pay attention to bodyParser, ExecutationContext or the type parameter B.
The main thing about this LoggingActionBuilder (and to any other ActionBuilder) is the method:

```scala
def invokeBlock[A](request: Request[A],
                   block: Request[A] => Future[Result]): Future[Result] = {
  Logger.debug(s"Just received the following request: $request")
  block(request)
}
```

This method is abstract on the ActionBuilder trait. It must be defined by us for each custom ActionBuilder we want to define.
The method is important because it is where you describe the common functionality that the Actions build through it must have.
In this case, the common functionality is:
<small><strong>Line 3</strong></small>: Log the Request.
<small><strong>Line 4</strong></small>: Do something else with the request.

Where the "something else" is not yet defined on the LoggingActionBuilder. It is each Action stemming from this ActionBuilder, which, by providing a specific block function, can materialize <small><strong>Line 4</strong></small>.

Consider the following 2 examples which are methods that return an Action and that could be inside a given controller. They would also be associated, on the conf/routes configuration file, with one HTTP method and URI pattern.

```scala
def action1(): Action[_] = LoggingActionBuilder { request =>
  val userId: Option[String] = request.headers.get("userId")
  userId.fold{
    BadRequest("The request did not have a userId on the headers")
  }{ userId =>
    Ok(s"The user id is $userId")
  }
}
```

```scala
def action2(): Action[_]  = LoggingActionBuilder { request =>
  val itemToBuy = request.body.\("itemToBuy").validate[String]
  itemToBuy.fold({
    _ => BadRequest("No valid item to buy on the body of request.")
  },{ item =>
    Ok(s"You are buying $item")
  })
}
```

<strong>About them, we can say:</strong>
1. They are Actions.
2. They are different Actions, i.e., they do different things in response to a given request.
3. They are built from the LoggingActionBuilder, via providing the block function which is referred to on the invokeBlock method of the LoggingActionBuilder.
4. Most importantly, both action1() and action2(), when called, will have their request logged.

<h4> Explanation of the syntax </h4>

Creating an Action from an ActionBuilder consists on calling the apply method of the ActionBuilder. 

```scala
trait ActionBuilder[+R[_], B] {
  final def apply(block: R[B] => Result): Action[B] = ...
  ...
}
```

This apply method takes as argument the block function which "materializes" the Action. On the examples above, the curl brackets are a call to this apply method, and the function inside is the specific block of the Action at hand.

<h2> Changing the type parameter R[_] </h2>

The left type parameter of an ActionBuilder constrains the signature of the block function in the invokeBlock method:

```scala
trait ActionBuilder[+R[_], B] extends ActionFunction[Request, R] {
  def invokeBlock[A](request: Request[A],
                     block: R[A] => Future[Result]): Future[Result]
```

On the custom LoggingActionBuilder we used type Request, where we log a request and then apply the block function to that same request object:

```scala
def invokeBlock[A](request: Request[A],
                   block: Request[A] => Future[Result]): Future[Result] = {
  Logger.debug(s"Just received the following request: $request")
  block(request)
}
```

Often it is convenient that a custom ActionBuilder, via its invokeBlock method, 
takes a request, does something with it, builds an instance of another type, and <strong>only then</strong> applies the block function to that new instance.
Authentication of requests is a good example. Here, a particular request, if authenticated, is normally associated with a User. It is therefore useful to obtain the corresponding instance of User and pass it along, meaning, applying the block function to that instance.
This is useful because now the Actions that are build through this ActionBuilder may count on the existence of an instance of User instead of a raw request. 
This of course changes the signature of the block function that must be provided for the posterior creation of each Action.
A naive AuthenticationActionBuilder could be:

```scala
class AuthenticatedAction[B](val parser: BodyParser[B])
                            (implicit val executionContext: ExecutionContext) 
                            extends ActionBuilder[AuthenticatedUser, B] {

override def invokeBlock[A](request: Request[A],
                            block: AuthenticatedUser[A] => Future[Result]): Future[Result] = {
 val userId: Option[Int] = request.headers.get("user_id")
 val password: Option[String] = request.headers.get("password")

 val user: Option[User] = DataBase.validate(userId, password)

 user.fold {
   Future.successful(BadRequest("Authentication failed"))
 }{ user =>
   val authenticatedUser = AuthenticatedUser(user, request)
   block(authenticatedUser)
 }
 }
}
```

Notice above, that the type parameter of the ActionBuilder changed to  <code>AuthenticatedUser</code> and correspondingly the signature of the block function on the invokeBlock method is <small><code> block: AuthenticatedUser[A] => Future[Result] </code></small>. 
It is up to us to define type AuthenticatedUser[\_]. In this case, it could be something along:
```scala
case class AuthenticatedUser[A](user: User, request: Request[A]) extends WrappedRequest(request)
```

Where type <code>User</code> is our internal representation of a user.
AuthenticatedUser[\_] must be a type constructor, as demanded by the signature of the invokeBlock method of the trait ActionBuilder. 
Also, as mentioned in the references, and explained further below, it is advantageous that this type parameter R[\_] extends WrappedRequest[\_]; which is a type provided by Play.

As a side observation, you can do a trick not to need a type constructor:

```scala
case class AuthenticatedUserHelper(user: User)
type AuthenticatedUser[_] = AuthenticatedUserHelper
```

With this discussion, I have gone through the most important points in creating custom ActionBuilders. This is summarized on the following sketch.

<img class=" size-full wp-image-397 aligncenter" src="https://aerodatablog.files.wordpress.com/2018/06/actionbuilder.png" alt="ActionBuilder" />

<strong>With the image above as guide, an ActionBuilder says:</strong> 
- I make Actions. The Actions that I make share a common logic. 
- That logic is described on my invokeBlock method. 
- invokeBlock is a high-order method, which takes a Request[A] and function called block.
- The block function is what distinguishes every Action made by me. Defining a block function is therefore creating an Action. Although I do not know what the block function will be, I demand it must have the signature R[A] => Result.
- The syntax through which I create an action is: ThisCustomActionBuilder.apply(block), which, given the syntactic sugar surrounding the apply method in Scala, is the same as ActionBuilder(block) or ActionBuilder { request: R[A] => Result }.

<h4> The syntax for creating default Actions </h4>

When you don't need to define a custom ActionBuilder, Play allows you to write Actions with a very intuitive syntax.
```scala
def index(): Action[AnyContent] = Action { request =>
  Ok("`Action` is actually an ActionBuilder with no common functionality.")
}
```

But Action on line 1 is actually a call to a function with a suggestive name (def Action), which returns a default ActionBuilder[Request, AnyContent] which commes along with Play.
Its invokeBlock is just:

```scala
def invokeBlock[A](request: Request[A],
                   block: (Request[A]) => Future[Result]) = block(request)
```

Because the invokeBlock consists of an immediate call to block, this ActionBuilder describes <strong>no</strong> common functionality for the Actions created through it. It is just a helper for when you want to create an Action straight away.

<h2 id="chaining_actionbuilders"> Chaining ActionBuilders </h2>

So, we have a LoggingActionBuilder that logs the requests, and we have a AuthenticationActionBuilder that authenticates the requests.

What if I want to build Actions whose requests I want to both log an authenticate?

<strong>1. Do I need to create a third ActionBuilder that does both?</strong>
This has two downsides. Firstly it duplicates logic. If the way we authenticate a request changes, we would have to remember to change on both ActionBuilders.
Secondly, we would violate the principle of single responsibility, by having the third ActionBuilder both logging and authenticating.
<strong>2. Can I join ActionBuilders ad-hoc? </strong>
This is what we want. It would mean we develop custom ActionBuilders, which can be used separately and independently, but that could also be combined together at will. 

Jumping to the result, it should be something like the following sketch:

<img class=" size-full wp-image-398 aligncenter" src="https://aerodatablog.files.wordpress.com/2018/06/chainingactionbuilders.png" alt="ChainingActionBuilders" />

From my contact with Actions, I get the impression Play's Actions were not planned for composition. The documentation is lacking and there is not really many developers discussing it on StackOverflow.
Still, the problem is underpinned by method <code>andThen</code> of the ActionBuilder.

```scala
trait ActionBuilder[+R[_], B] extends ActionFunction[Request, R] {
  ......
  override def andThen[Q[_]](other: ActionFunction[R, Q]): ActionBuilder[Q, B] = new ActionBuilder[Q, B] {
    ....
    def invokeBlock[A](request: Request[A], block: Q[A] => Future[Result]) =
      self.invokeBlock[A](request, other.invokeBlock[A](_, block))
  }
}
```

The first to notice is <code>andThen</code> returns another ActionBuilder. Meaning, no matter how many ActionBuilders you chain together, the result will also be an ActionBuilder.
This is fortunate since we already know how to deal with ActionBuilders.

The second thing is that the argument for the andThen is an ActionFunction \[probably indicating ActionBuilder chaining is not supposed to be a thing\].
But what we are really interested in is chaining an ActionBuilder with other ActionBuilder, since our motivation is to be able to group two components together who can also work independently and alone (namely the Logging and Authentication ActionBuilders). 

But of course ActionBuilder extends ActionFunction:

```scala
trait ActionBuilder[+L[_], B] extends ActionFunction[Request, L]
```

So here is the main point:
Because on line 3 the left type parameter of the ActionFunction must be R[\_], i.e. the type of the original ActionBuilder <strong>AND</strong> because an ActionBuilder is an ActionFuntion with the left type parameter to Request[\_] then:

```scala
type R[_] = Request
```

In other words, for the argument <em>other</em> of the andThen method to be an ActionBuilder, the original/base ActionBuilder must have its type parameter R[\_] restricted to a sub-type of Request[\_].

Similarly and at the same time, on line 3, the ActionBuilder that results from this chaining has type Q[_], i.e. the type of the second ActionBuilder. Therefore, if the result is also intended to be chained with yet a 3rd ActionBuilder then their type parameter must be also Request[\_].

This means all your ActionBuilders must have their type parameter R[\_] to Request[\_] for chaining.

The above is condensed on the picture below.

<img class=" size-full wp-image-398 aligncenter" src="https://aerodatablog.files.wordpress.com/2018/06/chainingactionbuildersfinal1.png" alt="ChainingActionBuildersFinal" />

Notice in particular that the block function that must be provided by an Action created by the resulting ActionBuilder has its signature constrained by the last on the chain.

Each of the Actions built via the resulting chained ActionBuilder will, upon a request, execute the logic of all the ActionBuilders in the order as they appear on the chain. The flow might stop at any given stage and will not continue forward. For example, if the incoming request is not Authenticated, the logic downstream will not be executed (although the logic upstream will).

<h3> Limitation </h3>
An ActionBuilder, whether simple or the result of chaining several others, does not have access to the body of the request. It abstracts over the body of the request via the type parameter A of the invokeBlock method.
Only the block function has access to it. This means <strong>no</strong> common functionality can be described which needs to access the body of the request, only the headers, parameters and URI.  
 
 &nbsp; 
 
<em>Originally posted on: https://aerodatablog.wordpress.com/</em>

<h4>References</h4>
1. <a id="play_docs" href="https://www.playframework.com/documentation/2.6.x/ScalaActionsComposition"> Action Composition Play Framework Scala 2.6.x Documentation </a>
