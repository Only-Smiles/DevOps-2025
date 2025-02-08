FROM ruby:3.4.1-bookworm

WORKDIR /app

COPY config.ru ./

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY db/minitwit.db /tmp/

COPY public/stylesheets ./public/stylesheets
COPY views ./views

COPY minitwit.rb  ./




