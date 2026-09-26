#!/usr/bin/env dart
// CF IP Scanner - Dart version
// Run: dart scan.dart

import 'dart:io';
import 'dart:async';

// ====================== CONFIG ======================
const String NETWORK = "104.18.16.0/20";
const int WORKERS = 32;
const int TIMEOUT_MS = 500;
// ====================================================

List<String> cidrToIps(String cidr) {
  final parts = cidr.split('/');
  final ipStr = parts[0];
  final prefix = int.parse(parts[1]);

  final octets = ipStr.split('.').map(int.parse).toList();
  int ip = (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3];

  final mask = prefix == 0 ? 0 : (~((1 << (32 - prefix)) - 1)) & 0xFFFFFFFF;
  final network = ip & mask;
  final broadcast = network | (~mask & 0xFFFFFFFF);

  final ips = <String>[];
  for (int i = network + 1; i < broadcast; i++) {
    ips.add("${(i >> 24) & 255}.${(i >> 16) & 255}.${(i >> 8) & 255}.${i & 255}");
  }
  return ips;
}

Future<bool> isAlive(String ip) async {
  final isWindows = Platform.isWindows;
  final args = isWindows
      ? ['-n', '1', '-w', '$TIMEOUT_MS', ip]
      : ['-c', '1', '-W', '${(TIMEOUT_MS / 1000).ceil()}', ip];

  try {
    final result = await Process.run('ping', args)
        .timeout(Duration(milliseconds: TIMEOUT_MS + 1000));
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<void> main() async {
  print("Scanning $NETWORK with $WORKERS workers...");
  print("This may take a while depending on the range size.\n");

  final ips = cidrToIps(NETWORK);
  final total = ips.length;
  print("Total hosts to scan: $total\n");

  final alive = <String>[];
  final queue = [...ips];
  final futures = <Future>[];

  for (int i = 0; i < WORKERS; i++) {
    futures.add(Future(() async {
      while (queue.isNotEmpty) {
        final ip = queue.removeAt(0);
        if (await isAlive(ip)) {
          print("[+] $ip");
          alive.add(ip);
        }
      }
    }));
  }

  await Future.wait(futures);

  alive.sort();
  await File('reachable.txt').writeAsString(alive.join('\n') + (alive.isNotEmpty ? '\n' : ''));

  print("\n========================================");
  print("Done! ${alive.length}/$total hosts are reachable");
  print("Results saved to: reachable.txt");
  print("========================================");

  if (alive.isNotEmpty) {
    print("\nReachable IPs:");
    print(alive.join('\n'));
  } else {
    print("\nNo reachable hosts found.");
  }
}
