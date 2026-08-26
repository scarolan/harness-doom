"""
DOOM Gate Server — holds level-completion state for the pipeline approval gate.

Endpoints:
  GET  /status   → {"complete": bool, "player": str, "timestamp": str}
  POST /complete → mark level as complete (called by the game page)
  POST /reset    → reset state for the next pipeline run
  GET  /healthz  → 200 OK
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import threading
import time

state = {"complete": False}
lock = threading.Lock()


class GateHandler(BaseHTTPRequestHandler):
    def _cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path == "/status":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._cors_headers()
            self.end_headers()
            with lock:
                self.wfile.write(json.dumps(state).encode())
        elif self.path == "/healthz":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == "/complete":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length) if content_length else b"{}"
            with lock:
                state["complete"] = True
                state["timestamp"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                try:
                    data = json.loads(body)
                    state["player"] = data.get("player", "Doomguy")
                except (json.JSONDecodeError, AttributeError):
                    state["player"] = "Doomguy"
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({"approved": True}).encode())
            print(f"[GATE] Level complete! Player: {state.get('player')}")
        elif self.path == "/reset":
            with lock:
                state.clear()
                state["complete"] = False
            self.send_response(200)
            self._cors_headers()
            self.end_headers()
            print("[GATE] State reset for next run")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        print(f"[GATE] {args[0]}")


if __name__ == "__main__":
    port = 8081
    server = HTTPServer(("", port), GateHandler)
    print(f"[GATE] DOOM Gate Server listening on :{port}")
    print("[GATE] Waiting for someone to beat E1M1...")
    server.serve_forever()
