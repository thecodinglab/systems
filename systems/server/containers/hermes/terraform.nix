{ ... }: {
  # Hermes: god of boundaries, travel, trade, communication
  resource.incus_instance.hermes = {
    name = "hermes";
    image = "images:nixos/23.11";

    profiles = [
      "default"
      "nesting"
    ];
  };
}
