FROM python:3.7
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
RUN apt-get update
COPY requirements.txt /code/
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
COPY . /code/
COPY nginx.conf /etc/nginx/
COPY uwsgi_params /etc/nginx/
COPY uwsgi.ini  /code/mysite/
# CMD ["uwsgi", "--ini", "/code/src/mysite/uwsgi.ini"]
