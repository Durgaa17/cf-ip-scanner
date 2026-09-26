#!/usr/bin/env ruby
# CF IP Scanner - Ruby version
# Concurrent ping scanner

require 'ipaddr'
require 'open3'
require 'thread'

# ====================== CONFIG ======================
NETWORK = "104.18.16.0/20"   # Change this to any CIDR
WORKERS = 32
TIMEOUT = 0.5                # seconds
# ====================================================

def cidr_to_ips(cidr)
  net = IPAddr.new(cidr)
  ips = []
  net.to_range.each do |ip|
    # Skip network and broadcast
    next if ip == net || ip == net.to_range.last
    ips << ip.to_s
  end
  ips
end

def alive?(ip)
  if Gem.win_platform?
    cmd = "ping -n 1 -w #{(TIMEOUT * 1000).to_i} #{ip}"
  else
    cmd = "ping -c 1 -W #{TIMEOUT.ceil} #{ip}"
  end

  system(cmd, out: File::NULL, err: File::NULL)
end

puts "Scanning #{NETWORK} with #{WORKERS} workers..."
puts "This may take a while depending on the range size.\n"

ips = cidr_to_ips(NETWORK)
total = ips.size
puts "Total hosts to scan: #{total}\n"

alive = []
mutex = Mutex.new
queue = Queue.new
ips.each { |ip| queue << ip }

workers = WORKERS.times.map do
  Thread.new do
    while ip = queue.pop(true) rescue nil
      if alive?(ip)
        mutex.synchronize do
          puts "[+] #{ip}"
          alive << ip
        end
      end
    end
  end
end

workers.each(&:join)

File.write("reachable.txt", alive.sort.join("\n") + (alive.empty? ? "" : "\n"))

puts "\n" + "=" * 40
puts "Done! #{alive.size}/#{total} hosts are reachable"
puts "Results saved to: reachable.txt"
puts "=" * 40

if alive.any?
  puts "\nReachable IPs:"
  puts alive.sort
else
  puts "\nNo reachable hosts found."
end
