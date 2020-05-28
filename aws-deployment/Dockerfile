FROM python:3.8.1-slim-buster

WORKDIR /usr/src/app

EXPOSE 8000

RUN pip install --upgrade pip
COPY app/requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

COPY app/api.py /usr/src/app/

CMD ["gunicorn", "--log-level=debug", "--bind=0.0.0.0:8000", "api:app"]