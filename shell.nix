{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  # eth2-val-tools = buildGoModule rec {
  #   pname = "eth2-val-tools";
  #   version = "d5a451b851cda7a67a455aab0da4c699ca8027f2";
  #   src = fetchFromGitHub {
  #     owner = "protolambda";
  #     repo = "eth2-val-tools";
  #     rev = "${version}";
  #     sha256 = "x50VDdwCDVwt+1mg0bCtkM4finhdfS/vaPzR+ylWpkA=";
  #   };
  #   vendorSha256 = "Z8JzDPmNN+UWa3UB139bJ35MwjUkYxsY2XwXpid4AIM=";
  # };
  # unstable = import (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/9959fe259d84b969fefa3c541e9e5a4ed381387d) { };
in
mkShell {
  buildInputs = [
    # eth2-val-tools
    curl
    jq
    yq
    git
  ];
}
