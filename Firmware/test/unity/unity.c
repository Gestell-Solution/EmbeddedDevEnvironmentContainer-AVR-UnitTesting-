#include "unity.h"
#include <stdio.h>

void UnityAssertEqualNumber(int expected, int actual, int line) {
    if (expected != actual) {
        printf("FAIL at line %d\n", line);
    } else {
        printf("PASS at line %d\n", line);
    }
}
