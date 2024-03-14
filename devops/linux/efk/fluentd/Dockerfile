FROM fluent/fluentd:v1.12-1

USER root

RUN echo "source 'https://mirrors.tuna.tsinghua.edu.cn/rubygems/'" > Gemfile \
  && gem install bundler \
  && gem install fluent-plugin-elasticsearch

USER fluent

CMD ["fluentd"]