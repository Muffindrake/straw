# straw
a small command line interface to streaming services

`CAUTION`: this is as of yet experimental and should not be used in a serious
fashion.

```
$ straw
twitch> user muffindrake
username set to `muffindrake`
twitch> fl
successfully fetched service information
00 BobRoss      <Art> Bob Ross - Weekend Stream Marathons Start At 3PM EST Every Friday!
01 Calebhart42  <Dark Souls III> Dark Souls 3 is the World's Best Game
02 BigJon       <The Price is Right> Friday Night Gameshows! The Price is Right!
[...]
```

# installation

```
$ git clone https://github.com/muffindrake/straw
$ cd straw
$ make
$ ./straw
```

The Makefile currently requires LDC2 as a D compiler, but the program will build
just fine by compiling all `*.d` files together using any other D compiler.

# dependencies
- a recent LDC2
- mpv
- youtube-dl
- sh-compatible shell
- libcurl (part of the D standard library)

# TODO
- rate limiting
- investigate segmentation fault related to users with an excessive amount of
  follows (probably related to rate limiting)
