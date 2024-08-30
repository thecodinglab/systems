{
  bspwm = import ./bspwm;
  chromium = import ./chromium.nix;
  fzf = import ./fzf.nix;
  git = import ./git.nix;
  hyprland = import ./hyprland.nix;
  i3 = import ./i3.nix;
  kitty = import ./kitty.nix;
  theme = import ./theme;
  tmux = import ./tmux.nix;
  zathura = import ./zathura.nix;
  zsh = import ./zsh;

  unfree = import ../unfree.nix;
}
