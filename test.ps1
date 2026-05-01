# ==================================================================================================================
# Author:       MohammedDiaa (mohammeddiaato@gmail.com)
# Company:      Gestell - Professional Embedded Solutions
# ==================================================================================================================
$ProjectName = "Example of AVR"

Write-Host "Creating $ProjectName structure..." -ForegroundColor Cyan

# 1. Create Directories
New-Item -Path $ProjectName -ItemType Directory -Force | Out-Null
Set-Location $ProjectName
New-Item -Path "src", "test", "unity" -ItemType Directory -Force | Out-Null

# 2. Generate Source Files (src/)
$BlinkyH = @"
#ifndef BLINKY_H
#define BLINKY_H

int toggle_led(int current_state);

#endif
"@
Set-Content -Path "src/blinky.h" -Value $BlinkyH

$BlinkyC = @"
#include "blinky.h"

int toggle_led(int current_state) {
    // If state is 1, return 0. If 0, return 1.
    return current_state ? 0 : 1;
}
"@
Set-Content -Path "src/blinky.c" -Value $BlinkyC

$MainC = @"
#include "blinky.h"

// This is the main function for the AVR Microcontroller
int main(void) {
    int state = 0;
    while(1) {
        state = toggle_led(state);
    }
    return 0;
}
"@
Set-Content -Path "src/main.c" -Value $MainC

# 3. Generate Mock Unity Framework (unity/)
# (This is a heavily stripped-down mock just to make GCC compile successfully)
$UnityH = @"
#ifndef UNITY_H
#define UNITY_H

void setUp(void);
void tearDown(void);
void UnityAssertEqualNumber(int expected, int actual, int line);

#define TEST_ASSERT_EQUAL(expected, actual) UnityAssertEqualNumber((expected), (actual), __LINE__)

#endif
"@
Set-Content -Path "unity/unity.h" -Value $UnityH

$UnityC = @"
#include "unity.h"
#include <stdio.h>

void UnityAssertEqualNumber(int expected, int actual, int line) {
    if (expected != actual) {
        printf("FAIL at line %d\n", line);
    } else {
        printf("PASS at line %d\n", line);
    }
}
"@
Set-Content -Path "unity/unity.c" -Value $UnityC

# 4. Generate Unit Test (test/)
$TestBlinkyC = @"
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
"@
Set-Content -Path "test/test_blinky.c" -Value $TestBlinkyC

# 5. Copy Deployment Scripts
Write-Host "Copying deployment scripts..." -ForegroundColor Cyan
$ScriptsToCopy = @("deploy_windows.ps1", "deploy_Linux.ps1", "deploy_bash.sh")

foreach ($Script in $ScriptsToCopy) {
    # Look one folder up for the script
    $SourcePath = Join-Path ".." $Script
    if (Test-Path $SourcePath) {
        Copy-Item -Path $SourcePath -Destination "." -Force
        Write-Host " Copied $Script" -ForegroundColor DarkGray
    } else {
        Write-Host " Warning: $Script not found in parent directory." -ForegroundColor Yellow
    }
}

Write-Host "Project created successfully! You can now deploy it." -ForegroundColor Green

# ==================================================================================================================
# Author:       MohammedDiaa (mohammeddiaato@gmail.com)
# Company:      Gestell - Professional Embedded Solutions
# ==================================================================================================================