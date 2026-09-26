#!/data/data/com.termux/files/usr/bin/bash
# CF IP Scanner - Bash version
# Fast concurrent ping scanner
# Best for Termux (Android) and Linux

# ====================== CONFIG ======================
NETWORK="104.18.16.0/20"   # Change this to any CIDR
WORKERS=32                 # Number of concurrent pings
TIMEOUT=0.5                # Timeout in seconds
# ====================================================

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "Scanning $NETWORK with $WORKERS workers..."
echo "This may take a while depending on the range size."
echo

# Generate IP list using Python (most reliable way in Termux/Linux)
# Fallback message if python is not available
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    echo "Error: Python is required to generate IP list from CIDR."
    echo "Install it with: pkg install python"
    exit 1
fi

PYTHON=$(command -v python3 || command -v python)

# Generate all host IPs
IPS=$($PYTHON -c "
import ipaddress
net = ipaddress.ip_network('$NETWORK', strict=False)
print('\n'.join(str(ip) for ip in net.hosts()))
")

if [ -z "$IPS" ]; then
    echo "Failed to generate IP list. Check the NETWORK value."
    exit 1
fi

TOTAL=$(echo "$IPS" | wc -l)
echo "Total hosts to scan: $TOTAL"
echo

# Clear previous results
> reachable.txt

# Concurrent ping using xargs
echo "$IPS" | xargs -P "$WORKERS" -I {} bash -c '
    ip="$1"
    if ping -c 1 -W '"$TIMEOUT"' "$ip" &>/dev/null; then
        echo -e "[+] $ip"
        echo "$ip" >> reachable.txt
    fi
' _ {}

# Count results
ALIVE=$(wc -l < reachable.txt | tr -d ' ')

echo
echo "========================================"
echo -e "Done! ${GREEN}$ALIVE${NC}/$TOTAL hosts are reachable"
echo "Results saved to: reachable.txt"
echo "========================================"

if [ "$ALIVE" -gt 0 ]; then
    echo
    echo "Reachable IPs:"
    cat reachable.txt
else
    echo
    echo "No reachable hosts found."
fi
