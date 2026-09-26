package main

import (
	"fmt"
	"net"
	"os"
	"os/exec"
	"runtime"
	"sync"
	"time"
)

// ====================== CONFIG ======================
const (
	Network = "104.18.16.0/20" // Change this to any CIDR
	Workers = 32               // Number of concurrent pings
	Timeout = 500 * time.Millisecond
)

// ====================================================

func isAlive(ip string) bool {
	var cmd *exec.Cmd

	if runtime.GOOS == "windows" {
		// Windows: ping -n 1 -w (timeout in milliseconds)
		cmd = exec.Command("ping", "-n", "1", "-w", fmt.Sprintf("%d", Timeout.Milliseconds()), ip)
	} else {
		// Linux / Termux / macOS
		cmd = exec.Command("ping", "-c", "1", "-W", fmt.Sprintf("%d", int(Timeout.Seconds())), ip)
	}

	cmd.Stdout = nil
	cmd.Stderr = nil

	err := cmd.Run()
	return err == nil
}

func main() {
	_, ipNet, err := net.ParseCIDR(Network)
	if err != nil {
		fmt.Printf("Invalid network: %v\n", err)
		os.Exit(1)
	}

	var ips []string
	for ip := ipNet.IP.Mask(ipNet.Mask); ipNet.Contains(ip); inc(ip) {
		// Skip network and broadcast addresses
		if !ip.Equal(ipNet.IP) && !isBroadcast(ip, ipNet) {
			ips = append(ips, ip.String())
		}
	}

	total := len(ips)
	fmt.Printf("Scanning %s (%d hosts) with %d workers...\n", Network, total, Workers)
	fmt.Println("This may take a while depending on the range size.\n")

	var (
		alive []string
		mu    sync.Mutex
		wg    sync.WaitGroup
		sems  = make(chan struct{}, Workers)
	)

	for _, ip := range ips {
		wg.Add(1)
		go func(ip string) {
			defer wg.Done()
			sems <- struct{}{}
			defer func() { <-sems }()

			if isAlive(ip) {
				mu.Lock()
				alive = append(alive, ip)
				fmt.Printf("[+] %s\n", ip)
				mu.Unlock()
			}
		}(ip)
	}

	wg.Wait()

	// Save results
	f, err := os.Create("reachable.txt")
	if err != nil {
		fmt.Printf("Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	for _, ip := range alive {
		f.WriteString(ip + "\n")
	}

	fmt.Println("\n" + "========================================")
	fmt.Printf("Done! %d/%d hosts are reachable\n", len(alive), total)
	fmt.Println("Results saved to: reachable.txt")
	fmt.Println("========================================")

	if len(alive) > 0 {
		fmt.Println("\nReachable IPs:")
		for _, ip := range alive {
			fmt.Println(ip)
		}
	} else {
		fmt.Println("\nNo reachable hosts found.")
	}
}

// Helper to increment IP
func inc(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}

// Simple check to skip broadcast (works for common cases)
func isBroadcast(ip net.IP, network *net.IPNet) bool {
	broadcast := make(net.IP, len(network.IP))
	for i := range network.IP {
		broadcast[i] = network.IP[i] | ^network.Mask[i]
	}
	return ip.Equal(broadcast)
}
