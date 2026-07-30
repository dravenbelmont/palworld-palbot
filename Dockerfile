FROM python:3.12-slim

WORKDIR /app

# Install git and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install the required Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Automatically inject a lightweight background HTTP server to satisfy Render's port binding requirement
RUN python -c ' \
path = "src/main.py"; \
code = "\n\nimport http.server, threading, os\ndef run_dummy_server():\n    port = int(os.environ.get(\"PORT\", 10000))\n    httpd = http.server.HTTPServer((\"\", port), http.server.SimpleHTTPRequestHandler)\n    httpd.serve_forever()\nthreading.Thread(target=run_dummy_server, daemon=True).start()\n"; \
with open(path, "a") as f: f.write(code) \
'

# Set the Python path so the app can locate the 'src' module
ENV PYTHONPATH=/app

# Start the bot
CMD ["python", "src/main.py"]
