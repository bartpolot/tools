#include <stdio.h>
#include <math.h>

int main (int argc, char *argv[]) {
  long double mean, var, f;
  unsigned int next;
  char buffer[1024];

  mean = var = f = 0.0;
  next = 1;
  while (EOF != scanf("%1023s", buffer))
    {
      long double tmp = mean;

      sscanf(buffer, "%Lf", &f);
      mean += (f - tmp) / next;
      var += (f - tmp) * (f - mean);
      next++;
    }
  printf("%Lf\t%Lf\n", mean, sqrtl(var / (next - 2)));
}
