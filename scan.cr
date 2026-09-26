# CF IP Scanner - Crystal version
# Compile: crystal build scan.cr -o scanner
# Run: ./scanner

# ====================== CONFIG ======================
NETWORK = "104.18.16.0/20"
WORKERS = 32
TIMEOUT = 1  # seconds
# ====================================================

def cidr_to_ips(cidr : String) : Array(String)
  ip, prefix_str = cidr.split('/')
  prefix = prefix_str.to_i

  octets = ip.split('.').map(&.to_i)
  ip_num = (octets[0] << 24) + (octets[1] << 16) + (octets[2] << 8) + octets[3]

  mask = prefix == 0 ? 0 : (~((1 << (32 - prefix)) - 1)) & 0xFFFFFFFF
  network = ip_num & mask
  broadcast = network | (~mask & 0xFFFFFFFF)

  ips = [] of String
  ((network + 1)...broadcast).each do |i|
    ips << "#{(i >> 24) & 255}.#{(i >> 16) & 255}.#{(i >> 8) & 255}.#{i & 255}"
  end
  ips
end

def is_alive(ip : String) : Bool
  cmd = if {{ flag?(:win32) }}
          "ping -n 1 -w #{TIMEOUT * 1000} #{ip}"
        else
          "ping -c 1 -W #{TIMEOUT} #{ip}"
        end

  system("#{cmd} >#{ {{ flag?(:win32) ? "nul" : "/dev/null" }} } 2>&1")
end

puts "Scanning #{NETWORK} with #{WORKERS} workers..."
puts "This may take a while depending on the range size.\n"

ips = cidr_to_ips(NETWORK)
total = ips.size
puts "Total hosts to scan: #{total}\n"

alive = [] of String
mutex = Mutex.new

channel = Channel(String).new

spawn do
  ips.each { |ip| channel.send(ip) }
  channel.close
end

WORKERS.times do
  spawn do
    loop do
      ip = channel.receive?
      break unless ip
      if is_alive(ip)
        puts "[+] #{ip}"
        mutex.synchronize { alive << ip }
      end
    end
  end
end

sleep  # wait for fibers (simplified)

alive.sort!
File.write("reachable.txt", alive.join("\n") + (alive.empty? ? "" : "\n"))

puts "\n========================================"
puts "Done! #{alive.size}/#{total} hosts are reachable"
puts "Results saved to: reachable.txt"
puts "========================================"

if alive.size > 0
  puts "\nReachable IPs:"
  puts alive.join("\n")
else
  puts "\nNo reachable hosts found."
end
