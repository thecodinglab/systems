# development tools beyond the core: editors, extra coding agents and
# kubernetes tooling
{ pkgs, ... }:
{
  home.packages = [
    # Coding
    pkgs.neovide
    pkgs.zed-editor

    # Kubernetes
    pkgs.kubectl
    (pkgs.wrapHelm pkgs.kubernetes-helm { plugins = [ pkgs.kubernetes-helmPlugins.helm-diff ]; })
    pkgs.helmfile
    pkgs.k9s
  ];
}
