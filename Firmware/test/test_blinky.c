#include "unity.h"
#include "blinky.h"

// Required by Unity
void setUp(void) {}
void tearDown(void) {}

void test_toggle_led_should_return_opposite(void) {
    TEST_ASSERT_EQUAL(0, toggle_led(1));
    TEST_ASSERT_EQUAL(1, toggle_led(0));
}

// This is the main function for the unit test!
// Our container must compile this WITHOUT including src/main.c
int main(void) {
    test_toggle_led_should_return_opposite();
    return 0;
}
