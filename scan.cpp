/*
 * CF IP Scanner - C++ version
 * Compile: g++ -std=c++17 scan.cpp -o scanner -pthread
 */

#include <iostream>
#include <vector>
#include <string>
#include <thread>
#include <mutex>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <arpa/inet.h>

// ====================== CONFIG ======================
const std::string NETWORK = "104.18.16.0/20";
const int WORKERS = 32;
const int TIMEOUT = 1; // seconds
// ====================================================

std::mutex mtx;
std::vector<std::string> alive;

bool isAlive(const std::string& ip) {
    std::string cmd;
#ifdef _WIN32
    cmd = "ping -n 1 -w " + std::to_string(TIMEOUT * 1000) + " " + ip + " >nul 2>&1";
#else
    cmd = "ping -c 1 -W " + std::to_string(TIMEOUT) + " " + ip + " >/dev/null 2>&1";
#endif
    return system(cmd.c_str()) == 0;
}

std::vector<std::string> cidrToIps(const std::string& cidr) {
    std::vector<std::string> ips;
    char ipstr[16];
    int prefix;
    sscanf(cidr.c_str(), "%15[^/]/%d", ipstr, &prefix);

    in_addr addr{};
    inet_pton(AF_INET, ipstr, &addr);
    uint32_t ip = ntohl(addr.s_addr);

    uint32_t mask = prefix == 0 ? 0 : ~((1u << (32 - prefix)) - 1);
    uint32_t network = ip & mask;
    uint32_t broadcast = network | ~mask;

    for (uint32_t i = network + 1; i < broadcast; ++i) {
        in_addr a{};
        a.s_addr = htonl(i);
        char buf[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &a, buf, sizeof(buf));
        ips.emplace_back(buf);
    }
    return ips;
}

void worker(const std::vector<std::string>& ips, size_t start, size_t end) {
    for (size_t i = start; i < end; ++i) {
        if (isAlive(ips[i])) {
            std::lock_guard<std::mutex> lock(mtx);
            std::cout << "[+] " << ips[i] << std::endl;
            alive.push_back(ips[i]);
        }
    }
}

int main() {
    std::cout << "Scanning " << NETWORK << " with " << WORKERS << " workers...\n";
    std::cout << "This may take a while depending on the range size.\n\n";

    auto ips = cidrToIps(NETWORK);
    size_t total = ips.size();
    std::cout << "Total hosts to scan: " << total << "\n\n";

    std::vector<std::thread> threads;
    size_t chunk = (total + WORKERS - 1) / WORKERS;

    for (int i = 0; i < WORKERS; ++i) {
        size_t start = i * chunk;
        size_t end = std::min(start + chunk, total);
        if (start >= total) break;
        threads.emplace_back(worker, std::cref(ips), start, end);
    }

    for (auto& t : threads) {
        t.join();
    }

    std::ofstream out("reachable.txt");
    for (const auto& ip : alive) {
        out << ip << "\n";
    }
    out.close();

    std::cout << "\n========================================\n";
    std::cout << "Done! " << alive.size() << "/" << total << " hosts are reachable\n";
    std::cout << "Results saved to: reachable.txt\n";
    std::cout << "========================================\n";

    if (!alive.empty()) {
        std::cout << "\nReachable IPs:\n";
        for (const auto& ip : alive) {
            std::cout << ip << "\n";
        }
    } else {
        std::cout << "\nNo reachable hosts found.\n";
    }

    return 0;
}
