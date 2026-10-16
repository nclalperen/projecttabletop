#!/usr/bin/env python3
"""
Simple local preview HTTP server for Godot 4.6/4.7 HTML5/WebAssembly exports.
Provides required Cross-Origin Isolation headers (COOP / COEP), cache-busting,
and correct MIME types for .wasm and .pck files.
"""

import argparse
import os
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

class GodotWebPreviewHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Cross-Origin Isolation headers required for SharedArrayBuffer / multi-threaded WebAssembly
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        # Prevent aggressive browser caching during development iterations
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def guess_type(self, path):
        if path.endswith(".wasm"):
            return "application/wasm"
        if path.endswith(".pck"):
            return "application/octet-stream"
        if path.endswith(".js"):
            return "application/javascript"
        return super().guess_type(path)

def main():
    parser = argparse.ArgumentParser(description="Serve Godot Web export with COOP/COEP headers.")
    parser.add_argument("--port", type=int, default=8080, help="Port to bind (default: 8080)")
    parser.add_argument("--bind", type=str, default="127.0.0.1", help="Address to bind (default: 127.0.0.1)")
    parser.add_argument("--directory", type=str, default="build/web", help="Directory to serve (default: build/web)")
    args = parser.parse_args()

    serve_dir = os.path.abspath(args.directory)
    if not os.path.exists(serve_dir):
        os.makedirs(serve_dir, exist_ok=True)

    os.chdir(serve_dir)
    server_address = (args.bind, args.port)
    httpd = HTTPServer(server_address, GodotWebPreviewHandler)
    print(f"Godot Web Preview serving '{serve_dir}' at http://{args.bind}:{args.port}/")
    print("Press Ctrl+C to stop.")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server.")
        httpd.server_close()

if __name__ == "__main__":
    main()
