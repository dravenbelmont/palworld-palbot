FROM python:3.12-slim

WORKDIR /app

# Install git and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install the required Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Append a lightweight background HTTP server cleanly to satisfy Render's port requirement
RUN echo "" >> src/main.py && \
    echo "import http.server, threading, os" >> src/main.py && \
    echo "def run_dummy_server():" >> src/main.py && \
    echo "    port = int(os.environ.get('PORT', 10000))" >> src/main.py && \
    echo "    httpd = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)" >> src/main.py && \
    echo "    httpd.serve_forever()" >> src/main.py && \
    echo "threading.Thread(target=run_dummy_server, daemon=True).start()" >> src/main.py

# Set the Python path so the app can locate the 'src' module
ENV PYTHONPATH=/app

# Start the bot
CMD ["python", "src/main.py"]
