#!/usr/bin/env python3
"""
Hyprland IPC Compatibility Bridge for Lua Configurations.
Transparently proxies Hyprland's socket1, translating legacy dispatch
commands (like 'dispatch workspace <id>') into Lua-compatible
'dispatch hl.dsp.focus({ workspace = "<id>" })' calls.
"""

import os
import sys
import time
import socket
import signal
import threading

def get_real_paths():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    real_sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not real_sig:
        hypr_base = os.path.join(runtime_dir, "hypr")
        if os.path.isdir(hypr_base):
            instances = [
                d for d in os.listdir(hypr_base)
                if d != "compat" and os.path.exists(os.path.join(hypr_base, d, ".socket.sock"))
            ]
            if instances:
                instances.sort(key=lambda d: os.path.getmtime(os.path.join(hypr_base, d, ".socket.sock")), reverse=True)
                real_sig = instances[0]
    if not real_sig:
        sys.stderr.write("Error: Could not locate real HYPRLAND_INSTANCE_SIGNATURE\n")
        sys.exit(1)

    real_dir = os.path.join(runtime_dir, "hypr", real_sig)
    compat_dir = os.path.join(runtime_dir, "hypr", "compat")
    return real_dir, compat_dir

def translate_single(cmd_str):
    cmd_str = cmd_str.strip()
    if not cmd_str.startswith("dispatch "):
        return cmd_str

    rest = cmd_str[len("dispatch "):].strip()
    if rest.startswith("hl."):
        return cmd_str

    parts = rest.split(maxsplit=1)
    dispatcher = parts[0]
    arg = parts[1].strip() if len(parts) > 1 else ""

    # Workspace focusing (What Waybar calls on click!)
    if dispatcher in ("workspace", "focusworkspaceoncurrentmonitor"):
        arg_esc = arg.replace("\\", "\\\\").replace('"', '\\"')
        return f'dispatch hl.dsp.focus({{ workspace = "{arg_esc}" }})'

    if dispatcher == "togglespecialworkspace":
        if arg:
            arg_esc = arg.replace("\\", "\\\\").replace('"', '\\"')
            return f'dispatch hl.dsp.workspace.toggle_special("{arg_esc}")'
        return 'dispatch hl.dsp.workspace.toggle_special()'

    if dispatcher in ("movetoworkspace", "movetoworkspacesilent"):
        arg_esc = arg.replace("\\", "\\\\").replace('"', '\\"')
        silent = ", silent = true" if "silent" in dispatcher else ""
        return f'dispatch hl.dsp.window.move({{ workspace = "{arg_esc}"{silent} }})'

    if dispatcher == "exec":
        arg_esc = arg.replace("\\", "\\\\").replace('"', '\\"')
        return f'dispatch hl.dsp.exec_cmd("{arg_esc}")'

    if dispatcher in ("killactive", "closewindow"):
        return 'dispatch hl.dsp.window.close()'

    if dispatcher.isdigit():
        return f'dispatch hl.dsp.focus({{ workspace = "{dispatcher}" }})'

    return cmd_str

def translate_command(text):
    if text.startswith("[[BATCH]]"):
        parts = text[len("[[BATCH]]"):].split(";")
        new_parts = [translate_single(p) for p in parts]
        return "[[BATCH]]" + ";".join(new_parts)
    return translate_single(text)

def log(msg):
    try:
        with open("/tmp/hypr-bridge.log", "a") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
            f.flush()
    except Exception:
        pass

def handle_client(client, real_sock_path):
    try:
        data = client.recv(8192)
        if not data:
            return
        text = data.decode("utf-8", errors="ignore")
        translated = translate_command(text)
        if translated != text:
            log(f"Translated: {repr(text)} -> {repr(translated)}")
            data = translated.encode("utf-8")

        real = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        real.connect(real_sock_path)
        real.sendall(data)

        resp = b""
        while True:
            chunk = real.recv(8192)
            if not chunk:
                break
            resp += chunk
        real.close()
        client.sendall(resp)
    except Exception as e:
        log(f"Bridge error: {e}")
    finally:
        try:
            client.close()
        except Exception:
            pass

def main():
    real_dir, compat_dir = get_real_paths()
    real_sock = os.path.join(real_dir, ".socket.sock")
    real_sock2 = os.path.join(real_dir, ".socket2.sock")

    os.makedirs(compat_dir, exist_ok=True)
    compat_sock = os.path.join(compat_dir, ".socket.sock")
    compat_sock2 = os.path.join(compat_dir, ".socket2.sock")

    # Maintain event socket symlink
    if os.path.lexists(compat_sock2):
        os.remove(compat_sock2)
    os.symlink(real_sock2, compat_sock2)

    # Clean existing command socket
    if os.path.lexists(compat_sock):
        os.remove(compat_sock)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(compat_sock)
    server.listen(64)
    log(f"Bridge initialized on {compat_sock} forwarding to {real_sock}")

    def cleanup(*args):
        try:
            server.close()
            if os.path.lexists(compat_sock):
                os.remove(compat_sock)
            if os.path.lexists(compat_sock2):
                os.remove(compat_sock2)
        except Exception:
            pass
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    while True:
        try:
            client, _ = server.accept()
            threading.Thread(target=handle_client, args=(client, real_sock), daemon=True).start()
        except Exception:
            break

if __name__ == "__main__":
    main()
