#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#include <stdlib.h>
#include <threads.h>

int thread_count;

struct arg_struct {
  void *rank;
  int t;
};

void *hello(void *args);

int main(int argc, char **argv) {
  long thread;
  pthread_t* thread_handles;

  time_t t;

  srand((unsigned)time(&t));

  thread_count = strtol(argv[1], NULL, 10);

  thread_handles = malloc(sizeof(pthread_t) * thread_count);

  for (thread = 0; thread < thread_count; thread++) {
    struct arg_struct arg = {
      .rank = (void *)thread,
      .t = rand() % 10,
    };
    pthread_create(&thread_handles[thread], NULL, hello, (void*)&arg);
  }

  printf("Hello from main thread\n");

  for (thread = 0; thread < thread_count; thread++) {
    pthread_join(thread_handles[thread], NULL);
  }

  free(thread_handles);

  return 0;
}

void *hello(void *arg) {
  struct arg_struct *local_arg = arg;
  long my_rank = (long) local_arg->rank;

  sleep(local_arg->t);
  printf("hello from thread %ld of %d after %d\n", my_rank, thread_count, local_arg->t);

  return NULL;
}
