FROM python:3.9

WORKDIR /broken_json_parser

COPY . .

RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple && \
  pip config set global.trusted-host mirrors.aliyun.com && \
  pip install --no-cache-dir --upgrade -r /broken_json_parser/requirements.txt

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]