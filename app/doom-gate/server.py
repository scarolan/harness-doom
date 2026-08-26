"""
DOOM Gate Server — booth backend for the DOOM pipeline approval gate.

Endpoints:
  POST /start      → register player, reset gate, trigger Harness pipeline
  GET  /status     → {"complete": bool, "player": str, ...} (pipeline polls this)
  POST /complete   → mark level complete, add to leaderboard
  GET  /leaderboard → last 10 completions
  POST /reset      → reset gate state
  GET  /healthz    → 200 OK
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import threading
import time
import urllib.request
import urllib.error

DATA_DIR = os.environ.get("DATA_DIR", "/data")
LEADERBOARD_FILE = os.path.join(DATA_DIR, "leaderboard.json")
MAX_LEADERBOARD = 10

HARNESS_API_KEY = os.environ.get("HARNESS_API_KEY", "")
HARNESS_ACCOUNT_ID = os.environ.get("HARNESS_ACCOUNT_ID", "")
HARNESS_ORG_ID = os.environ.get("HARNESS_ORG_ID", "")
HARNESS_PROJECT_ID = os.environ.get("HARNESS_PROJECT_ID", "")
HARNESS_PIPELINE_ID = os.environ.get("HARNESS_PIPELINE_ID", "doom_gate_deploy")
HARNESS_BASE_URL = os.environ.get("HARNESS_BASE_URL", "https://app.harness.io")

DIFFICULTY_LEVELS = {
    1: {"name": "I'm Too Young to Die", "emoji": "😊"},
    2: {"name": "Hey, Not Too Rough", "emoji": "😏"},
    3: {"name": "Hurt Me Plenty", "emoji": "😤"},
    4: {"name": "Ultra-Violence", "emoji": "🔥"},
    5: {"name": "Nightmare!", "emoji": "💀"},
}

state = {"complete": False}
lock = threading.Lock()


def load_leaderboard():
    try:
        with open(LEADERBOARD_FILE, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def save_leaderboard(entries):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(LEADERBOARD_FILE, "w") as f:
        json.dump(entries, f, indent=2)


def add_to_leaderboard(player, difficulty, elapsed):
    entries = load_leaderboard()
    diff_info = DIFFICULTY_LEVELS.get(difficulty, DIFFICULTY_LEVELS[3])
    entries.append({
        "player": player,
        "difficulty": difficulty,
        "difficulty_name": diff_info["name"],
        "emoji": diff_info["emoji"],
        "elapsed": elapsed,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    })
    entries = entries[-MAX_LEADERBOARD:]
    save_leaderboard(entries)
    return entries


def trigger_harness_pipeline(player, difficulty):
    if not HARNESS_API_KEY:
        print("[GATE] No HARNESS_API_KEY set — skipping pipeline trigger")
        return {"skipped": True, "reason": "no API key configured"}

    url = (
        f"{HARNESS_BASE_URL}/pipeline/api/pipeline/execute/"
        f"{HARNESS_PIPELINE_ID}"
        f"?accountIdentifier={HARNESS_ACCOUNT_ID}"
        f"&orgIdentifier={HARNESS_ORG_ID}"
        f"&projectIdentifier={HARNESS_PROJECT_ID}"
    )

    payload = json.dumps({
        "inputSetTemplateYaml": "",
        "stageIdentifiers": [],
        "runtimeInputYaml": "",
        "notesForPipelineExecution": f"DOOM Gate: {player} on {DIFFICULTY_LEVELS.get(difficulty, {}).get('name', 'Unknown')}"
    }).encode()

    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "x-api-key": HARNESS_API_KEY,
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = json.loads(resp.read())
            plan_id = body.get("data", {}).get("planExecution", {}).get("uuid", "unknown")
            print(f"[GATE] Pipeline triggered! Execution ID: {plan_id}")
            return {"triggered": True, "executionId": plan_id}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode() if e.fp else ""
        print(f"[GATE] Pipeline trigger failed: {e.code} — {error_body[:200]}")
        return {"triggered": False, "error": f"HTTP {e.code}", "detail": error_body[:200]}
    except Exception as e:
        print(f"[GATE] Pipeline trigger error: {e}")
        return {"triggered": False, "error": str(e)}


class GateHandler(BaseHTTPRequestHandler):
    def _cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json_response(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self._cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path == "/status":
            with lock:
                self._json_response(200, state)
        elif self.path == "/leaderboard":
            entries = load_leaderboard()
            self._json_response(200, {"entries": entries, "max": MAX_LEADERBOARD})
        elif self.path == "/healthz":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length else b"{}"

        if self.path == "/start":
            try:
                data = json.loads(body)
            except (json.JSONDecodeError, AttributeError):
                data = {}

            player = data.get("player", "Doomguy")[:30]
            difficulty = int(data.get("difficulty", 3))
            difficulty = max(1, min(5, difficulty))

            with lock:
                state.clear()
                state["complete"] = False
                state["player"] = player
                state["difficulty"] = difficulty
                state["started"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

            print(f"[GATE] New run: {player} on {DIFFICULTY_LEVELS[difficulty]['name']}")

            pipeline_result = trigger_harness_pipeline(player, difficulty)

            self._json_response(200, {
                "started": True,
                "player": player,
                "difficulty": difficulty,
                "pipeline": pipeline_result,
            })

        elif self.path == "/complete":
            try:
                data = json.loads(body)
            except (json.JSONDecodeError, AttributeError):
                data = {}

            with lock:
                player = data.get("player") or state.get("player", "Doomguy")
                difficulty = data.get("difficulty") or state.get("difficulty", 3)
                elapsed = data.get("elapsed", 0)

                state["complete"] = True
                state["player"] = player
                state["difficulty"] = difficulty
                state["elapsed"] = elapsed
                state["timestamp"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

            entries = add_to_leaderboard(player, int(difficulty), elapsed)
            print(f"[GATE] Level complete! {player} — {elapsed}s — {DIFFICULTY_LEVELS.get(int(difficulty), {}).get('name', '?')}")

            self._json_response(200, {"approved": True, "leaderboard": entries})

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
    os.makedirs(DATA_DIR, exist_ok=True)
    port = 8081
    server = HTTPServer(("", port), GateHandler)
    print(f"[GATE] DOOM Gate Server listening on :{port}")
    print(f"[GATE] Harness API: {'configured' if HARNESS_API_KEY else 'NOT configured (set HARNESS_API_KEY)'}")
    print("[GATE] Waiting for players...")
    server.serve_forever()
