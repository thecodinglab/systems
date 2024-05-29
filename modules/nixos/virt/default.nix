{ pkgs, ... }: {
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;

      ovmf.enable = true;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;
}
