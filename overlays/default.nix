{ inputs }:
{
  additions = final: _prev: import ../pkgs final;

  modifications = final: _prev: { neovim = inputs.neovim-config.packages.${final.system}.default; };
}
