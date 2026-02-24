This repository contains a nix flake for [portless](https://github.com/vercel-labs/portless). You can install portless into your nix devshell with:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    portless-nix.url = "github:hypervideo/portless-nix";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import portless-nix)
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            portless
          ];

        };
      }
    );
}
```

This repository has a automatically running CI job that will update the `portless` package to the latest version on a regular basis.
