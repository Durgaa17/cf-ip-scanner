import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * CF IP Scanner - Java version
 * Compile: javac scan.java
 * Run:     java scan
 */
public class scan {

    // ====================== CONFIG ======================
    static final String NETWORK = "104.18.16.0/20";  // Change this to any CIDR
    static final int WORKERS = 32;
    static final int TIMEOUT_MS = 500;
    // ====================================================

    public static void main(String[] args) throws Exception {
        System.out.println("Scanning " + NETWORK + " with " + WORKERS + " workers...");
        System.out.println("This may take a while depending on the range size.\n");

        List<String> ips = cidrToIps(NETWORK);
        int total = ips.size();
        System.out.println("Total hosts to scan: " + total + "\n");

        List<String> alive = Collections.synchronizedList(new ArrayList<>());
        ExecutorService executor = Executors.newFixedThreadPool(WORKERS);
        AtomicInteger completed = new AtomicInteger(0);

        for (String ip : ips) {
            executor.submit(() -> {
                if (isAlive(ip)) {
                    System.out.println("[+] " + ip);
                    alive.add(ip);
                }
            });
        }

        executor.shutdown();
        executor.awaitTermination(1, TimeUnit.HOURS);

        Collections.sort(alive);

        try (PrintWriter out = new PrintWriter("reachable.txt")) {
            for (String ip : alive) {
                out.println(ip);
            }
        }

        System.out.println("\n========================================");
        System.out.println("Done! " + alive.size() + "/" + total + " hosts are reachable");
        System.out.println("Results saved to: reachable.txt");
        System.out.println("========================================");

        if (!alive.isEmpty()) {
            System.out.println("\nReachable IPs:");
            for (String ip : alive) {
                System.out.println(ip);
            }
        } else {
            System.out.println("\nNo reachable hosts found.");
        }
    }

    static List<String> cidrToIps(String cidr) throws Exception {
        String[] parts = cidr.split("/");
        String ipStr = parts[0];
        int prefix = Integer.parseInt(parts[1]);

        byte[] bytes = InetAddress.getByName(ipStr).getAddress();
        int ip = ((bytes[0] & 0xFF) << 24) | ((bytes[1] & 0xFF) << 16) |
                 ((bytes[2] & 0xFF) << 8) | (bytes[3] & 0xFF);

        int mask = prefix == 0 ? 0 : 0xFFFFFFFF << (32 - prefix);
        int network = ip & mask;
        int broadcast = network | ~mask;

        List<String> result = new ArrayList<>();
        for (int i = network + 1; i < broadcast; i++) {
            result.add(String.format("%d.%d.%d.%d",
                    (i >> 24) & 0xFF,
                    (i >> 16) & 0xFF,
                    (i >> 8) & 0xFF,
                    i & 0xFF));
        }
        return result;
    }

    static boolean isAlive(String ip) {
        try {
            boolean isWindows = System.getProperty("os.name").toLowerCase().contains("win");
            List<String> command = new ArrayList<>();
            command.add("ping");

            if (isWindows) {
                command.add("-n");
                command.add("1");
                command.add("-w");
                command.add(String.valueOf(TIMEOUT_MS));
            } else {
                command.add("-c");
                command.add("1");
                command.add("-W");
                command.add(String.valueOf(Math.max(1, TIMEOUT_MS / 1000)));
            }
            command.add(ip);

            ProcessBuilder pb = new ProcessBuilder(command);
            pb.redirectErrorStream(true);
            Process process = pb.start();

            boolean finished = process.waitFor(TIMEOUT_MS + 1000, TimeUnit.MILLISECONDS);
            if (!finished) {
                process.destroyForcibly();
                return false;
            }
            return process.exitValue() == 0;
        } catch (Exception e) {
            return false;
        }
    }
}
