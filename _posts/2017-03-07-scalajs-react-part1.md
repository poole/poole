---
layout: post
author: pedropramos
title: Building Web applications with Scala.js and React - Part 1
---

As a Scala programmer developing Web applications, it is usually uncomfortable to move from a tidy, functional, and type-safe Scala back-end to an often subpar JavaScript front-end. Luckily for us, there are already some strong and mature alternatives to the Web's (not so) lovely *lingua franca*.

[**Scala.js**](https://www.scala-js.org/) is an implementation of Scala, authored by [Sébastien Doeraene](https://github.com/sjrd), which compiles Scala code to JavaScript (as opposed to JVM bytecode). It supports full bilateral interoperability between Scala and JavaScript code and therefore allows us to develop front-end Web applications in Scala using JavaScript libraries and frameworks. It also promotes less code duplication for a typical Scala Web application by allowing us to reuse the models and business logic developed for the back-end on the front-end.

[**React**](https://facebook.github.io/react/), on the other hand, is a Web framework for building user interfaces in JavaScript, developed and maintained by Facebook and other companies. It promotes a clean separation between declaratively updating the application state as a response to user events and the rendering of the views based on said state. The React framework is therefore particularly suited for the functional programming approach we use when programming in Scala.

We could use React directly in Scala.js, but thankfully [David Barri](https://github.com/japgolly) has authored [**scalajs-react**](https://github.com/japgolly/scalajs-react): a Scala library which provides a set of wrappers for React in order to make it type-safe and friendlier to use in Scala.js. It also provides some useful abstractions, such as the [Callback](https://github.com/japgolly/scalajs-react/blob/master/doc/CALLBACK.md) type: a composable, repeatable, side-effecting computation to be run by React.

This post is the first part of a tutorial on how we're building front-end Web applications at [**e.near**](http://www.enear.co/) using scalajs-react. Part 1 focuses on setting up a pure Scala.js project, while part 2 will focus on mixing Scala.js and "standard" JVM Scala code. I'm assuming you are an intermediate/advanced user of Scala and at least familiar with HTML and the [Bootstrap](http://getbootstrap.com/) framework. Previous experience with JavaScript or the React framework is not required.

The end result will be a simple Web app, using Spotify's public [API](https://developer.spotify.com/web-api/), for looking up artists and listing their albums and tracks (which you can preview [here](/pages/spotify-webapp/)). Although simple, this example should be able to give you an understanding on how to model Web apps in Scala.js React, including reacting to user input, calling a REST API via Ajax, and updating the displayed output.

For reference, all the code showed in this post is available at <https://github.com/enear/scalajs-react-guide-part1>.

### Setup

A quick way to get started with a Scala.js project is to clone Sébastien Doeraene's [example app](https://github.com/sjrd/scala-js-example-app).

You'll need to add in `scalajs-react`'s dependencies:

```scala
libraryDependencies ++= Seq(
  "com.github.japgolly.scalajs-react" %%% "core" % "0.11.3"
)

jsDependencies ++= Seq(
  "org.webjars.bower" % "react" % "15.3.2" / "react-with-addons.js" minified "react-with-addons.min.js" commonJSName "React",
  "org.webjars.bower" % "react" % "15.3.2" / "react-dom.js" minified "react-dom.min.js" dependsOn "react-with-addons.js" commonJSName "ReactDOM",
  "org.webjars.bower" % "react" % "15.3.2" / "react-dom-server.js" minified  "react-dom-server.min.js" dependsOn "react-dom.js" commonJSName "ReactDOMServer"
)
```

The Scala.js SBT plugin introduces the `jsDependencies` setting. It allows SBT to manage JavaScript dependencies using WebJars. These are then compiled to `<project-name>-jsdeps.js`.

To compile our own code, we can run `fastOptJS` (moderate optimizations - for development) or `fullOptJS` (full optimizations - for production) inside an SBT session. This will produce the artifacts `<project-name>-fastopt/fullopt.js` and `<project-name>-launcher.js`. The former contains our compiled code, while the latter is a script which simply calls our main method.

We'll also need an HTML file with an empty `<div>` tag where React will include our rendered content.

```html
<!DOCTYPE html>
<html>
<head>
  <title>Example Scala.js application</title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
</head>
<body>

<div class="app-container" id="playground">
</div>

<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>

<script type="text/javascript" src="./target/scala-2.12/scala-js-react-guide-jsdeps.js"></script>
<script type="text/javascript" src="./target/scala-2.12/scala-js-react-guide-fastopt.js"></script>
<script type="text/javascript" src="./target/scala-2.12/scala-js-react-guide-launcher.js"></script>

</body>
</html>
```

### Building React components

An entrypoint for Scala.js is defined by extending the `JSApp` trait. This will ensure our object and its main method is exported to JavaScript under their fully qualified names.

```scala
object App extends JSApp {

  @JSExport
  override def main(): Unit = {
    ReactDOM.render(TrackListingApp.component(), dom.document.getElementById("playground"))
  }
}
```

`scalajs-react` provides a [Router](https://github.com/japgolly/scalajs-react/blob/master/doc/ROUTER.md) class for managing the multiple React components of an SPA (single-page application), but that is out of the scope for this tutorial, since our app consists of a single React component, which we will render inside the `"playground"` tag.

```scala
object TrackListingApp {

  val component = ReactComponentB[Unit]("Spotify Track Listing")
    .initialState(TrackListingState.empty)
    .renderBackend[TrackListingOps]
    .build
```

All React components must define a `render` method, which returns HTML as a function of its arguments and/or state. Our component requires no arguments, hence the `Unit` type parameter, but it requires a state of type `TrackListingState`. We are delegating this component's rendering to the `TrackListingOps`, where we can define methods that manage our state.

Our app's state will consist of:

```scala
case class TrackListingState(
  artistInput: String,  // a text input for the artist name
  albums: Seq[Album],   // the list of albums to choose from
  tracks: Seq[Track]    // the list of tracks to display
)

object TrackListingState {
  val empty = TrackListingState("", Nil, Nil)
}
```

The `Album` and `Track` types will be defined in the next section.

For other ways to build React components, you may refer to the examples [here](https://github.com/japgolly/scalajs-react/blob/master/doc/USAGE.md#creating-components).

### Calling a REST API

We will need to use 3 endpoints from Spotify's public [API](https://developer.spotify.com/web-api/endpoint-reference/):

METHOD | ENDPOINT | USAGE | RETURNS
--- | --- | --- | ---
GET | `/v1/search?type=artist` | [Search for an artist](https://developer.spotify.com/web-api/search-item/) | [artists](https://developer.spotify.com/web-api/object-model/#artist-object-full)
GET | `/v1/artists/{id}/albums` | [Get an artist's albums](https://developer.spotify.com/web-api/get-artists-albums/) | [albums*](https://developer.spotify.com/web-api/object-model/#album-object-simplified)
GET | `/v1/albums/{id}/tracks` | [Get an album's tracks](https://developer.spotify.com/web-api/get-albums-tracks/) | [tracks*](https://developer.spotify.com/web-api/object-model/#track-object-simplified)

This API returns objects in JSON, which can be natively parsed by JavaScript. We can take advantage of this in Scala.js by defining façade types which act as an interface between Scala's and JavaScript's object models. To do this we annotate a trait with `@js.native` and extend it from `js.Object`.

```scala
@js.native
trait SearchResults extends js.Object {
  def artists: ItemListing[Artist]
}

@js.native
trait ItemListing[T] extends js.Object {
  def items: js.Array[T]
}

@js.native
trait Artist extends js.Object {
  def id: String
  def name: String
}

@js.native
trait Album extends js.Object {
  def id: String
  def name: String
}

@js.native
trait Track extends js.Object {
  def id: String
  def name: String
  def track_number: Int
  def duration_ms: Int
  def preview_url: String
}
```

Finally, we can call Spotify's API asynchronously with Scala.js's [Ajax](http://scala-js.github.io/scala-js-dom/#Extensions) object (which conveniently returns a Future, thus ensuring you don't go down the highway to [callback hell](https://en.wiktionary.org/wiki/callback_hell)).

```scala
object SpotifyAPI {

  def fetchArtist(name: String): Future[Option[Artist]] = {
    Ajax.get(artistSearchURL(name)) map { xhr =>
      val searchResults = JSON.parse(xhr.responseText).asInstanceOf[SearchResults]
      searchResults.artists.items.headOption
    }
  }

  def fetchAlbums(artistId: String): Future[Seq[Album]] = {
    Ajax.get(albumsURL(artistId)) map { xhr =>
      val albumListing = JSON.parse(xhr.responseText).asInstanceOf[ItemListing[Album]]
      albumListing.items
    }
  }

  def fetchTracks(albumId: String): Future[Seq[Track]] = {
    Ajax.get(tracksURL(albumId)) map { xhr =>
      val trackListing = JSON.parse(xhr.responseText).asInstanceOf[ItemListing[Track]]
      trackListing.items
    }
  }

  def artistSearchURL(name: String) = s"https://api.spotify.com/v1/search?type=artist&q=${URIUtils.encodeURIComponent(name)}"
  def albumsURL(artistId: String) =   s"https://api.spotify.com/v1/artists/$artistId/albums?limit=50&market=PT&album_type=album"
  def tracksURL(albumId: String) =    s"https://api.spotify.com/v1/albums/$albumId/tracks?limit=50"
}
```

For more ways to interact with JavaScript code, you may refer to Scala.js's documentation [here](https://www.scala-js.org/doc/interoperability/).

### Rendering the HTML

We now define our `render` method inside `TrackListingOps`, as a function of the state:

```scala
class TrackListingOps($: BackendScope[Unit, TrackListingState]) {

  def render(s: TrackListingState) = {
    <.div(^.cls := "container",
      <.h1("Spotify Track Listing"),
      <.div(^.cls := "form-group",
        <.label(^.`for` := "artist", "Artist"),
        <.div(^.cls := "row", ^.id := "artist",
          <.div(^.cls := "col-xs-10",
            <.input(^.`type` := "text", ^.cls := "form-control",
              ^.value := s.artistInput, ^.onChange ==> updateArtistInput
            )
          ),
          <.div(^.cls := "col-xs-2",
            <.button(^.`type` := "button", ^.cls := "btn btn-primary custom-button-width",
              ^.onClick --> searchForArtist(s.artistInput),
              ^.disabled := s.artistInput.isEmpty,
              "Search"
            )
          )
        )
      ),
      <.div(^.cls := "form-group",
        <.label(^.`for` := "album", "Album"),
        <.select(^.cls := "form-control", ^.id := "album",
          ^.onChange ==> updateTracks,
          s.albums.map { album =>
            <.option(^.value := album.id, album.name)
          }
        )
      ),
      <.hr,
      <.ul(s.tracks map { track =>
        <.li(
          <.div(
            <.p(s"${track.track_number}. ${track.name} (${formatDuration(track.duration_ms)})"),
            <.audio(^.controls := true, ^.key := track.preview_url,
              <.source(^.src := track.preview_url)
            )
          )
        )
      })
    )
  }
```

This may be overwhelming if you're unfamiliar with Bootstrap, but keep in mind that this is nothing more than typed HTML. Tags and attributes are written as methods of objects `<` and `^`, respectively (after importing `japgolly.scalajs.react.vdom.prefix_<^._`).

The odd arrows (`-->` and `==>`) are used for mapping attributes to event handlers, which are defined as [Callbacks](https://github.com/japgolly/scalajs-react/blob/master/doc/CALLBACK.md):
* `-->` takes a simple `Callback` argument
* `==>` takes a `(ReactEvent => Callback)`, which is useful when you need some value that was captured from the triggered event.

You may refer to scalajs-react's documentation [here](https://github.com/japgolly/scalajs-react/blob/master/doc/USAGE.md#creating-virtual-dom) for a more detailed look at how to create virtual DOM.

### Reacting to events

All that's left is to define our event handlers.

Let us have another look at our `TrackListingOps` class definition:

```scala
class TrackListingOps($: BackendScope[Unit, TrackListingState]) {
```

The constructor argument, `$`, provides an interface for updating the application state with `setState` and `modState`. We can define lenses for each of the fields of our state for a more concise updating.

```scala
val artistInputState = $.zoom(_.artistInput)((s, x) => s.copy(artistInput = x))
val albumsState = $.zoom(_.albums)((s, x) => s.copy(albums = x))
val tracksState = $.zoom(_.tracks)((s, x) => s.copy(tracks = x))
```

Now, as you may recall we're using 3 event handlers:
 * `updateArtistInput` when the artist input field changes
 * `updateTracks` when the selected album is changed
 * `searchForArtist` when the search button is pressed

Let us start with `updateArtistInput`:

```scala
def updateArtistInput(event: ReactEventI): Callback = {
  artistInputState.setState(event.target.value)
}
```

The `setState` and `modState` methods don't perform a destructive update when they're called but return the corresponding callback instead, so we're all set.

For `updateTracks`, we need an asynchronous callback, since we must lookup an album's tracks. Luckily, we can convert a `Future[Callback]` into an asynchronous `Callback` with `Callback.future`:

```scala
def updateTracks(event: ReactEventI) = Callback.future {
  val albumId = event.target.asInstanceOf[HTMLSelectElement].value
  SpotifyAPI.fetchTracks(albumId) map { tracks => tracksState.setState(tracks) }
}
```

Finally, let's define `searchForArtist` which requires looking up all 3 endpoints and fully updating our state:

```scala
def searchForArtist(name: String) = Callback.future {
  for {
    artistOpt <- SpotifyAPI.fetchArtist(name)
    albums <- artistOpt map (artist => SpotifyAPI.fetchAlbums(artist.id)) getOrElse Future.successful(Nil)
    tracks <- albums.headOption map (album => SpotifyAPI.fetchTracks(album.id)) getOrElse Future.successful(Nil)
  } yield {
    artistOpt match {
      case None => Callback(window.alert("No artist found"))
      case Some(artist) => $.setState(TrackListingState(artist.name, albums, tracks))
    }
  }
}
```

### Final notes

That concludes the tutorial. If you've made it this far, you should now be able to model front-end Web applications using purely functional constructs in Scala.js. If I've picked your interest, be sure to check out both [Scala.js](https://www.scala-js.org/doc/index.html)'s and [scalajs-react](https://github.com/japgolly/scalajs-react/blob/master/doc/USAGE.md)'s documentation.

Keep posted for part 2, which will focus on building a full-stack Scala Web application and how we can share a set of models and common logic between back-end and front-end code.
