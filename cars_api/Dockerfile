FROM python:3.7-alpine

WORKDIR /app

RUN apk add --no-cache gcc musl-dev linux-headers curl mysql-client mysql-dev
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . ./

ENV FLASK_APP=app.py
ENV FLASK_ENV=development
ENV FLASK_RUN_HOST=0.0.0.0

EXPOSE 5000

CMD flask run
