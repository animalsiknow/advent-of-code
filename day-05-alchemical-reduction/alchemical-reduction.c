#include <fcntl.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

void find_previous_unit(char **p, char *begin) {
  while (*p > begin && **p == 0) {
    *p -= 1;
  }
}

void find_next_unit(char **p, char *end) {
  while (*p < end && **p == 0) {
    *p += 1;
  }
}

bool units_react_p(char l, char r) {
  return (l ^ r) == 0x20;
}

struct polymer {
  char *buf;
  size_t sz;
};

const struct polymer null_polymer = (struct polymer){
  .buf = NULL,
  .sz = 0,
};

bool polymer_null_p(struct polymer polymer) {
  return polymer.buf == NULL;
}

struct polymer polymer_read(char *path) {
  int fd = open(path, O_RDONLY);
  if (fd < 0) {
    perror("can't open puzzle input");
    return null_polymer;
  }

  size_t bufsz = 1 << 16;
  char *buf = malloc(bufsz);
  if (buf == NULL) {
    return null_polymer;
  }
  memset(buf, 0, bufsz);

  ssize_t n = read(fd, buf, bufsz);
  if (n < 0) {
    perror("can't read puzzle input");
    return null_polymer;
  } else if ((size_t)n == bufsz) {
    return null_polymer;
  }
  close(fd);

  return (struct polymer){
    .buf = buf,
    .sz = n,
  };
}

struct polymer polymer_copy(struct polymer polymer) {
  size_t sz = polymer.sz;
  struct polymer copy = (struct polymer){
    .buf = malloc(sz),
    .sz = sz,
  };

  memcpy(copy.buf, polymer.buf, sz);
  return copy;
}

void polymer_free(struct polymer polymer) {
  free(polymer.buf);
}

size_t polymer_reduce(struct polymer polymer) {
  size_t n = 0;
  char *a = polymer.buf, *b = polymer.buf + 1, *end = polymer.buf + polymer.sz;
  for (;b != end; b += 1, find_next_unit(&b, end)) {
    if (units_react_p(*a, *b)) {
      *a = 0;
      *b = 0;
      n += 2;
      find_previous_unit(&a, polymer.buf);
    } else {
      a = b;
    }
  }

  return polymer.sz - n;
}

size_t polymer_delete_unit(struct polymer polymer, char unit) {
  size_t n = 0;
  char *end = polymer.buf + polymer.sz;
  for (char *i = polymer.buf; i < end; i += 1) {
    if (*i == unit || *i == (unit ^ 0x20)) {
      *i = 0;
      n += 1;
    }
  }
  return n;
}

int main(int argc, char *argv[]) {
  (void)argc;
  (void)argv;

  struct polymer original = polymer_read("./alchemical-reduction.txt");
  if (polymer_null_p(original)) {
    return 1;
  }

  {
    struct polymer polymer = polymer_copy(original);
    size_t final_size = polymer_reduce(polymer);
    printf("final size: %zu\n", final_size);
    polymer_free(polymer);
  }

  char best_unit;
  size_t best_size = SIZE_MAX;
  for (char unit = 'a'; unit <= 'z'; unit += 1) {
    struct polymer polymer = polymer_copy(original);
    size_t deleted = polymer_delete_unit(polymer, unit);
    size_t size = polymer_reduce(polymer) - deleted;
    if (size < best_size) {
      best_unit = unit;
      best_size = size;
    }
  }

  printf("best unit to delete: %c (final size: %zu)\n", (int)best_unit, best_size);
  polymer_free(original);
  return 0;
}
