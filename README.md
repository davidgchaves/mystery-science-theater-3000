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


## 6. Generators

### Generating `resources`

`Phoenix` includes two `Mix` tasks to bootstrap applications:

- `phoenix.gen.html` creates a simple HTTP scaffold with HTML pages,
- `phoenix.gen.json` creates a simple REST-based API using JSON.

You get **migrations**, **controllers**, and **templates** for basic CRUD operations of a `resource`, as well as **tests** so you can hit the ground running.

#### `phoenix.gen.html`

```console
➜  mix phoenix.gen.html Video videos user_id:references:users url:string title:string description:text
```

Following the `mix phoenix.gen.html` command, we have:

- `Video`, the name of the module that defines the model,
- `videos`, the plural form of the model name,
- `user_id:references:users url:string title:string description:text`, each field, with some type information.


## 7. `Ecto` Queries and Constraints

Instead of treating the database as pure dumb storage, `Ecto` uses the strengths of the database to help keep the data consistent.

### Convention for seeding data

`Phoenix` defines a convention for seeding data. Check the `Phoenix` generated comments at `priv/repo/seeds.exs`.

### Composable `Ecto` Queries

`Ecto` queries are composable, which means you can define the query bit by bit:

```console
➜  iex -S mix

iex(1)> import Ecto.Query
nil
iex(2)> alias MysteryScienceTheater_3000.Repo
nil
iex(3)> alias MysteryScienceTheater_3000.Category
nil

iex(4)> query = Category
MysteryScienceTheater_3000.Category
iex(5)> query = from c in query, order_by: c.name
#Ecto.Query<from c in MysteryScienceTheater_3000.Category,
 order_by: [asc: c.name]>
iex(6)> query = from c in query, select: {c.name, c.id}
#Ecto.Query<from c in MysteryScienceTheater_3000.Category,
 order_by: [asc: c.name], select: {c.name, c.id}>

iex(7)> Repo.all query
[debug] SELECT c0."name", c0."id" FROM "categories" AS c0 ORDER BY c0."name" [] OK query=89.4ms queue=28.2ms
[{"Action", 1}, {"Arthouse", 2}, {"Comedy", 3}, {"Drama", 4}, {"Romance", 5},
 {"Sci-fi", 6}]
```

instead of building the whole query at once:

```console
➜  iex -S mix

iex(1)> import Ecto.Query
nil
iex(2)> alias MysteryScienceTheater_3000.Repo
nil
iex(3)> alias MysteryScienceTheater_3000.Category
nil

iex(4)> query = from c in Category,
...(4)>         order_by: c.name,
...(4)>         select: {c.name, c.id}
#Ecto.Query<from c in MysteryScienceTheater_3000.Category,
 order_by: [asc: c.name], select: {c.name, c.id}>

iex(5)> Repo.all query
[debug] SELECT c0."name", c0."id" FROM "categories" AS c0 ORDER BY c0."name" [] OK query=159.6ms queue=28.7ms
[{"Action", 1}, {"Arthouse", 2}, {"Comedy", 3}, {"Drama", 4}, {"Romance", 5},
 {"Sci-fi", 6}]
```

This strategy works because:

- `Ecto` defines the `queryable` protocol.
- `from` receives a `queryable`, and you can use any `queryable` as a base for a new query.
- `queryable` is an `Elixir` protocol.
- Protocols like `Enumerable` (for Enum) define APIs for specific language features.

Because both `Category` and `query` implement the  `Ecto.Queryable` protocol, we can call `Repo.all` either as:

- `Repo.all(Category)`
- `Repo.all(query)`

By abiding by the protocol, you can quickly layer together sophisticated queries with `Ecto.Query`:

- maintaining clear boundaries between your layers,
- adding sophistication without complexity.

### The `^` (`pin`) operator in `Ecto` Queries

The `^` operator interpolates values into our queries where `Ecto` can scrub them and safely put them to use, without the risk of SQL injection:

```console
iex(4)> username = "andreitarkovsky"
iex(4)> query = from u in User,
...(4)>         where: u.username == ^username
#Ecto.Query<from u in MysteryScienceTheater_3000.User,
 where: u.username == ^"andreitarkovsky">
iex(5)> Repo.one query
```

If you forget the `^` operator, the `Elixir` compiler will yell at you:

```console
iex(6)> query = from u in User,
...(6)>         where: u.username == username
** (Ecto.Query.CompileError) variable `username` is not a valid query expression. Variables need to be explicitly interpolated in queries with ^
    (ecto) expanding macro: Ecto.Query.where/3
           iex:13: (file)
    (ecto) expanding macro: Ecto.Query.from/2
           iex:13: (file)
```

### Differences between traditional vs `Phoenix` MVC (from the perspective of controllers)

We’d like to:

- keep **impure** functions in the **controller**,
- keep **pure** functions in the **model** and **view** layers.

Since `Ecto` splits the responsibilities between:

- the repository,
- its data API,

it fits our world view perfectly:

