lib: {
  home = {
    ipv4 = "\${data.sops_file.secrets.data[\"HOME_IPV4\"]}";
    ipv4_subnet = "\${data.sops_file.secrets.data[\"HOME_IPV4_SUBNET\"]}";
    ipv6_subnet = "\${data.sops_file.secrets.data[\"HOME_IPV6_SUBNET\"]}";
  };
}
