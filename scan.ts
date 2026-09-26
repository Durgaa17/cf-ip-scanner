#!/usr/bin/env node
/**
 * CF IP Scanner - TypeScript version
 * Run: npx ts-node scan.ts
 * Or compile: tsc scan.ts && node scan.js
 */

import { exec } from "child_process";
import { promisify } from "util";
import * as fs from "fs";
import * as os from "os";

// ====================== CONFIG ======================
const NETWORK = "104.18.16.0/20"; // Change this to any CIDR
const WORKERS = 32;
const TIMEOUT = 500; // milliseconds
// ====================================================

const execAsync = promisify(exec);

function cidrToIps(cidr: string): string[] {
  const [ip, prefixStr] = cidr.split("/");
  const prefix = parseInt(prefixStr, 10);

  const ipParts = ip.split(".").map(Number);
  const ipNum = (ipParts[0] << 24) + (ipParts[1] << 16) + (ipParts[2] << 8) + ipParts[3];

  const mask = prefix === 0 ? 0 : (~((1 << (32 - prefix)) - 1)) >>> 0;
  const network = (ipNum & mask) >>> 0;
  const broadcast = (network | (~mask >>> 0)) >>> 0;

  const ips: string[] = [];
  for (let i = network + 1; i < broadcast; i++) {
    const a = (i >>> 24) & 255;
    const b = (i >>> 16) & 255;
    const c = (i >>> 8) & 255;
    const d = i & 255;
    ips.push(`${a}.${b}.${c}.${d}`);
  }
  return ips;
}

async function isAlive(ip: string): Promise<boolean> {
  const isWindows = os.platform() === "win32";
  const cmd = isWindows
    ? `ping -n 1 -w ${TIMEOUT} ${ip}`
    : `ping -c 1 -W ${Math.ceil(TIMEOUT / 1000)} ${ip}`;

  try {
    await execAsync(cmd, { timeout: TIMEOUT + 1000 });
    return true;
  } catch {
    return false;
  }
}

async function runWithConcurrency<T, R>(
  items: T[],
  concurrency: number,
  fn: (item: T) => Promise<R>
): Promise<R[]> {
  const results: R[] = [];
  let index = 0;

  async function worker() {
    while (index < items.length) {
      const current = index++;
      const result = await fn(items[current]);
      if (result) results.push(result);
    }
  }

  const workers = Array.from({ length: concurrency }, () => worker());
  await Promise.all(workers);
  return results;
}

async function main() {
  console.log(`Scanning ${NETWORK} with ${WORKERS} workers...`);
  console.log("This may take a while depending on the range size.\n");

  const ips = cidrToIps(NETWORK);
  const total = ips.length;
  console.log(`Total hosts to scan: ${total}\n`);

  const alive = await runWithConcurrency(ips, WORKERS, async (ip) => {
    if (await isAlive(ip)) {
      console.log(`[+] ${ip}`);
      return ip;
    }
    return null;
  });

  const filtered = alive.filter(Boolean) as string[];
  fs.writeFileSync("reachable.txt", filtered.join("\n") + (filtered.length ? "\n" : ""));

  console.log("\n" + "=".repeat(40));
  console.log(`Done! ${filtered.length}/${total} hosts are reachable`);
  console.log("Results saved to: reachable.txt");
  console.log("=".repeat(40));

  if (filtered.length > 0) {
    console.log("\nReachable IPs:");
    console.log(filtered.join("\n"));
  } else {
    console.log("\nNo reachable hosts found.");
  }
}

main().catch(console.error);
