# ❔ What is this repo?

This is basically a "storage" for my settings/configurations of various programs on [my Linux System](https://github.com/WhyHorsey/linux-notes). By doing this, if I decided to switch to a new device in the future, I then can just clone this repo and have all my programs already set up the way I wanted. However, if you also wanna use my configuration for the programs in this directory, then feel free to [do it](#⚙️%20Dependencies)!

Currently this directory include : 

- [bat](https://github.com/sharkdp/bat)
- [bash](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html)
- [btop](https://github.com/aristocratos/btop)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch)
- [konsole](https://invent.kde.org/utilities/konsole)
- [kwin](https://github.com/KDE/kwin)
- [mpd](https://mpd.readthedocs.io/en/stable/user.html)
- [rmpc](https://github.com/mierak/rmpc)
- [starship](https://github.com/starship/starship)
- [yazi](https://github.com/sxyazi/yazi)

---
# ⚙️ Dependencies

This repository is using something called GNU Stow to create a symlink between the files in this directory with the *actual* files in the correct path. I won't go into too much detail of how it works, but you can read more about it in [here](https://www.gnu.org/software/stow/). 

This means that you will need the `stow` package if you want to apply these configuration to your own system automatically. You will also need `git`, for cloning the repo of course. 

---
# ⬇️ Installation

1. Clone this repo. Run `git clone https://github.com/WhyHorsey/dotfiles.git ~/dotfiles`
2. Go to the repo directory. `cd ~/dotfiles`
3. Since the target for mpd config is `/etc/` and not `$HOME`, we need to do this slighly different than the rest. Run `sudo stow -t / -d ~/dotfiles mpd` (if I decided to add more config that also in `/etc/` and so on, and you wanna use that, just include it in here). This make sure the target path for its symlink is correct, because `-t /` is making stow specifically target the root.
4. Then, stow the rest of them. `stow bat bash btop fastfetch konsole ........` (just fill this with the configuration you wanna use)
5. Resart the the system just in case. Run `sudo systemctl daemon-reload`, `systemctl --user daemon-reload`, `systemctl --user restart mpd`
6. Done. Enjoy!!
