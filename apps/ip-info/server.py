#!/usr/bin/env python3
"""Simple HTTP server that returns local and Tailscale IP addresses."""

import http.server
import json
import socket
import subprocess


def get_local_ip():
    """Get the primary local IP address."""
    try:
        # Connect to external address to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "unavailable"


def get_tailscale_ip():
    """Get the Tailscale IP address."""
    try:
        result = subprocess.run(
            ["ip", "-4", "addr", "show", "tailscale0"],
            capture_output=True,
            text=True,
            timeout=5
        )
        for line in result.stdout.split("\n"):
            if "inet " in line:
                # Extract IP from "inet 100.x.x.x/32" format
                return line.strip().split()[1].split("/")[0]
    except Exception:
        pass
    return "unavailable"


class IPHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        data = {
            "local_ip": get_local_ip(),
            "tailscale_ip": get_tailscale_ip()
        }
        response = json.dumps(data)

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(response))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(response.encode())

    def log_message(self, format, *args):
        # Suppress access logs
        pass


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", 3099), IPHandler)
    print("IP Info server running on port 3099")
    server.serve_forever()
