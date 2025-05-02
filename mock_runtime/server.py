#!/usr/bin/env python3
"""
Mock ICN Runtime Server for AgoraNet testing.
This simple server provides endpoints that simulate the ICN Runtime API.
"""

import json
import http.server
import socketserver
import os
from urllib.parse import urlparse, parse_qs

PORT = 3000
EVENTS_FILE = os.path.join(os.path.dirname(__file__), "events.json")

class RuntimeHandler(http.server.BaseHTTPRequestHandler):
    def _set_headers(self, content_type='application/json'):
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        
    def do_OPTIONS(self):
        self._set_headers()
        
    def do_GET(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        if path == '/api/events':
            self._handle_events()
        elif path == '/api/health':
            self._handle_health()
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Not found"}).encode())
    
    def _handle_events(self):
        self._set_headers()
        try:
            with open(EVENTS_FILE, 'r') as file:
                events = json.load(file)
                self.wfile.write(json.dumps(events).encode())
        except Exception as e:
            self.wfile.write(json.dumps({"error": str(e)}).encode())
    
    def _handle_health(self):
        self._set_headers()
        self.wfile.write(json.dumps({"status": "healthy"}).encode())
    
    def log_message(self, format, *args):
        # Custom logging
        print(f"[Mock Runtime] {self.address_string()} - {format % args}")

def run_server():
    with socketserver.TCPServer(("", PORT), RuntimeHandler) as httpd:
        print(f"Mock ICN Runtime server running at http://localhost:{PORT}")
        print(f"Available endpoints:")
        print(f"  - GET /api/events - Returns mock runtime events")
        print(f"  - GET /api/health - Health check endpoint")
        httpd.serve_forever()

if __name__ == "__main__":
    print(f"Starting Mock ICN Runtime server on port {PORT}...")
    run_server() 