"""Serve only the compiled Flutter app on the selected Wi-Fi address."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse

class AppHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def list_directory(self, path):
        self.send_error(403, 'Directory listing disabled')
        return None

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', required=True)
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1] / 'build/web'
    if not (root / 'index.html').exists():
        raise SystemExit('Build the Flutter web application first.')
    handler = partial(AppHandler, directory=str(root))
    with ThreadingHTTPServer((args.host, args.port), handler) as server:
        print(f'Flutter app listening at http://{args.host}:{args.port}', flush=True)
        server.serve_forever()
