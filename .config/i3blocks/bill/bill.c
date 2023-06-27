#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <pthread.h>

typedef struct config_t {
    char *symbol;
    double hourly_amt;
    double yearly_amt;
    long hours_per_year;
    long seconds_per_year;
    long update_speed_ms;
    uint8_t decimals;
} config_t;

bool pause_break = false;
bool reset = false;

int msleep(long msec) {
	struct timespec ts;
	int res;

	if (msec < 0) {
		errno = EINVAL;
		return -1;
	}

	ts.tv_sec = msec / 1000;
	ts.tv_nsec = (msec % 1000) * 1000000;

	do {
		res = nanosleep(&ts, &ts);
	} while (res && errno == EINTR);

	return res;
}

void print_output(char *symbol, uint8_t decimals, double total_amount) {
    printf("BILL %s%.*lf\n", symbol, decimals, total_amount);

	fflush(stdout);
}

#define HOURLY_WORK_SECONDS 3600

void run_ptimer(config_t conf) {
    double amt_s;
    struct timespec start_t, cur_t, pause_t;
	uint64_t diff_us = 0, pause_us = 0;
    double d_us;

    if (conf.hourly_amt > 0.0) {
        amt_s = conf.hourly_amt / HOURLY_WORK_SECONDS;
    } else if (conf.yearly_amt > 0.0) {
        amt_s = conf.yearly_amt / conf.seconds_per_year;
    } else {
        amt_s = 0.0;
    }

	clock_gettime(CLOCK_MONOTONIC, &start_t);
	while (!reset) {
		msleep(conf.update_speed_ms);
		clock_gettime(CLOCK_MONOTONIC, &cur_t);

		diff_us = (cur_t.tv_sec - start_t.tv_sec) * 1000000
			+ (cur_t.tv_nsec - start_t.tv_nsec) / 1000;

        d_us = ((double)diff_us / 1000000) - ((double)pause_us / 1000000);

		print_output(conf.symbol, conf.decimals, amt_s * d_us);

        while (pause_break && !reset) {
            clock_gettime(CLOCK_MONOTONIC, &pause_t);
            msleep(conf.update_speed_ms);

            clock_gettime(CLOCK_MONOTONIC, &cur_t);
            pause_us += (cur_t.tv_sec - pause_t.tv_sec) * 1000000
                + (cur_t.tv_nsec - pause_t.tv_nsec) / 1000;
        }
	}
}

#define PAUSE_CLICK "1"
#define RESET_CLICK "3"

void *pause_break_handler(void *) {
    char buff[256];

    while (fgets(buff, 256, stdin)) {
        if (strncmp(buff, PAUSE_CLICK, 1) == 0) {
            pause_break = !pause_break;
        } else if (strncmp(buff, RESET_CLICK, 1) == 0) {
            reset = true;
        }
    }

    return NULL;
}

int spawn_detached_thread(void *(*t_handler)(void *), void *args) {
    pthread_t tid;
    if (pthread_create(&tid, NULL, t_handler, args)) {
        return -1;
    }

    if (pthread_detach(tid)) {
        return -2;
    }

    return 0;
}

#define SET_STRING_VAL(str, format, var, def) { \
        char *__n_str = getenv(str);                \
        if (!__n_str) {                             \
            var = def;                              \
        } else {                                    \
            sscanf(__n_str, format, &var);          \
        }                                           \
    }

int main(int argc, char *argv[]) {
    config_t conf;

    SET_STRING_VAL("yearly_amount", "%lf", conf.yearly_amt, -1.0);
    SET_STRING_VAL("hours_per_year", "%ld", conf.hours_per_year, 2080);
    conf.seconds_per_year = conf.hours_per_year * 60 * 60;
    SET_STRING_VAL("hourly_amount", "%lf", conf.hourly_amt, -1.0);
    SET_STRING_VAL("update_speed", "%ld", conf.update_speed_ms, 50);
    SET_STRING_VAL("decimal_length", "%hhu", conf.decimals, 2);

    conf.symbol = getenv("lead_symbol");
    if (!conf.symbol) {
        conf.symbol = "$";
    }

    spawn_detached_thread(pause_break_handler, NULL);

    while (1) {
        reset = false;
        pause_break = false;
        run_ptimer(conf);
    }

    return 0;
}
