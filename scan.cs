// CF IP Scanner - C# version
// Compile: dotnet new console -n scanner --force && copy scan.cs Program.cs && dotnet run
// Or: csc scan.cs && scan.exe

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading.Tasks;

class Program
{
    // ====================== CONFIG ======================
    const string Network = "104.18.16.0/20";   // Change this to any CIDR
    const int Workers = 32;
    const int TimeoutMs = 500;
    // ====================================================

    static List<string> CidrToIps(string cidr)
    {
        var parts = cidr.Split('/');
        var ip = IPAddress.Parse(parts[0]);
        int prefix = int.Parse(parts[1]);

        byte[] bytes = ip.GetAddressBytes();
        if (BitConverter.IsLittleEndian) Array.Reverse(bytes);
        uint ipInt = BitConverter.ToUInt32(bytes, 0);

        uint mask = prefix == 0 ? 0 : ~((1u << (32 - prefix)) - 1);
        uint network = ipInt & mask;
        uint broadcast = network | ~mask;

        var ips = new List<string>();
        for (uint i = network + 1; i < broadcast; i++)
        {
            byte[] b = BitConverter.GetBytes(i);
            if (BitConverter.IsLittleEndian) Array.Reverse(b);
            ips.Add(new IPAddress(b).ToString());
        }
        return ips;
    }

    static bool IsAlive(string ip)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = "ping",
                Arguments = OperatingSystem.IsWindows()
                    ? $"-n 1 -w {TimeoutMs} {ip}"
                    : $"-c 1 -W {Math.Max(1, TimeoutMs / 1000)} {ip}",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(psi);
            process.WaitForExit(TimeoutMs + 1000);
            return process.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    static async Task Main()
    {
        Console.WriteLine($"Scanning {Network} with {Workers} workers...");
        Console.WriteLine("This may take a while depending on the range size.\n");

        var ips = CidrToIps(Network);
        int total = ips.Count;
        Console.WriteLine($"Total hosts to scan: {total}\n");

        var alive = new ConcurrentBag<string>();

        await Parallel.ForEachAsync(ips, new ParallelOptions { MaxDegreeOfParallelism = Workers }, async (ip, ct) =>
        {
            if (IsAlive(ip))
            {
                Console.WriteLine($"[+] {ip}");
                alive.Add(ip);
            }
        });

        var sorted = alive.OrderBy(x => x).ToList();
        await File.WriteAllLinesAsync("reachable.txt", sorted);

        Console.WriteLine("\n========================================");
        Console.WriteLine($"Done! {sorted.Count}/{total} hosts are reachable");
        Console.WriteLine("Results saved to: reachable.txt");
        Console.WriteLine("========================================");

        if (sorted.Count > 0)
        {
            Console.WriteLine("\nReachable IPs:");
            foreach (var ip in sorted)
                Console.WriteLine(ip);
        }
        else
        {
            Console.WriteLine("\nNo reachable hosts found.");
        }
    }
}
