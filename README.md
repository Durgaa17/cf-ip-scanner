# CF IP Scanner

Fast concurrent IP ping scanner available in **multiple languages**.

Originally made to scan Cloudflare IP ranges, but works with **any CIDR** range.

### Supported Languages

| Language       | File        | Best For                      |
|----------------|-------------|-------------------------------|
| Python         | `scan.py`   | Easy & cross-platform         |
| Go             | `scan.go`   | Fastest                       |
| Node.js        | `scan.js`   | JavaScript users              |
| Bash           | `scan.sh`   | Termux / Linux                |
| Rust           | `scan.rs`   | High performance + safety     |
| PowerShell     | `scan.ps1`  | Windows 11 native             |
| C              | `scan.c`    | Lightweight                   |
| **C++**        | `scan.cpp`  | Modern C++                    |
| **C#**         | `scan.cs`   | .NET / Windows                |
| PHP            | `scan.php`  | Simple scripting              |
| Ruby           | `scan.rb`   | Clean syntax                  |

---

## Quick Start (Termux)

```bash
pkg update && pkg upgrade -y
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner
```

Then choose one:

```bash
python scan.py
go run scan.go
node scan.js
chmod +x scan.sh && ./scan.sh
rustc scan.rs -o scanner && ./scanner
php scan.php
ruby scan.rb

# C
pkg install clang -y
clang scan.c -o scanner -pthread && ./scanner

# C++
clang++ -std=c++17 scan.cpp -o scanner -pthread && ./scanner
```

---

## Windows 11

```cmd
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner
```

```cmd
python scan.py
go run scan.go
node scan.js
powershell -ExecutionPolicy Bypass -File scan.ps1
php scan.php
ruby scan.rb
```

**C / C++** (requires MinGW or Visual Studio Build Tools):
```cmd
gcc scan.c -o scanner.exe -lpthread
g++ -std=c++17 scan.cpp -o scanner.exe -lpthread
scanner.exe
```

**C#** (requires .NET SDK):
```cmd
dotnet new console -n temp --force
copy scan.cs temp\Program.cs
cd temp
dotnet run
```

Or with older `csc`:
```cmd
csc scan.cs
scan.exe
```

**Rust**:
```cmd
rustc scan.rs -o scanner.exe
scanner.exe
```

---

## Configuration

Every version has the same settings at the top of the file:

- `NETWORK` / `Network` → Target CIDR (default: `104.18.16.0/20`)
- `WORKERS` / `THREADS` → Concurrent pings (default: 32)
- `TIMEOUT` → Ping timeout

Just edit the file and run again.

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

## Requirements Summary

| Language    | Requirement                     |
|-------------|---------------------------------|
| Python      | Python 3.7+                     |
| Go          | Go 1.18+                        |
| Node.js     | Node.js 14+                     |
| Bash        | Bash + Python                   |
| Rust        | Rust (rustc)                    |
| PowerShell  | PowerShell 7+ (recommended)     |
| C           | gcc / clang + pthread           |
| C++         | g++ / clang++ (C++17)           |
| C#          | .NET 6+ or Mono                 |
| PHP         | PHP 7.4+                        |
| Ruby        | Ruby 2.7+                       |

---

## License

Free to use and modify.
