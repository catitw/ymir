{
  description = "A Nix-flake-based ymir project development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      # system should match the system you are running on
      system = "x86_64-linux";
    in
    {
      devShells."${system}".default =
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            # fix https://discourse.nixos.org/t/non-interactive-bash-errors-from-flake-nix-mkshell/33310
            bashInteractive

            # utils for this project
            OVMF.fd
            qemu
            qemu-utils

            # this project using zig 0.15
            zig_0_15
            zls_0_15
          ];

          shellHook = ''
            # fix tmux/zellij bash prompt breaks
            # see: https://discourse.nixosstag.fcio.net/t/tmux-bash-prompt-breaks-inside-of-flakes/60925/8
            export SHELL=${pkgs.lib.getExe pkgs.bashInteractive}

            export OVMF_CODE_FD=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd
            export OVMF_VARS_FD=${pkgs.OVMF.fd}/FV/OVMF_VARS.fd

            echo "[devShell] OVMF_CODE_FD=$OVMF_CODE_FD"
            echo "[devShell] OVMF_VARS_FD=$OVMF_VARS_FD"
          '';
        };
    };
}
