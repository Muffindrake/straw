# straw
a small command line interface to streaming services

```
$ rlwrap straw
twitch> user qttsix
username set to `qttsix`
twitch> fl
successfully fetched service information (37 online)
00 毛(00mao00) <Dota 2> 【GALALA】一輪跪皇后場 Quenn to Pawn
01 狂暴小建(a541021) <Apex Legends> 【小建】 顆顆 @_~@
02 艾維與卡苗(ankgaminghk) <Mobile Suit Gundam: Battle Operation 2> [國/粵] 13Mar 來玩鋼彈啦~
03 林口大倉鼠(ashgametime) <Tom Clancy's The Division 2> ASH 今晚籃球臺~先跟兩個世界冠軍全境2一下
04 Bawkbasoup <Resident Evil 2> Leon A Speedruns - PC 120 FPS (Standard) Dark Souls 3 Later
05 蛋捲(cawai0147) <Just Chatting> 【蛋捲】聊個天   !DISCORD
06 CrystalUnclear <Mega Man X> I'm Back! Ultimate Derust To Continue Where We Left Off
07 冷颯(fable165469) <Just Chatting> 【冷颯&颯子】 良好作息騎空士Day5 主線已全通 看看我能撐多久
08 懶貓(failverde) <Tom Clancy's The Division 2> 【懶貓】湯姆克蘭西：全境封鎖2 !周邊 !discord 有無訂閱都能加入
09 고스트(ghostgc) <League of Legends> 장롱스타즈 vs 봉봉단 정글시점
[...]
```
The `fl` command fetches information from the stream service according to the
user set beforehand, before listing all information. Use `help` for a list of
commands.

# installation

```
$ git clone https://github.com/muffindrake/straw
$ cd straw
$ make
```

The Makefile currently requires LDC2 as a D compiler, but the program will build
just fine by compiling all `*.d` files together using any other D compiler.

# dependencies
- a recent LDC2
- mpv
- youtube-dl
- sh-compatible shell
- libcurl (part of the D standard library)
- optional, but recommended: https://github.com/hanslub42/rlwrap

# MAYBE-TODO
- authentication to circumvent draconian rate limits
