FROM python:3.11-slim

WORKDIR /app

# Install git and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install the required Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set the Python path so the app can locate the 'src' module
ENV PYTHONPATH=/app

# Start the bot
CMD ["python", "src/main.py"]
