Currently the "vision" described by @README.md is not implemented. I want you to create a nix flake that provides `portless` as a package and overlay to be used in a devshells etc.

1. [x] Figure out how `portless` can be wrapped as a nix package. This may involve writing a `default.nix` that fetches the source code and builds it.
2. [x] Create an overlay that makes `portless` available in the nixpkgs package set.
3. [x] Write a CI script for github runners that regularly checks for updates to `portless` and updates the flake accordingly.
