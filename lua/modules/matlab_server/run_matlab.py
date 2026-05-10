import socket
import os
import sys
import subprocess
import time
import tempfile

SOCKET_PATH = f"/tmp/matlab_engine_{os.getlogin()}.sock"


def run_client(file_path):
    if not os.path.exists(SOCKET_PATH):
        # Start server in the background
        server_script = os.path.join(
            os.path.dirname(__file__), "matlab_server.py"
        )

        # We'll use a temporary file to capture server startup errors
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp_name = tmp.name

        try:
            with open(tmp_name, "w") as f:
                proc = subprocess.Popen(
                    [sys.executable, server_script],
                    stdout=f,
                    stderr=f,
                    preexec_fn=os.setpgrp,
                )

            print("Starting MATLAB Engine Server (this may take a while)...")
            # Wait for server to start
            max_retries = 60
            server_started = False
            for i in range(max_retries):
                if os.path.exists(SOCKET_PATH):
                    time.sleep(0.5)
                    server_started = True
                    break
                # Check if process died
                if proc.poll() is not None:
                    break
                time.sleep(1)

            if not server_started:
                print("Failed to start MATLAB server.")
                with open(tmp_name, "r") as f:
                    print(f.read())
                sys.exit(1)
        finally:
            if os.path.exists(tmp_name):
                os.remove(tmp_name)

    # Connect and send
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(SOCKET_PATH)
        client.sendall(os.path.abspath(file_path).encode("utf-8"))

        while True:
            chunk = client.recv(4096)
            if not chunk:
                break
            sys.stdout.write(chunk.decode("utf-8"))
            sys.stdout.flush()
        client.close()
    except Exception as e:
        print(f"\nCommunication error: {e}")
        if os.path.exists(SOCKET_PATH):
            try:
                os.remove(SOCKET_PATH)
            except:
                pass
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python run_matlab.py <file_path.m>")
        sys.exit(1)

    run_client(sys.argv[1])
