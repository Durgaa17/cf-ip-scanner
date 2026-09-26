# CF IP Scanner

Fast concurrent IP ping scanner available in **21 languages**.

Originally made to scan Cloudflare IP ranges, but works with **any CIDR** range.

### Supported Languages

| Language       | File         | Best For                      |
|----------------|--------------|-------------------------------|
| Python         | `scan.py`    | Easy & cross-platform         |
| Go             | `scan.go`    | Fastest                       |
| Node.js        | `scan.js`    | JavaScript users              |
| TypeScript     | `scan.ts`    | Typed JavaScript              |
| Bash           | `scan.sh`    | Termux / Linux                |
| Rust           | `scan.rs`    | High performance + safety     |
| PowerShell     | `scan.ps1`   | Windows 11 native             |
| C              | `scan.c`     | Lightweight                   |
| C++            | `scan.cpp`   | Modern C++                    |
| C#             | `scan.cs`    | .NET / Windows                |
| Java           | `scan.java`  | Cross-platform JVM            |
| Kotlin         | `scan.kt`    | Modern JVM                    |
| Swift          | `scan.swift` | Modern Apple language         |
| PHP            | `scan.php`   | Simple scripting              |
| Ruby           | `scan.rb`    | Clean syntax                  |
| Perl           | `scan.pl`    | Classic scripting             |
| Lua            | `scan.lua`   | Extremely lightweight         |
| Dart           | `scan.dart`  | Flutter / modern              |
| Zig            | `scan.zig`   | Modern systems language       |
| Nim            | `scan.nim`   | Clean & compiled              |
| Crystal        | `scan.cr`    | Ruby-like but fast            |

---

## Quick Start (Termux)

```bash
pkg update && pkg upgrade -y
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner
```

Then run any version you like.

---

## Configuration

All versions use the same settings at the top of the file:

- `NETWORK` → Target CIDR (default: `104.18.16.0/20`)
- `WORKERS` → Concurrent pings (default: 32)
- `TIMEOUT` → Ping timeout

---

## Example Output

```
Scanning 104.18.16.0/20 with 32 workers...
Total hosts to scan: 4094

[+] 104.18.16.5
[+] 104.18.17.23
...

========================================
Done! 47/4094 hosts are reachable
Results saved to: reachable.txt
========================================
```

---

## License

Free to use and modify.
