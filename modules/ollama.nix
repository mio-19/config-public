{ den, ... }:
{
  den.aspects.ollama = {
    description = "Ollama LLM service";
    nixos =
      { ... }:
      {
        services.ollama.enable = true;
        services.ollama.host = "0.0.0.0";
        services.ollama.openFirewall = true;
        services.ollama.home = "/var/lib/ollama-service"; # workaround some bug? is it interfering with persistent on default path?
      };
  };
}
