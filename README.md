# 🏭 Containerized C & AVR Build Factory

A robust, isolated Docker compilation engine designed to automatically build, test, and package standard C and embedded AVR microcontrollers (like the ATmega328p) via a simple REST API.

## 🌟 Features
* **Isolated Environment:** No need to install heavy GCC or AVR toolchains on host machines. Everything runs inside a lightweight Ubuntu Docker container.
* **Smart Configuration:** An interactive CLI wizard generates a configuration file, allowing custom MCUs, human-readable CPU frequencies (e.g., `16M`, `8MHz`), and custom compiler flags.
* **Automated Unit Testing:** Automatically detects and compiles Unity-based unit tests alongside your main application code.
* **Nginx Reverse Proxy:** Safely handles large file uploads and long compilation timeouts.
* **Pristine Logging:** Always returns a detailed `buildLog.txt` with exact `stdout` and `stderr` streams so you know exactly why a build succeeded or failed.
* **Cross-Platform Clients:** Deployment scripts provided for Windows (PowerShell) and Linux/macOS (Bash/pwsh).

---

## 🏗️ System Architecture
1. **Client (Deployment Script):** Packages the local code into a zip file, prompts the user for build parameters (MCU, frequency), and sends both to the server via an HTTP POST request.
2. **Nginx Proxy (Port 80):** Receives the request, handles the file upload, and passes it to the internal Flask application.
3. **Flask App (app.py):** Unzips the code, parses the JSON config, routes the files to the appropriate compilers (`avr-gcc` or `gcc`), and runs the unit tests.
4. **Results:** Packages the compiled binaries (`.hex`, `.elf`, `.out`) and `buildLog.txt` into a `results.zip` and returns it instantly to the client.

---

## 🚀 Server Setup (Docker)

To start the factory, ensure you are in the directory called ContainerApp that has the next files , or  ensure you have the following files in a directory on your host machine:
* `Dockerfile`
* `nginx.conf`
* `app.py`
* `start.sh`

Open your terminal in that directory and run:

```bash
# 1. Build the Docker Image
docker build -t avr-factory .

# 2. Run the Container in Detached Mode (Mapping Port 8050 to internal Port 80)
docker run -d -p 8050:80 --name running-avr-factory avr-factory
```
*To stop the server later: `docker stop running-avr-factory`*

---

## 📁 Required Project Structure
For the build engine to correctly categorize and compile your files, your C/AVR projects **must** follow this folder structure:

```text
MyAwesomeProject/
├── src/                  <-- Main source code goes here
│   ├── main.c            (Must contain your main loop/logic)
│   ├── blinky.c
│   └── blinky.h
├── test/                 <-- Unit test files go here
│   └── test_blinky.c     (Must start with "test_" and have its own main() function)
├── unity/                <-- Unity testing framework files
│   ├── unity.c
│   └── unity.h
└── deploy.ps1            <-- Your deployment script
```

---

## 🛠️ How to Deploy & Build

Once your code is written and structured correctly, open your terminal inside your project folder (e.g., `MyAwesomeProject/`).

**For Windows (PowerShell):**
```powershell
.\deploy.ps1
```

**For Linux/macOS (Bash):**
```bash
./deploy.sh
```

### The Interactive Wizard
If it is your first time compiling a project, the script will trigger an interactive wizard:
1. **Target Type:** Choose `c` (Standard GCC) or `avr` (Embedded).
2. **MCU:** (AVR only) Enter your chip (e.g., `atmega328p`).
3. **CPU Frequency:** (AVR only) You can use friendly formats like `16M`, `8MHz`, or `500K`.
4. **Extra Flags:** Enter any specific GCC flags (e.g., `-Werror`). *Note: `-g`, `-Wall`, `-Wextra`, and `-Os` are applied automatically to all builds.*

This generates a `build_config.json` file. Future builds will skip the wizard and use this file automatically. To change settings, simply delete `build_config.json` and run the script again.

---

## 📦 Understanding Your Results

After a successful (or failed) deployment, the script will download **`results.zip`** into your project folder. Unzip it to find:

* **`buildLog.txt`:** Start here! This contains the exact commands run by the server and any syntax errors or warnings your code produced.
* **`main.hex`:** (AVR Only) The final firmware file ready to be flashed to your microcontroller using tools like `avrdude`.
* **`main.elf` / `main.map`:** Debugging and memory mapping files.
* **`test_*.out`:** Your compiled unit tests. Run these executables on your local machine to see if your code passes its tests!

***