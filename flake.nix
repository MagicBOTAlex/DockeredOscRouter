{
  description =
    "Dockered OSC flake (ChatGPT because I want it fast, and this isn't important)";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05"; };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
        (system: let pkgs = import nixpkgs { inherit system; }; in f pkgs);

      oscRelayPkg = pkgs:
        pkgs.writeShellApplication {
          name = "osc-relay";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            exec python3 ${./main.py}
          '';
        };
    in {
      packages = forAllSystems (pkgs: { default = oscRelayPkg pkgs; });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${oscRelayPkg pkgs}/bin/osc-relay";
        };
      });

      nixosModules.osc-relay = { config, lib, pkgs, ... }:
        let cfg = config.services.osc-relay;
        in {
          options.services.osc-relay = {
            enable = lib.mkEnableOption "OSC relay daemon";

            listenIp = lib.mkOption {
              type = lib.types.str;
              default = "0.0.0.0";
              description = "IP to listen on.";
            };

            listenPort = lib.mkOption {
              type = lib.types.port;
              default = 8000;
              description = "UDP port to listen on.";
            };

            targets = lib.mkOption {
              type = lib.types.str;
              example = "127.0.0.1:9001,192.168.1.10:9002";
              description = "OSC_TARGETS env var string.";
            };
          };

          config = lib.mkIf cfg.enable {
            systemd.services.osc-relay = {
              description = "OSC relay";
              after = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                ExecStart = "${oscRelayPkg pkgs}/bin/osc-relay";
                Environment = [
                  "OSC_LISTEN_IP=${cfg.listenIp}"
                  "OSC_LISTEN_PORT=${toString cfg.listenPort}"
                  "OSC_TARGETS=${cfg.targets}"
                ];
                Restart = "always";
              };
            };
          };
        };
    };
}

