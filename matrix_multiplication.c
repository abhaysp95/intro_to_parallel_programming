#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

// doing multiplication rxc and cx1 matrix

int mat1[256][256];
unsigned r1, c1;
int mat2[256];

int res[256][256];

struct row_range {
  unsigned start;
  unsigned end;
};

void *mul_mat(void *args) {
  struct row_range *my_args = (struct row_range *)args;
#ifdef DEBUG
  printf("args recieved: %d, %d\n", my_args->start, my_args->end);
#endif
  for (unsigned row = my_args->start; row <= my_args->end; row++) {
    long sum = 0;
    for (unsigned col = 0; col < c1; col++) {
#ifdef DEBUG
      printf("multiplying mat1[%d][%d] = %d and mat2[%d] = %d\n", row, col, mat1[row][col], col, mat2[col]);
#endif
      sum += (mat1[row][col] * mat2[col]);
    }
    res[row][0] = sum;
  }

  return NULL;
}

int main(int argc, char **argv) {
  int ncpus = sysconf(_SC_NPROCESSORS_ONLN);

  printf("Enter number of rows & cols: \n");
  scanf("%u %u", &r1, &c1);
  printf("Enter the matrix[r][c]: \n");
  for (unsigned i = 0; i < r1; i++) {
    for (unsigned j = 0; j < c1; j++) {
      scanf("%d", &mat1[i][j]);
    }
  }

  printf("Enter the matrix2[r]\n(row len will be equal to row len of "
         "previous mat): \n");
  for (unsigned j = 0; j < c1; j++) {
    scanf("%d", &mat2[j]);
  }

  unsigned parts = r1 / ncpus;
  pthread_t* thread_pool = malloc(sizeof(pthread_t) * ncpus);

  unsigned spawned_thread_count = r1 < ncpus ? r1 : ncpus;
  struct row_range *args = malloc(sizeof(struct row_range) * spawned_thread_count);

  unsigned start = 0, end = 0;
  for (unsigned t = 0; t < spawned_thread_count; t++) {
    end = (parts) - 1;
    int rem = r1 % ncpus;
    if (rem != 0 && rem - 1 >= t) {  // this tells that remainder rows are included in thread or not
      end += 1;
    }
    end += start;
    args[t].start = start;
    args[t].end = end;
    start = end + 1;
  }
#ifdef DEBUG
  for (unsigned t = 0; t < spawned_thread_count; t++) {
    printf("args[%d].start = %d, args[%d].end = %d\n", t, args[t].start, t, args[t].end);
  }
#endif
  for (unsigned t = 0; t < spawned_thread_count; t++) {
    printf("Starting thread t#%d, with start: %d, end: %d\n", t, args[t].start, args[t].end);
    if (pthread_create(&thread_pool[t], NULL, mul_mat, (void *)&args[t]) != 0) {
      printf("Error occured in spawning thread. Exiting!!!\n");
      return EXIT_FAILURE;
    }
  }

  for (unsigned t = 0; t < spawned_thread_count; t++) {
    pthread_join(thread_pool[t], NULL);
  }
  free(thread_pool);
  free(args);

  printf("Resultant Matrix: \n");
  for (unsigned i = 0; i < r1; i++) {
    printf("%d ", res[i][0]);
  }
  printf("\n");

  return EXIT_SUCCESS;
}

// input
// 16 5
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 2 3 4 5 6
// 7 8 9 0 1
