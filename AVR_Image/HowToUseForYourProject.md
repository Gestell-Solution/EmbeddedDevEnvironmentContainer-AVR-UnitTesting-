# 🚀 Developer Guide: How to Use the Build Environment

Welcome to your new firmware workspace! This guide is designed to get you writing and
compiling code as quickly as possible.

The beauty of this architecture is that **you do not need to understand Docker, Nginx, or
complex GCC toolchains** to use it. The heavy lifting is handled by the
`ProjectDeployment` engine running in the background. Your only focus is writing great C
code inside the `Firmware` folder.

---

## 🛑 1. The Golden Rule: What to Ignore
To keep your workflow simple, **completely ignore the `ProjectDeployment` directory.**
That folder contains the server architecture, reverse proxies, and proprietary build engines.
Unless you are the DevOps engineer maintaining the build infrastructure, modifying files in
that directory will break your compilation pipeline.

**Your entire workflow takes place inside the `Firmware/` directory.**

---

## ✍️ 2. Writing Your Application Code (`src/`)
All of your actual application logic, drivers, and headers belong inside the `Firmware/src/`
directory.

* **Nested Folders are Fine:** You can organize your code however you like. If you want to
create `src/drivers/i2c/` or `src/utils/`, the build engine will automatically find and compile
them.
* **The `main.c` Rule:** You must have exactly one file that contains your primary `main()`
function, and it is highly recommended to name it `main.c` or place it at the root of the `src/`
directory.

---

## 🧪 3. Writing Unit Tests (`test/`)
Testing embedded C code can be painful, but this system makes it completely automatic
using the Unity Test Framework. All testing materials go into the `Firmware/test/` directory.

* **The `test_` Prefix:** For the engine to recognize a file as a standalone unit test, the file
name **must** start with `test_` (e.g., `test_blinky.c`, `test_sensor_math.c`).
* **Isolated Compilation:** Every `test_*.c` file is compiled into its own, independent
executable. This means **every test file must have its own `main()` function** to run the
Unity macros.
* **The Unity Folder:** Do not delete the `test/unity/` folder. The engine needs `unity.c` and
`unity.h` to successfully build your tests.

---

## 🏭 4. Compiling Your Project
When you are ready to compile your firmware or check if your tests pass, open your
terminal inside the `Firmware/` directory and run the deployment script:

* **Windows:** `.\CompilingYourProject.ps1`
* **Linux/macOS:** `./CompilingYourProject.sh`

**The Build Wizard:**
If you haven't compiled this project before, the script will ask you a few questions:

1. Are you building standard `c` or embedded `avr`?
2. What is your target MCU? (e.g., `atmega328p`)
3. What is your clock speed? (e.g., `16M`, `8MHz`, `500K`)

It saves your answers to a `build_config.json` file. Future builds will use those settings
automatically. If you ever need to change your chip or clock speed, simply delete
`build_config.json` and run the script again.

---

## 📦 5. Retrieving Your Binaries
Once the compilation finishes, the script will download a **`results.zip`** file directly into
your `Firmware/` folder.

Unzip it to find your artifacts:
1. **`buildLog.txt`:** Always check this first! It contains the exact compiler output, showing
you exactly where any syntax errors or warnings occurred.
2. **`main.hex`:** (AVR Only) Your final, optimized firmware. Use a tool like `avrdude` to
flash this directly to your microcontroller.
3. **`test_*.out`:** Your compiled unit tests. You can run these directly on your computer's
terminal (e.g., `./test_blinky.out` on Linux or `.\test_blinky.out.exe` on Windows) to verify
your logic works before flashing!