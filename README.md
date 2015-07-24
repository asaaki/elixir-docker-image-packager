
# Elixir Docker Image Packager (EDIP)

Attempt to create the possibly smallest docker image for an Elixir release.

<!--
  TOC generaged with doctoc: `npm install -g doctoc`

    $ doctoc README.md --github --maxlevel 4 --title '## TOC'

-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## TOC

- [Showdown](#showdown)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [app](#app)
  - [package/app-config.mk](#packageapp-configmk)
    - [APPNAME](#appname)
    - [APPVER](#appver)
  - [Trigger build process](#trigger-build-process)
  - [Test it!](#test-it)
- [Caveats](#caveats)
- [Does it work for Phoenix apps?](#does-it-work-for-phoenix-apps)
- [Why?](#why)
- [Is it free?](#is-it-free)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Showdown

```
~/Development/elixir-docker-image-packager $ docker images
REPOSITORY           TAG     IMAGE ID      CREATED        VIRTUAL SIZE
local/release-image  latest  ce86ea652636  some time ago  19.87 MB
local/stage-image    latest  2ad6b6f89e1c  some time ago  152 MB
```

Okay, this release is a pretty dump Elixir app (it does start the app and
supervision tree + a stupid worker printing a counter every 2 seconds).

But the ~ 20 MB are basically:

- busybox (~ 796 KB)
- shared libraries (here musl-libc, libncurse, libcrypto, libz; ~ 3 MB)
- Elixir release (~ 16.5 MB); most notably with:
  - ERTS (erlang runtime system; ~ 5.6 MB)
  - applications (including the dummy app; ~ 10.7 MB)

Details about the applications:

```
$ du -hd1 /app/lib
160.0K  /app/lib/iex-1.0.5
124.0K  /app/lib/logger-1.0.5
508.0K  /app/lib/syntax_tools-1.7
216.0K  /app/lib/crypto-3.6
1.5M    /app/lib/kernel-4.0
3.1M    /app/lib/stdlib-2.5
20.0K   /app/lib/standalone-0.1.0
3.1M    /app/lib/elixir-1.0.5
52.0K   /app/lib/consolidated
1.6M    /app/lib/compiler-6.0
396.0K  /app/lib/sasl-2.5
```

`standalone-0.1.0` is the dummy app, so it doesn't really account for the image size at all.

Therefore the 20 MB can be seen as the lower limit of an image with the necessary runtime tools.

## Prerequisites

- Elixir application (obviously ¯\\\_(ツ)\_/¯)
- [exrm](https://github.com/bitwalker/exrm)
- `make`
- `docker` _(Yes, yes, I know ...)_

## Usage

### app

Move/copy your application to `app/`.

For testing purposes just create a simple app with:

```shell
mix new app --module MyAwesomeApp --app my_awesome_app
```

Do not forget to add the `exrm` dependency:

```elixir
defmodule MyAwesomeApp.Mixfile do
  use Mix.Project
  # <snip>

  defp deps do
    [{:exrm, "~> 0.18"}]
  end
end
```

### package/app-config.mk

Edit `package/app-config.mk`.

#### APPNAME

This is the name of your application identified by the Erlang VM and the exrm tool.
You find this in your `mix.exs` in the _project_ function under the `app` key:

```elixir
# file: app/mix.exs
defmodule MyAwesomeApp.Mixfile do
  use Mix.Project

  def project do
    [app: :my_awesome_app,
     version: "0.1.0",
     elixir: "~> 1.0",
    # <snip>
```

#### APPVER

Simply use the same version string you have in your `mix.exs` file (mostly found directly below the `app` key).

### Trigger build process

```shell
make
```

... and wait a bit.

### Test it!

Start the app in foreground mode:

```shell
make run-release
```

If everything went well, your release should be up and running now.

_(You might need to stop the container with `docker stop ...`,
since the Erlang VM within the container doesn't like to react on Ctrl+C via docker at all.)_

## Caveats

Avoid packages with C extensions (NIFs or ports to external binaries). This is not tested yet.
Most likely you would need to adjust _Dockerfile.stage_ to meet the requirements/dependencies.

## Does it work for Phoenix apps?

If you ignore the static asset compilation step, then yes, it does.
(You can adjust the _package/Makefile.app_ to your needs.)

After a successful build you can test it like this:

```shell
docker run --rm -e "PORT=4000" -p=4000:4000 local/release-image
```

## Why?

Not just for fun, but to save my sanity by not using overly huge, crazily humongous, tremendously gigantic Ubuntu images.*

There is no need for custom application images which reach the 1 GB mark.

And there is no need for images with risky and unnecessary cruft in it.

_*) Yes, I know, the Ubuntu base image is less than 200 MB, but when you start building your custom image onto it,
then it will quickly grow as hell even if you try to be careful._

## Is it free?

_[Of course it is!](./LICENSE)_
