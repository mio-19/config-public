{
  inputs = {
    nixbsd.url = "github:nix-community/nixbsd";
    nixpkgs.follows = "nixbsd/nixpkgs";
  };
  outputs = inputs: {};
}