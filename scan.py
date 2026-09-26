#!/usr/bin/env python3
"""
CF IP Scanner - Fast concurrent ping scanner
Works on Termux (Android), Linux, and Windows 11
"""

import subprocess
import platform
from concurrent.futures import ThreadPoolExecutor
import ipaddress
import sys

# ====================== CONFIG ======================
NETWORK = "104.18.16.0/20"   # Change this to any CIDR you want
THREADS = 32                 # Number of concurrent pings
TIMEOUT = 0.5                # Timeout in seconds
# ====================================================

def is_alive(ip: str) -> tuple[str, bool]:
    system = platform.system().lower()

    if system == "windows":
        # Windows: ping -n 1 -w (timeout in ms)
        cmd = ["ping", "-n", "1", "-w", str(int(TIMEOUT * 1000)), ip]
    else:
        # Linux / Termux / macOS
        cmd = ["ping", "-c", "1", "-W", str(int(TIMEOUT)), ip]

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=TIMEOUT + 1
        )
        return ip, result.returncode == 0
    except Exception:
        return ip, False


def main():
    try:
        network = ipaddress.ip_network(NETWORK, strict=False)
    except ValueError as e:
        print(f"Invalid network: {e}")
        sys.exit(1)

    ips = [str(ip) for ip in network.hosts()]
    total = len(ips)

    print(f"Scanning {NETWORK} ({total} hosts) with {THREADS} threads...")
    print("This may take a while depending on the range size.\n")

    alive = []
    with ThreadPoolExecutor(max_workers=THREADS) as executor:
        for ip, ok in executor.map(is_alive, ips):
            if ok:
                alive.append(ip)
                print(f"[+] {ip}")

    # Save results
    with open("reachable.txt", "w") as f:
        f.write("\n".join(alive))

    print("\n" + "=" * 40)
    print(f"Done! {len(alive)}/{total} hosts are reachable")
    print(f"Results saved to: reachable.txt")
    print("=" * 40)

    if alive:
        print("\nReachable IPs:")
        print("\n".join(alive))
    else:
        print("\nNo reachable hosts found.")


if __name__ == "__main__":
    main()
