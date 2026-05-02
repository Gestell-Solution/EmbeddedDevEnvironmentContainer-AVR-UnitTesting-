#include "blinky.h"

// This is the main function for the AVR Microcontroller
int main(void) {
    int state = 0;
    while(1) {
        state = toggle_led(state);
    }
    return 0;
}
