Complete User Guide: Setup,
Deployment, and Best Practices
(Updated)
Here is the updated HowToUseForYourProject.md file. I have added a brand new Phase 0:
Prerequisites section at the very beginning to ensure the user actually has Docker installed
before they try to run any commands.

# 🚀 Complete User Guide: Setup, Deployment, and Best Practices

Welcome to the AVR & C Containerized Build Factory. This guide will walk you step-by-step
through installing the necessary tools, deploying the Docker engine, adapting your own
specific project into the workspace, and running your first successful build.

---

## Phase 0: Prerequisites (Install Docker)
Before you can use this build environment, your host machine must have Docker installed.
This is the engine that runs the isolated compilation factory.

* **Windows / macOS:** Download and install [Docker
Desktop](https://www.docker.com/products/docker-desktop/). Ensure it is running in the
background (you should see the whale icon in your system tray).
* **Linux:** Install [Docker Engine](https://docs.docker.com/engine/install/) via your
package manager (e.g., `sudo apt install docker.io`). Ensure the daemon is running.

*Note: You do not need to install GCC, AVR-GCC, or Nginx on your computer. Docker
handles all of that internally!*

---

## Phase 1: Deploying the Docker Container (One-Time Setup)
With Docker running on your machine, you must now build and start the factory server. You
only need to do this once per machine (or after a reboot).

**Step 1:** Open your terminal and navigate to the Docker directory:
```bash
cd ProjectDeployment/ContainerApp
```

**Step 2:** Build the Docker image (this downloads the GCC toolchains):
```bash
docker build -t avr-factory .
```

**Step 3:** Start the container in detached mode:
```bash
docker run -d -p 8050:80 --name running-avr-factory avr-factory
```
*The factory is now online and waiting for your code!*

---

## Phase 2: Adapting Your Own Specific Project
Now that the server is running, you need to place your project files into the `Firmware/`
folder so the deployment scripts can find them.

**Step 1:** Navigate to the `Firmware/` directory.
**Step 2:** Place your application logic inside `Firmware/src/`.
* You **must** have a file containing your primary `main()` function (usually `main.c`).
* You can create as many sub-folders as you need (e.g., `src/drivers/`, `src/utils/`). The
engine will find them automatically.
**Step 3:** Place your testing logic inside `Firmware/test/`.
* Every test file **must** begin with `test_` (e.g., `test_sensors.c`).

* Ensure the `test/unity/` folder remains intact, as your tests require it to compile.

---

## Phase 3: Compiling Your Project (Step-by-Step)
Once your code is in place, you are ready to send it to the Docker factory.

**Step 1:** Open a terminal inside the `Firmware/` directory.
**Step 2:** Execute the deployment script:
* **Windows:** `.\CompilingYourProject.ps1`
* **Linux/macOS:** `./CompilingYourProject.sh`
**Step 3:** Answer the interactive Build Wizard prompts:
* *Type:* Enter `c` or `avr`.
* *MCU:* Enter your microcontroller (e.g., `atmega328p`).
* *Frequency:* Enter your clock speed (e.g., `16M`, `8MHz`).
**Step 4:** Wait a few seconds for the factory to compile your code. You will receive a
green "Success!" message.
**Step 5:** Unzip the newly downloaded `results.zip` file in your directory to access your
`main.hex` firmware, `test_*.out` executables, and the `buildLog.txt`.

---

## ⚠️ Phase 4: Critical Best Practices & Size Warnings

To compile your code, the deployment script zips the entire `Firmware/` folder and sends it
to the Docker container over a local HTTP connection. Because of this, **you must be
highly protective of what files you put inside the Firmware folder.**
### ❌ Do NOT include the following in the Firmware/ directory:
1. **PDFs and Datasheets:** Keep your microcontroller reference manuals and project
documentation in a completely separate folder outside of `Firmware/`.
2. **CAD Files & Schematics:** Altium, KiCad, or Eagle files should never be in the
compilation path.

3. **Heavy Media:** Images, videos, or UI assets that are not compiled directly into
memory.
4. **Previous Build Artifacts:** Do not manually upload old `.hex`, `.out`, or `.elf` files.

### Why is this important?
If you place a 50MB PDF datasheet inside the `src/` folder, the deployment script will zip it
and send it to the Docker container every single time you press compile.
* It will drastically slow down your compilation time.
* It inflates network traffic.
* It can cause the Nginx proxy to throw an `Error 413 (Payload Too Large)` or a timeout
error, completely breaking your build pipeline.

**Keep your `Firmware/` folder strictly for `.c` files, `.h` files, and lightweight
configurations!**