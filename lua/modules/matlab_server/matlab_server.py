import os
import sys
import socket
import io
import time
import traceback

# Ensure we can import matlab.engine
try:
    import matlab.engine
except ImportError:
    print("Error: matlab.engine not found in this Python environment.")
    sys.exit(1)

SOCKET_PATH = f"/tmp/matlab_engine_{os.getlogin()}.sock"

def start_server():
    if os.path.exists(SOCKET_PATH):
        try:
            # Check if another server is already listening
            test_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            test_sock.connect(SOCKET_PATH)
            test_sock.close()
            print("Server already running.")
            return
        except socket.error:
            os.remove(SOCKET_PATH)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen(5)
    
    print("MATLAB Engine Server: Initializing engine...")
    eng = None
    try:
        engines = matlab.engine.find_matlab()
        if engines:
            print(f"Connecting to shared engine: {engines[0]}")
            eng = matlab.engine.connect_matlab(engines[0])
        else:
            print("Starting new MATLAB engine...")
            eng = matlab.engine.start_matlab()
        print("MATLAB Engine Server: Ready.")
    except Exception as e:
        print(f"Failed to start MATLAB engine: {e}")
        if os.path.exists(SOCKET_PATH):
            os.remove(SOCKET_PATH)
        return

    while True:
        conn, _ = server.accept()
        try:
            data = conn.recv(4096).decode('utf-8')
            if not data:
                continue
            
            file_path = data.strip()
            if file_path == "__EXIT__":
                break
            
            if not os.path.exists(file_path):
                conn.sendall(f"Error: File '{file_path}' not found.\n".encode('utf-8'))
                conn.close()
                continue

            abs_path = os.path.abspath(file_path)
            folder = os.path.dirname(abs_path)
            script_name = os.path.splitext(os.path.basename(abs_path))[0]
            
            # Send an acknowledgement
            conn.sendall(f"--- Running '{script_name}' ---\n".encode('utf-8'))
            
            # Change directory
            eng.cd(folder, nargout=0)
            
            # MATLAB strictly requires io.StringIO for capturing stdout/stderr
            out_stream = io.StringIO()
            err_stream = io.StringIO()
            
            # Execute
            try:
                eng.eval(script_name, nargout=0, stdout=out_stream, stderr=err_stream)
                
                # Retrieve the captured output
                stdout_val = out_stream.getvalue()
                stderr_val = err_stream.getvalue()
                
                if stdout_val:
                    conn.sendall(stdout_val.encode('utf-8'))
                if stderr_val:
                    conn.sendall(stderr_val.encode('utf-8'))
                    
            except Exception as eval_err:
                # Capture MATLAB evaluation errors specifically
                stdout_val = out_stream.getvalue()
                stderr_val = err_stream.getvalue()
                
                if stdout_val:
                    conn.sendall(stdout_val.encode('utf-8'))
                if stderr_val:
                    conn.sendall(stderr_val.encode('utf-8'))
                
                conn.sendall(f"\nMATLAB Error: {eval_err}\n".encode('utf-8'))
            finally:
                out_stream.close()
                err_stream.close()
            
            conn.sendall("\n--- Finished ---\n".encode('utf-8'))
        except Exception as e:
            error_msg = f"\nAn error occurred during execution:\n{traceback.format_exc()}\n"
            try:
                conn.sendall(error_msg.encode('utf-8'))
            except:
                pass
        finally:
            try:
                conn.close()
            except:
                pass

    if os.path.exists(SOCKET_PATH):
        os.remove(SOCKET_PATH)

if __name__ == "__main__":
    start_server()
