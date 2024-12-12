{
  description = "A flake";

  outputs = { self }: {

    templates = {

      nixos = {
        path = ./final;
        description = "Impermanent setup";
      };

    };

    defaultTemplate = self.templates.nixos;

  };
}
