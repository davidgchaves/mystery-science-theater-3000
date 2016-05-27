# Programming `Phoenix` Notes

## 2. The Lay of the Land

- You can think of any web server as a function.
- Each time you type a `URL`, think of it as a function call to some remote server.
- That function takes your request and generates some response.

### `|>`, the *pipe operator*

The `|>`, or *pipe operator*:

- takes the value on the left, and
- passes it as the **first argument** to the function on the right.

We can chain together several different function calls like this:

```elixir
def​ inc(x), ​do​: x + 1
def​ dec(x), ​do​: x - 1

​2
​|> inc
​|> inc
​|> dec
```

We call:

- these compositions *pipes* or *pipelines*,
- each individual function a *segment* or *pipe segment*.

*Pipelines* are also functions, so you can make *pipelines* of *pipelines*.

### A classic `HTTP`-style request in `Phoenix`

```elixir
connection
|> endpoint
|> router
|> pipelines
|> controller
```

- Each request comes in through an `endpoint`, the first point of contact.
- From there, requests go into our `router` layer, which directs a request into the appropriate `controller`, after passing it through a series of `pipelines`.
- A *pipeline* groups functions together to handle common tasks:
	- a `pipeline` for browser requests,
	- a `pipeline` for `JSON` requests.

### Controllers as *pipelines* of functions

```elixir
connection
|> controller
|> common_services
|> action
```

- The `connection` flows into the `controller` and calls `common_services`.
- In `Phoenix`, those `common_services` are implemented with `Plug`.
- `action`s will do many different things:
	- access other websites,
	- authenticate a user,
	- access a database,
	- render a view.

An `action` to show a user:

```elixir
connection
|> find_user
|> view
|> template
```

### Pure vs Impure functions and `Ecto`

In `Phoenix`, whenever it's possible,

- we try to limit side effects (**impure**) to the `controller`.
- we try to keep the functions in our `models` and `views` side effects free (**pure**), so that calling the same function with the same arguments will always yield the same results.

In `Phoenix`, you'll want to separate **pure** from **impure** functions:

- **PURE**: process data in the `model`.
- **IMPURE**: read or write data through the `controller`:
	- call another web server,
	- fetch data from a database.

`Ecto`, the persistence layer, allows us to organize our code in this way, separating:

- the code with side effects, which changes the world around us,
- the code that's only transforming data.

### Pre-requisites

```console
➜  mix local.hex
* creating /Users/***/.mix/archives/hex-0.12.0.ez

➜  mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
* creating /Users/***/.mix/archives/phoenix_new.ez
```

### Creating your first `Phoenix` app

```console
➜  mix phoenix.new hello

➜  cd hello
➜  mix ecto.create
The database for Hello.Repo has been created.

➜  mix phoenix.server
```

### Atom Keys vs. String Keys?

Convention followed throughout `Phoenix`:

- external parameters have string keys `"name" => name`,
- internal paramters have `atom` keys `name: name`

External data can't safely be converted to `atoms`, because the `atom` table isn't garbage-collected. Instead, we explicitly match on the string keys, and then our application boundaries like controllers and channels will convert them into `atom` keys, which we'll rely on everywhere else inside `Phoenix`.

### `Phoenix` file struture

- `config`: configuration.
- `lib`:
	- supervision trees,
	- long-running processes:
		- `Phoenix`'s PubSub system,
		- the database connection pool,
		- ...
	- the code in `lib` **is NOT** reloaded.
- `test`: tests.
- `web`:
	- models, views, templates, controllers, ...
	- the code in `lib` **is** reloaded.

### TODO: Going Deeper: The Request Pipeline

- Plugs are functions.
- Your web applications are pipelines of plugs.

## 3. Controllers, Views, and Templates

### Controllers

Example of a User Controller flow:

```elixir
connection
|> endpoint            # (lib/rumbl/endpoint.ex)
  |> Plug.Static.call
  |> Plug.RequestId.call
  |> Plug.Logger.call
  |> Plug.Parsers.call
  |> Plug.MethodOverride.call
  |> Plug.Head.call
  |> Plug.Session.call
  |> Rumbl.Router.call
|> router              # (web/router.ex)
  |> browser_pipeline
    |> plug ​:accepts​, [​"​​html"​]
    |> plug ​:fetch_session​
    |> plug ​:fetch_flash​
    |> plug ​:protect_from_forgery​
    |> plug ​:put_secure_browser_headers​”
  |> routes
    |> Rumbl.UserController.call
|> UserController     # (web/controllers/user_controller.ex​)
  |> UserController.index
  |> UserView.render("index.html")
```