1. When a **request** comes in, the **controller** is invoked.
2. The **controller** might read data from the socket (**an IO side effect**) and parse it into data structures (like the `params` map).
3. When we have the parsed data (like the `params` map), we send it to the **model**, which transforms those parameters into `Ecto changesets` or `Ecto queries`.
4. `Elixir structs`, `Ecto changesets`, and `Ecto queries` are just data, we can build or transform (**no side effects**) any of them by passing them from function to function, slightly modifying the data on each step.
5. When we've molded the data to the shape of our business-model requirements, we invoke the entities that can change the world around us (**side effects**, again), like:
	- the repository (`Repo`),
	- the system responsible for delivering emails (`Mail`).
6. Finally, we can invoke the **view**.
7. The **view** converts
	- the **model data**, such as:
		- `Ecto changesets`,
		- `Elixir structs`,
	- into **view data**, such as:
		- `JSON maps`
		- `HTML strings`...
8. ...which is then written to the socket via the **controller** (**a side effect**).
9. Because the **controller** already encapsulates **IO side effects** (by reading and writing to the socket), it's the perfect place to put interactions with the repository, while the **model** and **view** layers are kept **pure**.

The same strategy that improves the manageability of our code will also make our code easier to test.

### Writing `Ecto` Queries

The query syntax you choose depends on your taste and the problems you're trying to solve:

- with `Keywords`: probably more convenient for pulling together ad-hoc queries and solving one-off problems.
- with `|>`s: probably better for building an application’s unique complex layered query API.

Each approach has its advantages.

### Writing `Ecto` Queries with `Keywords` Syntax

Expresses different parts of the query by using a `keyword` list (key-value pairs):

```console
➜  iex -S mix

iex(1)> import Ecto.Query
iex(2)> alias MysteryScienceTheater_3000.Repo
iex(3)> alias MysteryScienceTheater_3000.User

iex(4)> users_count = from u in User,
...(4)>               select: count(u.id)
#Ecto.Query<from u in MysteryScienceTheater_3000.User, select: count(u.id)>

iex(5)> ingmar_users_count = from u in users_count,
...(5)>                      where: ilike(u.username, ^"ingmar%")
#Ecto.Query<from u in MysteryScienceTheater_3000.User,
 where: ilike(u.username, ^"ingmar%"), select: count(u.id)>

iex(6)> Repo.one users_count
[debug] SELECT count(u0."id") FROM "users" AS u0 [] OK query=0.6ms
10

iex(7)> Repo.one ingmar_users_count
[debug] SELECT count(u0."id") FROM "users" AS u0 WHERE (u0."username" ILIKE $1) ["ingmar%"] OK query=0.7ms
1
```

### Writing `Ecto` Queries with `|>`s

Expresses different parts of the query with the `|>` operator:

```console
➜  iex -S mix

iex(1)> import Ecto.Query
iex(2)> alias MysteryScienceTheater_3000.Repo
iex(3)> alias MysteryScienceTheater_3000.User

iex(4)> User |>
...(4)>   select([u], count(u.id)) |>
...(4)>   where([u], ilike(u.username, ^"ingmar%")) |>
...(4)>   Repo.one()
[debug] SELECT count(u0."id") FROM "users" AS u0 WHERE (u0."username" ILIKE $1) ["ingmar%"] OK query=1.5ms
1
```

### Writing `Ecto` Query `Framents`

A programming truism is that the best abstractions offer an escape hatch, one that exposes the user to one deeper level of abstraction on demand.

`Ecto` has such a feature, called the `query fragment`.

A `query fragment` sends part of a query directly to the database but allows you to construct the query string in a safe way:

```console
➜  iex -S mix

iex(1)> import Ecto.Query
iex(2)> alias MysteryScienceTheater_3000.Repo
iex(3)> alias MysteryScienceTheater_3000.User

iex(4)> ingmar_bergman = "IngmarBergman"

iex(5)> ingmar_bergman_query =
...(5)>   from u in User,
...(5)>   where: fragment("lower(username) = ?", ^String.downcase(ingmar_bergman))
#Ecto.Query<from u in MysteryScienceTheater_3000.User,
 where: fragment("lower(username) = ?", ^"ingmarbergman")>

iex(6)> ingmar_bergman_count_query =
...(6)>   from u in ingmar_bergman_query,
...(6)>   select: count(u.id)
#Ecto.Query<from u in MysteryScienceTheater_3000.User,
 where: fragment("lower(username) = ?", ^"ingmarbergman"), select: count(u.id)>

iex(7)> Repo.one ingmar_bergman_count_query
[debug] SELECT count(u0."id") FROM "users" AS u0 WHERE (lower(username) = $1) ["ingmarbergman"] OK query=113.8ms queue=30.5ms
1
```

Whether the interpolated values are `Ecto` query expressions or Postgres SQL fragments, `Ecto` safely escapes all interpolated values.

### `Ecto.Adapters.SQL.query`

When everything else fails and even `fragments` aren’t enough, you can always run direct SQL with `Ecto.Adapters.SQL.query`.

