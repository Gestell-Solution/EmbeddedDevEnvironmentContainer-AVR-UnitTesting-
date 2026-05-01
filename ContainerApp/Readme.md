# ⚙️ ContainerApp: The Build Engine

This directory contains the core server architecture for the AVR/C Compilation Factory. It is responsible for receiving project files, routing them through the appropriate GCC toolchains, and returning the compiled binaries and logs.

### ⚠️ Important Notice on Modifications
This environment has been precisely configured to handle complex build pipelines, file extractions, and reverse proxy timeouts. 
**Any additions, modifications, or custom package installations added to this directory or the Dockerfile are solely the responsibility of the user.** If you alter the Python logic or Nginx routing, you must manage your own debugging and error handling.

---

## 🛑 Execution Rule: Directory Context
**You MUST be inside this exact directory (`ContainerApp`) when building the Docker image.** Docker requires the `Dockerfile` and all its associated files to be in the current working directory (the "build context"). If you try to run the build command from the parent folder, it will fail.

**Correct Usage:**
```bash
# 1. Navigate into this folder
cd ContainerApp

# 2. Build the image (Do not forget the '.' at the end!)
docker build -t avr-factory .

# 3. Run the container
docker run -d -p 8050:80 --name running-avr-factory avr-factory
```

---

## 📁 File Manifest

Here is exactly what each file in this directory does to keep the factory running:

* **`app.py`**
    The core Flask application. It acts as the brain of the container—receiving the ZIP uploads, parsing your `build_config.json`, running the actual `avr-gcc` and `gcc` compilation commands, and packaging the results back together.

* **`Dockerfile`**
    The blueprint for the container. It downloads the Ubuntu base image, installs all the necessary C and AVR toolchains (`gcc-avr`, `binutils-avr`, `avr-libc`), sets up the Python virtual environment, and copies these configuration files inside.

* **`nginx.conf`**
    The reverse proxy configuration. Nginx sits in front of the Flask app to safely manage large ZIP file uploads (up to 200MB) and prevent connection timeouts when complex projects take several seconds to compile.

* **`Runner.sh`**
    The entrypoint shell script. When the container boots, Docker runs this script to start Nginx in the background and then launch the Python application in the foreground, keeping the container alive and stable.

* **`build.log`**
    A local log file used to capture the standard output and standard error streams from the compilers during the build process.

* **`Readme.md`**
    This documentation file.