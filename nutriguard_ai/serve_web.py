import http.server
import socket
import socketserver
import os

class DualStackServer(socketserver.TCPServer):
    address_family = socket.AF_INET6
    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        super().server_bind()

web_dir = r"c:\Users\YASH MANE\OneDrive\Desktop\SIH\SIH\nutriguard_ai\build\web"
os.chdir(web_dir)
handler = http.server.SimpleHTTPRequestHandler
port = 3000

with DualStackServer(('::', port), handler) as httpd:
    print(f"[*] Serving Flutter Web on port {port} (IPv4 + IPv6 / localhost)...")
    httpd.serve_forever()
