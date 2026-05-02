# ==================================================================================================================
# Application file name :  app.py
# Description:  App file that routes the requests and builds the Files given 
#               based on the requested Building method -> if AVR or Just C Programming Code
#
#
# Author:       MohammedDiaa (mohammeddiaato@gmail.com)
# Company:      Gestell - Professional Embedded Solutions
# ==================================================================================================================
from flask import Flask, request, send_file
import os
import subprocess
import shutil
import zipfile
import json
import shlex

app = Flask(__name__)
WORKSPACE = "/app/workspace"

def get_unique_filename(base_name, destination_folder):
    """Ensures test outputs don't overwrite each other."""
    current_name = f"{base_name}.out"
    counter = 1
    while os.path.exists(os.path.join(destination_folder, current_name)):
        current_name = f"{base_name}_{counter}.out"
        counter += 1
    return current_name

@app.route('/run', methods=['POST'])
def run_project():
    # ==========================================
    # 1. Parse JSON Configuration
    # ==========================================
    config_data = {}
    if 'config' in request.files:
        try:
            config_file = request.files['config']
            config_data = json.load(config_file)
        except Exception as e:
            return f"Error reading config JSON: {str(e)}", 400

    build_type = config_data.get('build_type', 'c').lower()
    mcu = config_data.get('mcu', 'atmega328p')
    cpu_freq = config_data.get('cpu_freq', '16000000')
    extra_flags_str = config_data.get('extra_flags', '')
    extra_flags = shlex.split(extra_flags_str)

    # ==========================================
    # 2. File Validation & Setup
    # ==========================================
    if 'file' not in request.files:
        return "Error: No file uploaded", 400

    uploaded_file = request.files['file']
    if uploaded_file.filename == '':
        return "Error: No selected file", 400

    if os.path.exists(WORKSPACE):
        shutil.rmtree(WORKSPACE)
    
    extract_dir = os.path.join(WORKSPACE, "extracted")
    results_dir = os.path.join(WORKSPACE, "results")
    os.makedirs(extract_dir, exist_ok=True)
    os.makedirs(results_dir, exist_ok=True)

    zip_path = os.path.join(WORKSPACE, "project_upload.zip")
    uploaded_file.save(zip_path)

    # --- Initialize Build Log ---
    log_path = os.path.join(results_dir, "buildLog.txt")
    with open(log_path, 'w') as f:
        f.write("=== FACTORY BUILD LOG ===\n")
        f.write(f"Target: {build_type.upper()} | MCU: {mcu} | Freq: {cpu_freq}Hz\n")
        f.write("=========================\n\n")

    def run_step(cmd, step_name):
        """Runs a command, logs output to buildLog.txt, and returns True if successful."""
        process = subprocess.run(cmd, capture_output=True, text=True)
        with open(log_path, 'a') as f:
            f.write(f"[{step_name}]\n")
            f.write(f"Command: {' '.join(cmd)}\n")
            f.write(f"Exit Code: {process.returncode}\n")
            if process.stdout.strip():
                f.write(f"STDOUT:\n{process.stdout.strip()}\n")
            if process.stderr.strip():
                f.write(f"STDERR:\n{process.stderr.strip()}\n")
            f.write("-" * 50 + "\n\n")
        return process.returncode == 0

    try:
        # ==========================================
        # 3. Extract and Categorize (UPDATED)
        # ==========================================
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_dir)

        src_files, unity_files, test_files = [], [], []
        include_dirs = set()

        for root, dirs, files in os.walk(extract_dir):
            # Convert path to lowercase to safely match Src/, src/, Test/, etc.
            path_parts = [p.lower() for p in root.split(os.sep)]
            
            for file in files:
                file_path = os.path.join(root, file)
                
                # A. Process files inside the 'src' directory
                if 'src' in path_parts:
                    if file.endswith('.c'): 
                        src_files.append(file_path)
                    elif file.endswith('.h'): 
                        include_dirs.add(root)
                        
                # B. Process files inside the 'test' directory
                elif 'test' in path_parts:
                    # Look for unity specifically nested inside test/
                    if 'unity' in path_parts:
                        if file.endswith('.c'): 
                            unity_files.append(file_path)
                        elif file.endswith('.h'): 
                            include_dirs.add(root)
                    # Otherwise, it is standard test code
                    else:
                        if file.lower().startswith('test_') and file.endswith('.c'):
                            test_files.append(file_path)
                        elif file.endswith('.h'):
                            include_dirs.add(root) # Ensure test header folders are included

        include_flags = [f"-I{d}" for d in include_dirs]
        test_src_files = [f for f in src_files if not f.lower().endswith('main.c')]
        
        base_gcc_flags = ["-g", "-Wall", "-Wextra", "-Os"] + extra_flags + include_flags
        
        main_build_success = True

        # ==========================================
        # 4A. AVR Compilation Phase
        # ==========================================
        if build_type == 'avr':
            if src_files:
                elf_path = os.path.join(results_dir, "main.elf")
                map_path = os.path.join(results_dir, "main.map")
                hex_path = os.path.join(results_dir, "main.hex")

                avr_specific_flags = [f"-mmcu={mcu}", f"-DF_CPU={cpu_freq}UL"]
                avr_cmd = ["avr-gcc"] + base_gcc_flags + avr_specific_flags + src_files + ["-o", elf_path, f"-Wl,-Map={map_path}"]
                
                if run_step(avr_cmd, "AVR Main Compilation"):
                    hex_cmd = ["avr-objcopy", "-O", "ihex", "-R", ".eeprom", elf_path, hex_path]
                    run_step(hex_cmd, "AVR Hex Generation")
                else:
                    main_build_success = False

        # ==========================================
        # 4B. Standard C Compilation Phase
        # ==========================================
        else:
            if src_files:
                main_out_path = os.path.join(results_dir, "main.out")
                gcc_cmd = ["gcc"] + base_gcc_flags + src_files + ["-o", main_out_path]
                
                if not run_step(gcc_cmd, "Standard C Main Compilation"):
                    main_build_success = False

        # ==========================================
        # 5. Unit Test Compilation Phase
        # ==========================================
        if main_build_success:
            for test_file in test_files:
                base_name = os.path.splitext(os.path.basename(test_file))[0]
                out_filename = get_unique_filename(base_name, results_dir)
                out_filepath = os.path.join(results_dir, out_filename)

                test_cmd = ["gcc"] + base_gcc_flags + [test_file] + unity_files + test_src_files + ["-o", out_filepath]
                run_step(test_cmd, f"Unit Test Compilation: {base_name}")
        else:
            with open(log_path, 'a') as f:
                f.write("[Unit Tests Skipped]\nReason: Main compilation failed.\n")

        # ==========================================
        # 6. Package and Cleanup
        # ==========================================
        result_zip_path = os.path.join(WORKSPACE, "build_results.zip")
        with zipfile.ZipFile(result_zip_path, 'w') as zipf:
            for root, _, files in os.walk(results_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, results_dir)
                    zipf.write(file_path, arcname)

        return send_file(
            result_zip_path,
            mimetype='application/zip',
            as_attachment=True,
            download_name="results.zip"
        )

    except Exception as e:
        with open(log_path, 'a') as f:
            f.write(f"\n[SYSTEM FATAL ERROR]\n{str(e)}\n")
        
        result_zip_path = os.path.join(WORKSPACE, "crash_results.zip")
        with zipfile.ZipFile(result_zip_path, 'w') as zipf:
            zipf.write(log_path, os.path.basename(log_path))
            
        return send_file(
            result_zip_path,
            mimetype='application/zip',
            as_attachment=True,
            download_name="crash_results.zip"
        )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
# ==================================================================================================================
# Application file name :  app.py
# Description:  App file that routes the requests and builds the Files given 
#               based on the requested Building method -> if AVR or Just C Programming Code
#
#
# Author:       MohammedDiaa (mohammeddiaato@gmail.com)
# Company:      Gestell - Professional Embedded Solutions
# ==================================================================================================================