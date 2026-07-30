FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app/
CMD ["sh", "-c", "python src/utils/database.py && sleep 5 && python startup.py"]


