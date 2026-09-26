#!/usr/bin/env perl
# CF IP Scanner - Perl version

use strict;
use warnings;
use threads;
use Thread::Queue;
use IO::File;

# ====================== CONFIG ======================
my $NETWORK = "104.18.16.0/20";
my $WORKERS = 32;
my $TIMEOUT = 1;  # seconds
# ====================================================

sub cidr_to_ips {
    my ($cidr) = @_;
    my ($ip, $prefix) = split m{/}, $cidr;
    $prefix = int($prefix);

    my @octets = split /\./, $ip;
    my $ip_num = ($octets[0] << 24) + ($octets[1] << 16) + ($octets[2] << 8) + $octets[3];

    my $mask = $prefix == 0 ? 0 : (~((1 << (32 - $prefix)) - 1)) & 0xFFFFFFFF;
    my $network = $ip_num & $mask;
    my $broadcast = $network | (~$mask & 0xFFFFFFFF);

    my @ips;
    for (my $i = $network + 1; $i < $broadcast; $i++) {
        push @ips, sprintf("%d.%d.%d.%d",
            ($i >> 24) & 255,
            ($i >> 16) & 255,
            ($i >> 8) & 255,
            $i & 255);
    }
    return @ips;
}

sub is_alive {
    my ($ip) = @_;
    my $cmd;
    if ($^O =~ /MSWin32|msys|cygwin/i) {
        $cmd = "ping -n 1 -w " . ($TIMEOUT * 1000) . " $ip >nul 2>&1";
    } else {
        $cmd = "ping -c 1 -W $TIMEOUT $ip >/dev/null 2>&1";
    }
    return system($cmd) == 0;
}

print "Scanning $NETWORK with $WORKERS workers...\n";
print "This may take a while depending on the range size.\n\n";

my @ips = cidr_to_ips($NETWORK);
my $total = scalar @ips;
print "Total hosts to scan: $total\n\n";

my $queue = Thread::Queue->new();
$queue->enqueue(@ips);
$queue->end();

my @alive;
my $mutex = threads::shared::share({});

my @threads;
for (1 .. $WORKERS) {
    push @threads, threads->create(sub {
        while (defined(my $ip = $queue->dequeue())) {
            if (is_alive($ip)) {
                print "[+] $ip\n";
                lock($mutex);
                push @alive, $ip;
            }
        }
    });
}

$_->join() for @threads;

@alive = sort @alive;

open my $fh, '>', 'reachable.txt' or die $!;
print $fh join("\n", @alive), (@alive ? "\n" : "");
close $fh;

print "\n========================================\n";
print "Done! " . scalar(@alive) . "/$total hosts are reachable\n";
print "Results saved to: reachable.txt\n";
print "========================================\n";

if (@alive) {
    print "\nReachable IPs:\n";
    print join("\n", @alive), "\n";
} else {
    print "\nNo reachable hosts found.\n";
}
