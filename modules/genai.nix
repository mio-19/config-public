{ den, ... }:
{
  den.aspects.genai = {
    description = "Stable Diffusion WebUI and ComfyUI packages";
    nixos =
      { inputs, pkgs, ... }:
      {
        # https://search.nixos.org/packages
        environment.systemPackages = with pkgs; [
          # https://github.com/Janrupf/stable-diffusion-webui-nix
          inputs.stable-diffusion-webui-nix.packages."${pkgs.stdenv.hostPlatform.system}".forge.cuda # For lllyasviel's fork of AUTOMATIC1111 WebUI - stable-diffusion-webui
          inputs.stable-diffusion-webui-nix.packages."${pkgs.stdenv.hostPlatform.system}".comfy.cuda # For ComfyUI - comfy-ui
          # https://github.com/nixified-ai/flake
          inputs.nixified-ai.packages."${pkgs.stdenv.hostPlatform.system}".comfyui-nvidia # comfyui # takes too many time to compile. disable temporarily
        ];
      };
  };
}
