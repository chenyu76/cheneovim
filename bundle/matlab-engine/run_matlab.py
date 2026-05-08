"""
MATLAB Execution Wrapper
------------------------
This script executes a specified MATLAB (.m) file using one of two methods:
1. Shared Engine: It searches for an already running MATLAB instance (shared).
   If found, it connects to it and runs the script, avoiding startup overhead.
2. Batch Mode: If no running instance is detected, it launches a new MATLAB
   process in -batch mode to execute the file and then exits.

Usage: python run_matlab.py <path_to_matlab_file>

NOTE:
To make a MATLAB instance detectable, run 'matlab.engine.shareEngine'
inside MATLAB first.

If using the line below, a new MATLAB instance would be started each time,
which is very time-consuming
> matlab -batch "code"

MATLAB Engine for my 2023b MATLAB only supports up to Python 3.11
> yay -S python311
Then in the directory:
> python3.11 -m venv ./venv
> ./venv/bin/pip install '/path/to/MATLAB/R2023b/extern/engines/python'

This path can be obtained by executing
> fullfile(matlabroot,"extern","engines","python") in MATLAB

Note: On some Linux systems (e.g., Arch),
the libCppMicroServices library requires an executable stack,
which is disabled by default and may cause OSError. Fix:
> rm ./venv/bin/python3.11 && cp /usr/bin/python3.11 ./venv/bin/python3.11
> patchelf --set-execstack ./venv/bin/python3.11
"""

import sys
import os
import subprocess
import matlab.engine


def run_script(file_path):

    # Validate file existence
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)

    # Prepare pathing and script name
    abs_path = os.path.abspath(file_path)
    folder = os.path.dirname(abs_path)
    # Remove .m extension for MATLAB execution
    script_name = os.path.splitext(os.path.basename(abs_path))[0]

    try:
        # Search for shared MATLAB engines
        print("Searching for available MATLAB engines...")
        engines = matlab.engine.find_matlab()

        if engines:
            # Method 1: Connect to existing engine
            engine_name = engines[0]
            eng = matlab.engine.connect_matlab(engine_name)

            # Navigate to the script's directory and run
            eng.cd(folder, nargout=0)
            print(
                f"Running '{script_name}' in shared engine '{engine_name}'..."
            )
            eng.eval(script_name, nargout=0)

        else:
            # Method 2: Fallback to Batch Mode
            print("No active engines found. Starting MATLAB in batch mode...")
            # Use 'run' command to handle the specific file path
            cmd = ["matlab", "-batch", f"run('{abs_path}')"]

            # Execute via subprocess
            subprocess.run(cmd, check=True)

    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    # Check if file path is provided via CLI arguments
    if len(sys.argv) < 2:
        print("Usage: python run_matlab.py <file_path.m>")
        sys.exit(1)

    run_script(sys.argv[1])
