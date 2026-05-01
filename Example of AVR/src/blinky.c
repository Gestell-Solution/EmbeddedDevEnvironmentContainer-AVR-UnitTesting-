#include "blinky.h"

int toggle_led(int current_state) {
    // If state is 1, return 0. If 0, return 1.
    return current_state ? 0 : 1;
}
