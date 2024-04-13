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
  for (unsigned row = my_args->start; row < my_args->end; row++) {
    long sum = 0;
    for (unsigned col = 0; col < c1; col++) {
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

  for (unsigned t = 0; t < ncpus; t++) {
    struct row_range args = {
      .start = t * parts,
      .end = (t + 1) * parts - 1,
    };
    unsigned start = t * parts;
    unsigned end = (t + 1) * parts - 1;
    if (pthread_create(&thread_pool[t], NULL, mul_mat, (void *)&args) != 0) {
      printf("Error occured in spawning thread. Exiting!!!\n");
      return EXIT_FAILURE;
    }
  }

  for (unsigned t = 0; t < ncpus; t++) {
    pthread_join(thread_pool[t], NULL);
  }
  free(thread_pool);

  printf("Resultant Matrix: \n");
  for (unsigned i = 0; i < r1; i++) {
    printf("%d ", res[i][0]);
  }
  printf("\n");

  return EXIT_SUCCESS;
}

// printf("Enter number of rows [multiple of %d]: \n", ncpus);
// int rows = 0;
// scanf("%d", &rows);
//
// int parts = rows / ncpus;
// for (unsigned i = 0; i < ncpus; i++) {
//   int start = i * parts;
//   int end = (i + 1) * parts - 1;
//   printf("start: %d, end: %d\n", start, end);
// }
