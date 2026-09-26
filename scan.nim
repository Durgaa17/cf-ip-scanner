# CF IP Scanner - Nim version
# Compile: nim c -d:release scan.nim
# Run: ./scan

import std/[os, osproc, strutils, strformat, threadpool, locks]

# ====================== CONFIG ======================
const
  NETWORK = "104.18.16.0/20"
  WORKERS = 32
  TIMEOUT = 1  # seconds
# ====================================================

var
  alive: seq[string]
  aliveLock: Lock

initLock(aliveLock)

proc cidrToIps(cidr: string): seq[string] =
  let parts = cidr.split('/')
  let ipStr = parts[0]
  let prefix = parseInt(parts[1])

  let octets = ipStr.split('.').map(parseInt)
  var ip = (octets[0] shl 24) or (octets[1] shl 16) or (octets[2] shl 8) or octets[3]

  let mask = if prefix == 0: 0 else: (not ((1 shl (32 - prefix)) - 1)) and 0xFFFFFFFF
  let network = ip and mask
  let broadcast = network or (not mask and 0xFFFFFFFF)

  result = @[]
  for i in (network + 1) ..< broadcast:
    result.add(&"{(i shr 24) and 255}.{(i shr 16) and 255}.{(i shr 8) and 255}.{i and 255}")

proc isAlive(ip: string): bool =
  let cmd = if defined(windows):
    &"ping -n 1 -w {TIMEOUT * 1000} {ip}"
  else:
    &"ping -c 1 -W {TIMEOUT} {ip}"

  let (output, exitCode) = execCmdEx(cmd)
  result = exitCode == 0

proc worker(ips: seq[string]) =
  for ip in ips:
    if isAlive(ip):
      echo "[+] ", ip
      withLock aliveLock:
        alive.add(ip)

proc main() =
  echo &"Scanning {NETWORK} with {WORKERS} workers..."
  echo "This may take a while depending on the range size.\n"

  let ips = cidrToIps(NETWORK)
  let total = ips.len
  echo &"Total hosts to scan: {total}\n"

  let chunkSize = (total + WORKERS - 1) div WORKERS
  var threads: seq[Thread[seq[string]]]

  for i in 0 ..< WORKERS:
    let start = i * chunkSize
    let finish = min(start + chunkSize, total)
    if start >= total: break
    var t: Thread[seq[string]]
    createThread(t, worker, ips[start ..< finish])
    threads.add(t)

  for t in threads:
    joinThread(t)

  alive.sort()
  writeFile("reachable.txt", alive.join("\n") & (if alive.len > 0: "\n" else: ""))

  echo "\n========================================"
  echo &"Done! {alive.len}/{total} hosts are reachable"
  echo "Results saved to: reachable.txt"
  echo "========================================"

  if alive.len > 0:
    echo "\nReachable IPs:"
    for ip in alive:
      echo ip
  else:
    echo "\nNo reachable hosts found."

main()
