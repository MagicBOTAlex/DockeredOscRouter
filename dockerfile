FROM nixos/nix

RUN nix-channel --update
RUN nix-env -iA nixpkgs.gitoxide

COPY ./* /backend/
COPY ./startServer.sh /
RUN chmod +x /startServer.sh

# CMD ["bash"]
ENTRYPOINT ["/startServer.sh"]

