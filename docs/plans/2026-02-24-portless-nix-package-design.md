# portless-nix Package Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a nix flake that provides `portless` as a package and overlay for use in devShells.

**Architecture:** Fetch the pre-built npm tarball from the npm registry using `buildNpmPackage`. The published tarball contains compiled `dist/` files, so no build step is needed. A vendored `package-lock.json` (production-only) enables reproducible dependency resolution for the single dependency (`chalk`). The flake exposes a package, overlay, and devShell.

**Tech Stack:** Nix flakes, `buildNpmPackage`, Node.js 20, nixpkgs-unstable

---

### Task 1: Add the vendored package-lock.json

**Files:**
- Create: `package-lock.json`

**Step 1: Create the production-only lockfile**

Write `package-lock.json` with this exact content (already generated from the portless@0.4.1 npm tarball with devDependencies removed):

```json
{
  "name": "portless",
  "version": "0.4.1",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "portless",
      "version": "0.4.1",
      "license": "Apache-2.0",
      "os": [
        "darwin",
        "linux"
      ],
      "dependencies": {
        "chalk": "^5.3.0"
      },
      "bin": {
        "portless": "dist/cli.js"
      },
      "engines": {
        "node": ">=20"
      }
    },
    "node_modules/chalk": {
      "version": "5.6.2",
      "resolved": "https://registry.npmjs.org/chalk/-/chalk-5.6.2.tgz",
      "integrity": "sha512-7NzBL0rN6fMUW+f7A6Io4h40qQlG+xGmtMxfbnH/K7TAtt8JQWVQK+6g0UXKMeVJoyV5EkkNsErQ8pVD3bLHbA==",
      "license": "MIT",
      "engines": {
        "node": "^12.17.0 || ^14.13 || >=16.0.0"
      },
      "funding": {
        "url": "https://github.com/chalk/chalk?sponsor=1"
      }
    }
  }
}
```

**Step 2: Commit**

```bash
git add package-lock.json
git commit -m "chore: add vendored production-only package-lock.json for portless 0.4.1"
```

---

### Task 2: Create the portless package derivation

**Files:**
- Create: `default.nix`

**Step 1: Write `default.nix`**

```nix
{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  openssl,
  nodejs_20,
}:

let
  version = "0.4.1";

  srcWithLock = runCommand "portless-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/portless/-/portless-${version}.tgz";
        hash = "sha256-0Xjf7fgBoBu1OFcl+GakLHCX+QpwJfQgpe/FGRKa9OY=";
      }
    } -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in

buildNpmPackage {
  pname = "portless";
  inherit version;

  src = srcWithLock;

  npmDepsHash = "sha256-sFswfaVLupYx220aIHPYxrFw6N2H8ZjfyQu+JCaqmKg=";

  dontNpmBuild = true;
  nodejs = nodejs_20;

  postInstall = ''
    wrapProgram $out/bin/portless \
      --prefix PATH : ${lib.makeBinPath [ openssl ]}
  '';

  meta = with lib; {
    description = "Replace port numbers with stable, named .localhost URLs";
    homepage = "https://github.com/vercel-labs/portless";
    license = licenses.asl20;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "portless";
  };
}
```

**Step 2: Commit**

```bash
git add default.nix
git commit -m "feat: add portless package derivation"
```

---

### Task 3: Update flake.nix with package, overlay, and devShell

**Files:**
- Modify: `flake.nix`

**Step 1: Rewrite `flake.nix`**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      overlays.default = final: prev: {
        portless = final.callPackage ./default.nix { };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages.default = pkgs.portless;

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.portless ];
        };
      }
    );
}
```

**Step 2: Commit**

```bash
git add flake.nix
git commit -m "feat: add portless package, overlay, and devShell to flake"
```

---

### Task 4: Build and verify

**Step 1: Update flake.lock**

```bash
nix flake update
```

**Step 2: Build the package**

```bash
nix build .#
```

Expected: Builds successfully, producing `./result/bin/portless`

**Step 3: Test the binary runs**

```bash
./result/bin/portless --help
```

Expected: Shows portless help output

**Step 4: Test the devShell**

```bash
nix develop -c portless --help
```

Expected: Shows portless help output

**Step 5: Commit the updated flake.lock**

```bash
git add flake.lock
git commit -m "chore: update flake.lock"
```

---

### Task 5: Test the overlay from consumer perspective

**Step 1: Verify overlay works**

```bash
nix eval .#overlays.default --apply 'x: builtins.typeOf x'
```

Expected: `"lambda"`

**Step 2: Test overlay integration matches README usage**

```bash
nix build .#packages.x86_64-darwin.default  # or appropriate system
```

Expected: Builds successfully
