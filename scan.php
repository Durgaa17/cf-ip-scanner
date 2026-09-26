<?php
/**
 * CF IP Scanner - PHP version
 * Concurrent ping scanner
 */

// ====================== CONFIG ======================
$NETWORK = "104.18.16.0/20";  // Change this to any CIDR
$WORKERS = 32;
$TIMEOUT = 0.5;               // seconds
// ====================================================

function cidrToIps(string $cidr): array {
    list($ip, $prefix) = explode('/', $cidr);
    $prefix = (int)$prefix;

    $ipLong = ip2long($ip);
    $mask = $prefix === 0 ? 0 : (~((1 << (32 - $prefix)) - 1) & 0xFFFFFFFF);
    $network = $ipLong & $mask;
    $broadcast = $network | (~$mask & 0xFFFFFFFF);

    $ips = [];
    for ($i = $network + 1; $i < $broadcast; $i++) {
        $ips[] = long2ip($i);
    }
    return $ips;
}

function isAlive(string $ip, float $timeout): bool {
    $isWindows = strtoupper(substr(PHP_OS, 0, 3)) === 'WIN';

    if ($isWindows) {
        $cmd = sprintf('ping -n 1 -w %d %s', (int)($timeout * 1000), escapeshellarg($ip));
    } else {
        $cmd = sprintf('ping -c 1 -W %d %s', (int)$timeout, escapeshellarg($ip));
    }

    exec($cmd, $output, $returnCode);
    return $returnCode === 0;
}

echo "Scanning $NETWORK with $WORKERS workers...\n";
echo "This may take a while depending on the range size.\n\n";

$ips = cidrToIps($NETWORK);
$total = count($ips);
echo "Total hosts to scan: $total\n\n";

$alive = [];
$chunks = array_chunk($ips, (int)ceil($total / $WORKERS));

// Simple multi-process approach using pcntl if available, otherwise sequential with note
if (function_exists('pcntl_fork')) {
    $children = [];
    foreach ($chunks as $chunk) {
        $pid = pcntl_fork();
        if ($pid === -1) {
            die("Could not fork\n");
        } elseif ($pid === 0) {
            // Child
            $localAlive = [];
            foreach ($chunk as $ip) {
                if (isAlive($ip, $TIMEOUT)) {
                    echo "[+] $ip\n";
                    $localAlive[] = $ip;
                }
            }
            file_put_contents("reachable_part_" . getmypid() . ".txt", implode("\n", $localAlive) . (count($localAlive) ? "\n" : ""));
            exit(0);
        } else {
            $children[] = $pid;
        }
    }

    foreach ($children as $pid) {
        pcntl_waitpid($pid, $status);
    }

    // Collect results
    foreach (glob("reachable_part_*.txt") as $file) {
        $content = file_get_contents($file);
        if (trim($content) !== '') {
            $alive = array_merge($alive, explode("\n", trim($content)));
        }
        unlink($file);
    }
} else {
    // Fallback: sequential (or limited concurrency)
    echo "Note: pcntl not available, running with limited concurrency...\n";
    foreach ($ips as $ip) {
        if (isAlive($ip, $TIMEOUT)) {
            echo "[+] $ip\n";
            $alive[] = $ip;
        }
    }
}

sort($alive);
file_put_contents("reachable.txt", implode("\n", $alive) . (count($alive) ? "\n" : ""));

echo "\n========================================\n";
echo "Done! " . count($alive) . "/$total hosts are reachable\n";
echo "Results saved to: reachable.txt\n";
echo "========================================\n";

if (count($alive) > 0) {
    echo "\nReachable IPs:\n";
    echo implode("\n", $alive) . "\n";
} else {
    echo "\nNo reachable hosts found.\n";
}
