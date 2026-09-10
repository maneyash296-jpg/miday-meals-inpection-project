"""
NutriGuard AI — Dual-Stack Server Launcher
Binds to IPv6 '::' with IPV6_V6ONLY=0 so that:
  - http://localhost:8000
  - http://127.0.0.1:8000
  - http://[::1]:8000
  - LAN IP:8000
all work seamlessly on Windows without connection refused errors.
"""
import socket
import sys
import uvicorn
from app.main import app

def main():
    port = 8000
    print(f"[*] NutriGuard AI Server listening on 0.0.0.0:{port} (All network interfaces)...")
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")

if __name__ == "__main__":
    main()
