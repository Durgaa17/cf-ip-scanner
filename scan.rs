use std::net::Ipv4Addr;
use std::process::Command;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;
use std::fs::File;
use std::io::Write;

// ====================== CONFIG ======================
const NETWORK: &str = "104.18.16.0/20"; // Change this to any CIDR
const WORKERS: usize = 32;
const TIMEOUT_MS: u64 = 500;
// ====================================================

fn cidr_to_ips(cidr: &str) -> Vec<String> {
    let parts: Vec<&str> = cidr.split('/').collect();
    let ip: Ipv4Addr = parts[0].parse().expect("Invalid IP");
    let prefix: u32 = parts[1].parse().expect("Invalid prefix");

    let ip_u32 = u32::from(ip);
    let mask = if prefix == 0 { 0 } else { !((1u32 << (32 - prefix)) - 1) };
    let network = ip_u32 & mask;
    let broadcast = network | !mask;

    let mut ips = Vec::new();
    for i in (network + 1)..broadcast {
        let addr = Ipv4Addr::from(i);
        ips.push(addr.to_string());
    }
    ips
}

fn is_alive(ip: &str) -> bool {
    let output = if cfg!(target_os = "windows") {
        Command::new("ping")
            .args(["-n", "1", "-w", &TIMEOUT_MS.to_string(), ip])
            .output()
    } else {
        Command::new("ping")
            .args(["-c", "1", "-W", &(TIMEOUT_MS / 1000).max(1).to_string(), ip])
            .output()
    };

    match output {
        Ok(o) => o.status.success(),
        Err(_) => false,
    }
}

fn main() {
    let ips = cidr_to_ips(NETWORK);
    let total = ips.len();

    println!("Scanning {} ({} hosts) with {} workers...", NETWORK, total, WORKERS);
    println!("This may take a while depending on the range size.\n");

    let alive = Arc::new(Mutex::new(Vec::new()));
    let mut handles = vec![];

    let chunk_size = (ips.len() + WORKERS - 1) / WORKERS;

    for chunk in ips.chunks(chunk_size) {
        let chunk = chunk.to_vec();
        let alive = Arc::clone(&alive);

        let handle = thread::spawn(move || {
            for ip in chunk {
                if is_alive(&ip) {
                    println!("[+] {}", ip);
                    alive.lock().unwrap().push(ip);
                }
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    let alive = alive.lock().unwrap();
    let mut file = File::create("reachable.txt").expect("Unable to create file");
    for ip in alive.iter() {
        writeln!(file, "{}", ip).unwrap();
    }

    println!("\n{}", "=".repeat(40));
    println!("Done! {}/{} hosts are reachable", alive.len(), total);
    println!("Results saved to: reachable.txt");
    println!("{}", "=".repeat(40));

    if !alive.is_empty() {
        println!("\nReachable IPs:");
        for ip in alive.iter() {
            println!("{}", ip);
        }
    } else {
        println!("\nNo reachable hosts found.");
    }
}
