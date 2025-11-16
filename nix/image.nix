let
  pkgs = import <nixpkgs> {};
  docker = pkgs.dockerTools;

  streamScript = docker.streamLayeredImage {
    name = "nix-base";
    contents = [
      pkgs.coreutils
      pkgs.busybox
      pkgs.nodejs_20
    ];
    config = {
      Cmd = [ "${pkgs.nodejs_20}/bin/node" ];
      WorkingDir = "/app";
      Env = [
        "NODE_ENV=production"
        "PATH=${pkgs.nodejs_20}/bin:${pkgs.coreutils}/bin:${pkgs.busybox}/bin"
      ];
    };
  };
in
{
  myImage = pkgs.runCommand "stream-layered-image-wrapped" {} ''
    mkdir -p $out/bin
    ln -s ${streamScript} $out/bin/stream-layered-image
  '';
}

