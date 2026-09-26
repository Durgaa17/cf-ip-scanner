#!/usr/bin/env swift
// CF IP Scanner - Swift version
// Run: swift scan.swift
// Or compile: swiftc scan.swift -o scanner

import Foundation

// ====================== CONFIG ======================
let NETWORK = "104.18.16.0/20"
let WORKERS = 32
let TIMEOUT: TimeInterval = 0.5
// ====================================================

func cidrToIps(_ cidr: String) -> [String] {
    let parts = cidr.split(separator: "/")
    guard parts.count == 2,
          let prefix = Int(parts[1]) else { return [] }

    let ipParts = parts[0].split(separator: ".").compactMap { UInt32($0) }
    guard ipParts.count == 4 else { return [] }

    let ip = (ipParts[0] << 24) | (ipParts[1] << 16) | (ipParts[2] << 8) | ipParts[3]
    let mask: UInt32 = prefix == 0 ? 0 : ~((1 << (32 - prefix)) - 1)
    let network = ip & mask
    let broadcast = network | ~mask

    var ips: [String] = []
    var i = network + 1
    while i < broadcast {
        let a = (i >> 24) & 255
        let b = (i >> 16) & 255
        let c = (i >> 8) & 255
        let d = i & 255
        ips.append("\(a).\(b).\(c).\(d)")
        i += 1
    }
    return ips
}

func isAlive(_ ip: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/sbin/ping")

    #if os(Windows)
    process.arguments = ["-n", "1", "-w", "\(Int(TIMEOUT * 1000))", ip]
    #else
    process.arguments = ["-c", "1", "-W", "\(Int(TIMEOUT))", ip]
    #endif

    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}

print("Scanning \(NETWORK) with \(WORKERS) workers...")
print("This may take a while depending on the range size.\n")

let ips = cidrToIps(NETWORK)
let total = ips.count
print("Total hosts to scan: \(total)\n")

var alive: [String] = []
let lock = NSLock()
let group = DispatchGroup()
let queue = DispatchQueue(label: "scanner", attributes: .concurrent)
let semaphore = DispatchSemaphore(value: WORKERS)

for ip in ips {
    semaphore.wait()
    queue.async(group: group) {
        defer { semaphore.signal() }
        if isAlive(ip) {
            print("[+] \(ip)")
            lock.lock()
            alive.append(ip)
            lock.unlock()
        }
    }
}

group.wait()

alive.sort()
try? alive.joined(separator: "\n").write(toFile: "reachable.txt", atomically: true, encoding: .utf8)

print("\n" + String(repeating: "=", count: 40))
print("Done! \(alive.count)/\(total) hosts are reachable")
print("Results saved to: reachable.txt")
print(String(repeating: "=", count: 40))

if !alive.isEmpty {
    print("\nReachable IPs:")
    print(alive.joined(separator: "\n"))
} else {
    print("\nNo reachable hosts found.")
}
