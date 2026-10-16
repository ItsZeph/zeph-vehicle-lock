# zeph-vehicle-lock
I was fed up with how vMenu sometimes forgets your Personal Vehicle, and therefore doesn't let you lock it or enter it, so I had Claude make something for my server, which I decided to publish.

# Features
- Vehicle Locking via ox_target
- Lockpicking via ox_target and an ox_lib skill check.

# Prerequisites
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)

# Installation
Installation is simple, just download the latest release, drop it into your Resources folder, and put `ensure zeph-vehicle-lock` in your server.cfg, configure it, then restart your server.

# Important Notes
> [!IMPORTANT]
> Like this README states, this script was made entirely by Claude months ago, which I decided to publish now, this means that I can't provide much support, I just wanted to make something to fix something that annoyed me. The car alarm, which is intended to trigger when a player lockpicks a vehicle doesn't work, and there are times when it won't prompt you to lock your vehicle when you spawn it, so if you know how to fix those, feel free to make a fork with credit, since I know there are people 10x smarter than me who can make this work.
