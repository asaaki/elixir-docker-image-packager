
# Elixir Docker Image Packager (EDIP)

Attempt to create the possibly smallest Docker image for an Elixir release.

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
- [How it works](#how-it-works)
  - [Step 1: The stage environment](#step-1-the-stage-environment)
    - [Phase 1: Building the stage image](#phase-1-building-the-stage-image)
    - [Phase 2: Crafting the artifact](#phase-2-crafting-the-artifact)
  - [Step 2: The final release image](#step-2-the-final-release-image)
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

First clone the repository or download and unpack a zip archive.

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

## How it works

The whole build/packaging process happens in Docker containers.
The only host dependencies are _docker_, _make_ and _sed._

The process is split in 2 steps:

- Step 1: The stage environment
  > creating the release and preparing the file system artifact _(rootfs)_

- Step 2: The final release image
  > creating the release image from the artifact

### Step 1: The stage environment

Most work is done here.

#### Phase 1: Building the stage image

First the stage image is created, which is based on [asaaki/elixir-base-dev](https://github.com/asaaki/elixir-base-dev-docker).
In the _dockerfiles/Dockerfile.stage_ you can adjust the steps for your desired environment.
Add more packages if your build process needs them (like shared libraries for compilation).

#### Phase 2: Crafting the artifact

In the run phase the heavy lifting happens.

First it creates the release of your Elixir application you tenderly assembled.

Then it gathers the information which other files in the system needs to be collected (shared libraries).
In general it will be a libc (here it's from [musl](http://www.musl-libc.org/), which is also a much smaller variant
than the more common _glibc_) and some other quiet essential libraries (at least _libcrypto_ and _libz_).

After this it finally gathers all the files (your app, libraries/dependencies and busybox) and bundles everything into
a beautiful wrapped tarball (_rootfs.tar.gz_) for the second step.

### Step 2: The final release image

This is a quick and simple step. Really, it is.

Of course it's a very important one!

With the tarball archive artifact from the previous step we can finally create our precious Docker image for
production deployments.

Initially grown from a _Dockerfile_ instruction set it is now just a single `docker import` command.

Since the original base image was `scratch` (which is a totally empty rootfs) there is no difference in size between
the two approaches. For simplicity I'll stick to the _docker import_ as it makes it easier to set the _CMD_ line.

## Caveats

Avoid packages with C extensions (NIFs or ports to external binaries). This is not tested yet.
Most likely you would need to adjust _Dockerfile.stage_ to meet the requirements/dependencies.

## Does it work for Phoenix apps?

If you ignore the static asset compilation step, then yes, it does.
(You can adjust the _package/Makefile.app_ to your needs.)

After a successful build you can test it like this:

```shell
docker run --rm -e "PORT=4000" -p 4000:4000 local/release-image
```

You need to set the `PORT` environment variable, otherwise the app will just crash (only in Phoenix's default config).

## Why?

Not just for fun, but to save my sanity by not using overly huge, crazily humongous, tremendously gigantic Ubuntu images.*

There is no need for custom application images which reach the 1 GB mark.

And there is no need for images with risky and unnecessary cruft in it.

_*) Yes, I know, the Ubuntu base image is less than 200 MB, but when you start building your custom image onto it,
then it will quickly grow as hell even if you try to be careful._

## Is it free?

_[Of course it is!](./LICENSE)_
