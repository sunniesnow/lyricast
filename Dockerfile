FROM ruby:4.0-slim

WORKDIR /app

RUN apt-get update && apt-get install -y build-essential
COPY . .
RUN bundle install

ENV LYRICAST_DATA_DIR /data
ENV LYRICAST_CONFIG_DIR /config
ENV RACK_ENV production

CMD ["bundle", "exec", "./main.rb"]
