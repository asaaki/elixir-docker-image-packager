
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
  - [exrm](#exrm)
  - [Trigger build process](#trigger-build-process)
  - [Test it!](#test-it)
- [How it works](#how-it-works)
  - [Step 1: Create stage environment](#step-1-create-stage-environment)
  - [Step 2: Build application release](#step-2-build-application-release)
  - [Step 3: Craft rootfs artifact](#step-3-craft-rootfs-artifact)
  - [Step 4: Create release image](#step-4-create-release-image)
- [Caveats](#caveats)
- [FAQ](#faq)
  - [Does it work for Phoenix apps?](#does-it-work-for-phoenix-apps)
  - [Why?](#why)
  - [How different is it from ...?](#how-different-is-it-from-)
    - [msaraiva's "Erlang/Elixir on Alpine Linux"](#msaraivas-erlangelixir-on-alpine-linux)
  - [Is it free?](#is-it-free)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Showdown

```
~/Development/elixir-docker-image-packager $ docker images
REPOSITORY                    TAG     IMAGE ID      CREATED        VIRTUAL SIZE
local-release/my_awesome_app  latest  ce86ea652636  some time ago  19.87 MB
```

Okay, this release is a pretty dump Elixir app. Actually it is just a freshly
created one via `mix new app --module MyAwesomeApp --app my_awesome_app`.

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

```shell
git clone https://github.com/asaaki/elixir-docker-image-packager.git
cd elixir-docker-image-packager
```

### app

Move/copy your application to `app/`.

For testing purposes just create a simple app with:

```shell
mix new app --module MyAwesomeApp --app my_awesome_app
```

### exrm

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

### Trigger build process

```shell
make
```

... and wait a bit.

### Test it!

Start the app in foreground mode:

```shell
docker run --rm -it local-release/my_awesome_app
```

If everything went well, your release should be up and running now.

## How it works

The whole build/packaging process happens in Docker containers.
The only host dependencies are _docker_ and _make_.

Everything happens within a staging container.

### Step 1: Create stage environment

First the stage image is created, which is based on [asaaki/elixir-base-dev](https://github.com/asaaki/elixir-base-dev-docker).
In the _dockerfiles/Dockerfile.stage_ you can adjust the steps for your desired environment.
Add more packages if your build process needs them (like shared libraries for compilation).

If the image is ready, a container will be started directly afterwards.

### Step 2: Build application release

Within the running staging container the project release is built with exrm.

Nothing fancy here.

### Step 3: Craft rootfs artifact

Then it gathers the information which other files in the system needs to be collected (shared libraries).
In general it will be a libc (here it's from [musl](http://www.musl-libc.org/), which is also a much smaller variant
than the more common _glibc_) and some other quiet essential libraries (at least _libcrypto_ and _libz_).

After this it finally gathers all the files (your app, libraries/dependencies and busybox) and bundles everything into
a beautiful wrapped tarball (_rootfs.tar.gz_) for the final step.

### Step 4: Create release image

This is a quick and simple step. Really, it is.

Of course it's a very important one!

With the tarball archive artifact from the previous step we can finally create our precious Docker image for
production deployments.

_(For the curious: It's using `docker import`)_

## Caveats

Avoid packages with C extensions (NIFs or ports to external binaries). This is not well-tested yet.
Most likely you would need to adjust _Dockerfile.stage_ to meet the requirements/dependencies.

## FAQ

### Does it work for Phoenix apps?

If you ignore the static asset compilation step, then yes, it does.
(You can adjust the _package/Makefile.app_ to your needs.)

After a successful build you can test it like this:

```shell
docker run --rm -e "PORT=4000" -p 4000:4000 local/release-image
```

You need to set the `PORT` environment variable, otherwise the app will just crash (only in Phoenix's default config).

### Why?

Not just for fun, but to save my sanity by not using overly huge, crazily humongous, tremendously gigantic Ubuntu images.*

There is no need for custom application images which reach the 1 GB mark.

And there is no need for images with risky and unnecessary cruft in it.

_*) Yes, I know, the Ubuntu base image is less than 200 MB, but when you start building your custom image onto it,
then it will quickly grow as hell even if you try to be careful._

### How different is it from ...?

I'm glad you asked! _(And if you find similar projects, point me to them; I'd like to have a look at them, too.)_

#### msaraiva's "Erlang/Elixir on Alpine Linux"

Under [msaraiva/alpine-erlang](https://github.com/msaraiva/alpine-erlang) you'll find a pretty good guide on how to
build pretty small images/containers for your Erlang or Elixir application. Yes, you've read it correctly, I said
_application_, not _release_.

Of course, there is an example for a Phoenix app with exrm, but unfortunatelly it requires dependencies on your host.
I'd like to avoid or at least to minimalize this burden. While in development of your application, you don't care so
much about this downside, but I think here more about CI/CD (continuous integration/deployment).

The other example ["Hello world (compilation inside the container)"](https://github.com/msaraiva/alpine-erlang#-hello-world-compilation-inside-the-container)
is more the flavor of build process I'd like to see. I think this is the much better approach we should aim for.

When you try this and inspect the container content, you will notice some differences from this project:

- the source code is visible
- there are still tools present which are not needed (like _apk_)

In conclusion: Either you have a bit crufty image or a crufty system. Mostly this is not a big deal, but was never my
goal.

### Is it free?

_[Of course it is!](./LICENSE)_
