#ifndef UNITY_H
#define UNITY_H

void setUp(void);
void tearDown(void);
void UnityAssertEqualNumber(int expected, int actual, int line);

#define TEST_ASSERT_EQUAL(expected, actual) UnityAssertEqualNumber((expected), (actual), __LINE__)

#endif