```console
➜  iex -S mix

iex(1)> alias MysteryScienceTheater_3000.Repo

iex(2)> Ecto.Adapters.SQL.query(
...(2)>   Repo,
...(2)>   "SELECT power($1, $2)",
...(2)>   [2, 10]
...(2)> )
[debug] SELECT power($1, $2) [2, 10] OK query=2.7ms
{:ok,
 %{columns: ["power"], command: :select, connection_id: 81445, num_rows: 1,
   rows: [[1024.0]]}}
```

It's best to stick to `Ecto` query expressions wherever possible, but you have a safe escape hatch when you need it.

### Querying Relationships

Very basic example:

```console
➜  iex -S mix

iex(1)> import Ecto.Query
iex(2)> alias MysteryScienceTheater_3000.Repo
iex(3)> alias MysteryScienceTheater_3000.User

iex(4)> query = from u in User,
...(4)>         limit: 1,
...(4)>         preload: [:videos]
#Ecto.Query<from u in MysteryScienceTheater_3000.User, limit: 1,
 preload: [:videos]>

iex(5)> user_with_videos = Repo.one query
[debug] SELECT u0."id", u0."name", u0."username", u0."password_hash", u0."inserted_at", u0."updated_at" FROM "users" AS u0 LIMIT 1 [] OK query=1.0ms
[debug] SELECT v0."id", v0."url", v0."title", v0."description", v0."user_id", v0."category_id", v0."inserted_at", v0."updated_at" FROM "videos" AS v0 WHERE (v0."user_id" IN ($1)) ORDER BY v0."user_id" [1] OK query=0.9ms queue=0.1ms

iex(6)> user_with_videos.videos
[%MysteryScienceTheater_3000.Video{
  ...,
  description: "Just an example video for andrei",
  id: 2,
  user_id: 1}]
```

More elaborated example:

```console
➜  iex -S mix

iex(1)> import Ecto.Query
iex(2)> alias MysteryScienceTheater_3000.Repo
iex(3)> alias MysteryScienceTheater_3000.User

iex(4)> Repo.all from u in User,
...(4)>          join: v in assoc(u, :videos),
...(4)>          join: c in assoc(v, :category),
...(4)>          where: c.name == "Arthouse",
...(4)>          select: {u, v}
[debug] SELECT u0."id", u0."name", u0."username", u0."password_hash", u0."inserted_at", u0."updated_at", v1."id", v1."url", v1."title", v1."description", v1."user_id", v1."category_id", v1."inserted_at", v1."updated_at" FROM "users" AS u0 INNER JOIN "videos" AS v1 ON v1."user_id" = u0."id" INNER JOIN "categories" AS c2 ON c2."id" = v1."category_id" WHERE (c2."name" = 'Arthouse') [] OK query=1.4ms
[{%MysteryScienceTheater_3000.User{
     ...,
     username: "andreitarkovsky"},
  %MysteryScienceTheater_3000.Video{
     ...,
     category_id: 2,
     description: "This time with `Arthouse` Category",
     id: 3,
     title: "Second example video",
     user_id: 1}
}]
```

### `Constraints` and `Ecto` terminology

`Constraints` allow us to use underlying relational database features to help us maintain database integrity.

- `constraint`: explicit database constraint (uniqueness constraint on an index, or an integrity constraint between primary and foreign keys).
- `constraint error`: The `Ecto.ConstraintError`, (like when we tried to add a category twice).
- `changeset constraint`: A `constraint annotation` added to the `changeset` that allows `Ecto` to convert `constraint errors` into `changeset error messages`.
- `changeset error messages`: Beautiful error messages for the consumption of humans.

### Data consistency across records

Ensuring data is consistent across records is a critical job that all database-backed applications need to handle.

You have **three approaches** to solving this problem:

1. Let the application (and the web framework) manage relationships for you (`Rails ActiveRecord`).
2. Let the database manage all code that touches data (through the use of layers such as stored procedures).
3. Let the application layer (and web server) use database services (hybrid approach) like referential integrity and transactions to strike a balance between the needs of the application layer and the needs of the database (`Ecto` managing `constraints`).

### `*_constraint` `changeset` functions examples

The `*_constraint` `changeset` functions are useful when the constraint being mapped is triggered by external data, often as part of the user request.

Using `changeset constraints` only makes sense if the error message can be something the user can take action on.

#### `unique_constraint`

The `unique_constraint` converts unique constraint errors into human-readable error messages.

`user_changeset |> unique_constraint(​:username​)` guarantees that you can't create a new user if the new username already exists in the database.

#### `assoc_constraint`

The `assoc_constraint` converts foreign-key constraint errors into human-readable error messages.

`video_changeset |> assoc_constraint(​:category​)` guarantees that a video is created only if the category exists in the database.

### `IEx` `v(n)` trick

`IEx` allows us to fetch a previous value by using `v(n)`:

- `n` is the number of the expression.
- Pass a negative value to grab the last `nth` expression.

```console
iex(11)> Repo.update changeset
{:error, %Ecto.Changeset{ ... }

iex(12)> {:error, changeset} = v(-1)
{:error, %Ecto.Changeset{ ... }

iex(13)> changeset.errors
[category: "does not exist"]
```
