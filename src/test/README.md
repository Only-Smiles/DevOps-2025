# Testing for minitwit
This directory contains the tests for minitwit, all tests are written in python

## Requirements
Running the tests requires pytest, install with pip: `pip install pytest requests` <br>
Running the website requires ruby and bundler: `bundle install gemfile && cd src/minitwit && bundle exec rackup --port 4567`


## Running the tests
The tests are expected to be run while in the /test directory and to run the test make sure you have the minitwit_api.rb running on port 4567.
From here run `pytest` and enjoy