### Maps vs Structs

Elixir `structs` are built on top of `maps`:

```elixir
defmodule Rumbl.User do
  defstruct [:id, :name, :username, :password]
end
```

Elixir `maps` offer protection for bad keys only at runtime, when we effectively access the key:

```console
iex> user = %{usernmae: "jose", password: "elixir"}
%{password: "elixir", usernmae: "jose"}

iex> user.username
** (KeyError) key :username not found in: %{password: "elixir", usernmae: "jose"}
```

Elixir `structs` offer protection for bad keys at compilation time:


```console
iex> chris = %User{nmae: "chris"}
** (CompileError) iex:3: unknown key :nmae for struct User
```

A `struct` is a `map` that has a `__struct__` key:

```console
iex> jose = %User{name: "Jose Valim"}
%User{id: nil, name: "Jose Valim", username: nil, password: nil}

iex> jose.__struct__
Rumbl.User
```

Elixir `structs` are Elixir's main abstraction for working with structured data.

### Views vs Templates

- Templates are web pages or fragments that allow both static markup and native code to build response pages, compiled into a function.
- Views are modules containing rendering functions that convert data into a format the end user will consume, like HTML or JSON.
- In Phoenix, you eventually compile both to functions.

## 4. `Ecto` and Changesets

### Understanding `Ecto`'s changesets

`Ecto` has a feature called **changesets** that:

- holds all changes you want to perform on the database.
- encapsulates the whole process of receiving external data, casting and validating it before writing it to the database.

### About Models

In `Phoenix`, models, controllers, and views are layers of functions:

- A **controller** is a layer to transform requests and responses according to a communication protocol.
- A **model** is a group of functions to transform data according to our business requirements.

We use the word:

- **schema** to describe the native form of the data,
- **struct** to refer to the data itself (but structs are not models).

The important thing to understand is that the **model** is the layer of functions that supports our business rules rather than the data that flows through those functions.

### Migrations

`Phoenix` uses **migrations** to make the database reflect the structure of our application.

Example:

```console
➜  mix ecto.gen.migration create_user
Compiled web/models/user.ex
Compiled web/views/user_view.ex
* creating priv/repo/migrations
* creating priv/repo/migrations/20160526172142_create_user.exs
```

In general, migrating a database, both up for a successful deploy and down for an unsuccessful deploy, should be an automated and repeatable process.

### More about `Ecto`'s changesets

- `Ecto` is using **changesets** as a bucket to hold everything related to a database change, before and after persistence.
- You can use the information contained inside a **changeset** to do more than see what changed, like:
	- Write code to do the minimal required database operation to update a record.
	- Check a particular change against a database constraint (such as a unique index).
	- Enforce validations without hitting the database.


## 5. Authenticating Users

### Anatomy of a `Plug`

There are two kinds of `plug`s (they work the same):

- `function plugs`: single functions.
- `module plugs`: modules that provides two functions with some configuration details.

Both use the same request interface:

- take a `conn` and optional `opts`,
- return a `conn`.

#### `Module Plugs`

You specify a `module plug` by providing the module name:

```elixir
plug Plug.Logger
```

A `module plug`:

- must have 2 functions:
	- `init(opts)`.
	- `call(conn, opts)`.
- can simply (a `plug` that does nothing):
	- return the given options on `init`.
	- return the given connection on `call`.

```elixir
defmodule DoNothingPlug do
  def init(opts),        do: opts
  def call(conn, _opts), do: conn
end
```

#### `init(opts)`

`init` will happen at **compile time**, being a great place to:

- validate `opts`,
- prepare some of the work,
- do some heavy lifting to transform `opts`.

#### `call(conn, opts)`

`call` will happen at **runtime**:

- It's where the main work of a `module plug` happens.
- We want it to do as little work as possible.

#### Comunication between `init` and `call`

`Plug` uses the result of `init` as the second argument to `call`, that way, `call` can be as fast as possible because `init` has already done the heavy lifting.

#### `Function Plugs`

You specify a `function plug` with the name of the function as an `atom`:

```elixir
plug :protect_from_forgery
```

#### More about `Plug.Conn`

`conn` is only a `Plug.Conn` struct:

- `conn` is the data we pass through every `plug`.
- `conn` has the details for any `request`.
- The `request` is morphed in tiny steps until we eventually send a `response`.
- [Online documentation for Plug.Conn](https://hexdocs.pm/plug/Plug.Conn.html)
