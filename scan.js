#!/usr/bin/env node
/**
 * CF IP Scanner - Node.js version
 * Fast concurrent ping scanner
 * Works on Termux (Android), Windows 11, Linux, macOS
 */

const { exec } = require("child_process");
const { promisify } = require("util");
const fs = require("fs");
const os = require("os");
const { networkInterfaces } = require("os");

// ====================== CONFIG ======================
const NETWORK = "104.18.16.0/20"; // Change this to any CIDR
const WORKERS = 32;               // Number of concurrent pings
const TIMEOUT = 500;              // Timeout in milliseconds
// ====================================================

const execAsync = promisify(exec);

function cidrToIps(cidr) {
  const [ip, prefix] = cidr.split("/");
  const prefixNum = parseInt(prefix, 10);

  const ipParts = ip.split(".").map(Number);
  const ipNum = (ipParts[0] << 24) + (ipParts[1] << 16) + (ipParts[2] << 8) + ipParts[3];

  const mask = ~((1 << (32 - prefixNum)) - 1) >>> 0;
  const network = ipNum & mask;
  const broadcast = network | (~mask >>> 0);

  const ips = [];
  // Skip network and broadcast addresses
  for (let i = network + 1; i < broadcast; i++) {
    const a = (i >>> 24) & 255;
    const b = (i >>> 16) & 255;
    const c = (i >>> 8) & 255;
    const d = i & 255;
    ips.push(`${a}.${b}.${c}.${d}`);
  }
  return ips;
}

async function isAlive(ip) {
  const isWindows = os.platform() === "win32";

  let cmd;
  if (isWindows) {
    // Windows: ping -n 1 -w (timeout in ms)
    cmd = `ping -n 1 -w ${TIMEOUT} ${ip}`;
  } else {
    // Linux / Termux / macOS
    cmd = `ping -c 1 -W ${Math.ceil(TIMEOUT / 1000)} ${ip}`;
  }

  try {
    await execAsync(cmd, { timeout: TIMEOUT + 1000 });
    return true;
  } catch {
    return false;
  }
}

async function runWithConcurrency(items, concurrency, fn) {
  const results = [];
  let index = 0;

  async function worker() {
    while (index < items.length) {
      const current = index++;
      const item = items[current];
      const alive = await fn(item);
      if (alive) {
        results.push(item);
        console.log(`[+] ${item}`);
      }
    }
  }

  const workers = Array.from({ length: concurrency }, () => worker());
  await Promise.all(workers);
  return results;
}

async function main() {
  let ips;
  try {
    ips = cidrToIps(NETWORK);
  } catch (err) {
    console.error("Invalid network:", err.message);
    process.exit(1);
  }

  const total = ips.length;
  console.log(`Scanning ${NETWORK} (${total} hosts) with ${WORKERS} workers...`);
  console.log("This may take a while depending on the range size.\n");

  const alive = await runWithConcurrency(ips, WORKERS, isAlive);

  // Save results
  fs.writeFileSync("reachable.txt", alive.join("\n") + (alive.length ? "\n" : ""));

  console.log("\n" + "=".repeat(40));
  console.log(`Done! ${alive.length}/${total} hosts are reachable`);
  console.log("Results saved to: reachable.txt");
  console.log("=".repeat(40));

  if (alive.length > 0) {
    console.log("\nReachable IPs:");
    console.log(alive.join("\n"));
  } else {
    console.log("\nNo reachable hosts found.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
