/*
 * CF IP Scanner - C version
 * Lightweight concurrent ping scanner
 * Compile: gcc scan.c -o scanner -lpthread
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <arpa/inet.h>
#include <sys/wait.h>

// ====================== CONFIG ======================
#define NETWORK "104.18.16.0/20"
#define WORKERS 32
#define TIMEOUT 1          // seconds (ping -W)
// ====================================================

typedef struct {
    char ip[16];
} ip_t;

ip_t *ips;
int total_ips = 0;
int alive_count = 0;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
FILE *outfile;

int is_alive(const char *ip) {
    char cmd[128];
#ifdef _WIN32
    snprintf(cmd, sizeof(cmd), "ping -n 1 -w %d %s >nul 2>&1", TIMEOUT * 1000, ip);
#else
    snprintf(cmd, sizeof(cmd), "ping -c 1 -W %d %s >/dev/null 2>&1", TIMEOUT, ip);
#endif
    return system(cmd) == 0;
}

void *worker(void *arg) {
    int start = *(int *)arg;
    int end = start + (total_ips + WORKERS - 1) / WORKERS;
    if (end > total_ips) end = total_ips;

    for (int i = start; i < end; i++) {
        if (is_alive(ips[i].ip)) {
            pthread_mutex_lock(&lock);
            printf("[+] %s\n", ips[i].ip);
            fprintf(outfile, "%s\n", ips[i].ip);
            alive_count++;
            pthread_mutex_unlock(&lock);
        }
    }
    return NULL;
}

void generate_ips(const char *cidr) {
    char ipstr[16];
    int prefix;
    sscanf(cidr, "%15[^/]/%d", ipstr, &prefix);

    struct in_addr addr;
    inet_pton(AF_INET, ipstr, &addr);
    uint32_t ip = ntohl(addr.s_addr);

    uint32_t mask = prefix == 0 ? 0 : ~((1U << (32 - prefix)) - 1);
    uint32_t network = ip & mask;
    uint32_t broadcast = network | ~mask;

    total_ips = broadcast - network - 1;
    ips = malloc(total_ips * sizeof(ip_t));

    int idx = 0;
    for (uint32_t i = network + 1; i < broadcast; i++) {
        struct in_addr a;
        a.s_addr = htonl(i);
        inet_ntop(AF_INET, &a, ips[idx].ip, sizeof(ips[idx].ip));
        idx++;
    }
}

int main() {
    printf("Scanning %s with %d workers...\n", NETWORK, WORKERS);
    printf("This may take a while depending on the range size.\n\n");

    generate_ips(NETWORK);
    printf("Total hosts to scan: %d\n\n", total_ips);

    outfile = fopen("reachable.txt", "w");
    if (!outfile) {
        perror("Failed to create reachable.txt");
        return 1;
    }

    pthread_t threads[WORKERS];
    int starts[WORKERS];

    for (int i = 0; i < WORKERS; i++) {
        starts[i] = i * ((total_ips + WORKERS - 1) / WORKERS);
        pthread_create(&threads[i], NULL, worker, &starts[i]);
    }

    for (int i = 0; i < WORKERS; i++) {
        pthread_join(threads[i], NULL);
    }

    fclose(outfile);
    free(ips);

    printf("\n========================================\n");
    printf("Done! %d/%d hosts are reachable\n", alive_count, total_ips);
    printf("Results saved to: reachable.txt\n");
    printf("========================================\n");

    return 0;
}
