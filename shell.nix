{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  eth2-val-tools = buildGoModule rec {
    pname = "eth2-val-tools";
    version = "3c6266a6cf44e7f61866e115106fa4382e30f3a4";
    proxyVendor = true;
    src = fetchFromGitHub {
      owner = "protolambda";
      repo = "eth2-val-tools";
      rev = "${version}";
      sha256 = "SZFl8f9858e1mKFNeYbeh9Zg/6NYviid6G8L868UfIw=";
    };
    vendorSha256 = "FTws0YtP1VyDerkHJLBxQDwhmtbHO0tx1M7CX7JIstY=";
  };
in
mkShell {
  buildInputs = [
    eth2-val-tools
    curl
    jq
    yq
    git
  ];
}
