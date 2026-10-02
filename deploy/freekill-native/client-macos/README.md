# macOS client

The upstream FreeKill release currently publishes Windows and Android
artifacts. macOS is supported, but the official README asks Mac users to build
the client from source. `build.sh` keeps that process repeatable and pins the
same client line used by the live server smoke test (`v0.5.25`).

## Build

Install the upstream build dependencies with Homebrew:

```sh
brew install cmake libgit2 lua qt pkgconfig vulkan-headers swig
```

The upstream project recommends the full Xcode installation for Qt on macOS;
Command Line Tools may work on some machines but are not the supported setup.

From this directory:

```sh
bash build.sh
```

The result is `build/FreeKill`. To use another source or build directory:

```sh
FREEKILL_SOURCE_DIR="$HOME/src/FreeKill" \
FREEKILL_BUILD_DIR="$HOME/src/FreeKill-build" \
bash build.sh
```

## Connect to the live private server

Launch the built client, open the server/join-server page, and enter:

```text
Address: 168.110.36.224
Port:    9527
```

Create a player account in the client. The server is currently English and
does not require an invite whitelist, so a small test group can connect. A
complete interactive Hegemony game with one bot finished on 2026-09-24; a
complete two-human game and reconnect still need verification. The
client downloads the enabled `freekill-core`, `hegemony` and `utility` package
versions from the server and verifies their file-list hash before entering the
lobby.

Windows and Android players can use the matching official FreeKill `v0.5.25`
release artifacts; they should use the same server address and port.

## macOS artwork status

The source build alone does not include the playable card and general artwork.
On 2026-09-24, the Mac test client was installed at
`~/Applications/FreeKill Playable.app` with data under
`~/Library/Application Support/FreeKill-Playable-v0.5.25`. Its enabled
`official-v0.5.25` resource pack contains 613 artwork and animation files
extracted from the official v0.5.25 release. The standard character gallery
and standard/Hegemony shared card illustrations were visually verified in the
Mac client. The same pack maps 36 Hegemony characters to existing standard
portraits of the same characters.

The Hegemony extension itself contains no portrait or unique card artwork.
Characters without a matching standard portrait therefore still show the
game's silhouette. For unique Hegemony cards without art, the Mac client's
card component now displays the translated card name on the blank face, so
these cards can be distinguished. The client also lays out Latin character
names horizontally and falls back to Chinese when an English skill/name
translation is missing. These local display fixes do not supply missing
Hegemony artwork or a full English/Vietnamese translation.

## Native smoke helper

`remote-smoke.cpp` is a development-only, headless check. It uses the official
FreeKill client library to connect, synchronize packages, log in and create a
temporary `new_heg_mode` room. It is not the normal game launcher.
