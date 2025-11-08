#!/usr/bin/env python3
import os
import socket
import sys


def parse_targets(env_value: str):
    """
    Parse OSC_TARGETS like:
      "127.0.0.1:9001,192.168.1.10:8000"
    into a list of (host, port) tuples.
    """
    targets = []
    for item in env_value.split(","):
        item = item.strip()
        if not item:
            continue
        try:
            host, port_str = item.rsplit(":", 1)
            port = int(port_str)
        except ValueError:
            raise ValueError(f"Invalid target '{item}', expected host:port")
        targets.append((host, port))
    if not targets:
        raise ValueError("OSC_TARGETS is empty or malformed")
    return targets


def main():
    listen_ip = os.getenv("OSC_LISTEN_IP", "0.0.0.0")
    listen_port = int(os.getenv("OSC_LISTEN_PORT", "8000"))
    targets_env = os.getenv("OSC_TARGETS", "")

    if not targets_env:
        print("ERROR: OSC_TARGETS env var is not set.")
        print("Example: OSC_TARGETS='127.0.0.1:9001,192.168.1.50:9002'")
        sys.exit(1)

    try:
        targets = parse_targets(targets_env)
    except ValueError as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((listen_ip, listen_port))

    print(f"OSC relay listening on {listen_ip}:{listen_port}")
    print(f"Forwarding all incoming packets to: {targets}")

    # Relay loop
    while True:
        data, src_addr = sock.recvfrom(65535)
        # data contains the full OSC packet; we forward it unchanged
        for target in targets:
            try:
                sock.sendto(data, target)
            except OSError as e:
                print(f"Failed to send to {target}: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
