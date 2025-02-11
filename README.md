# DevOps 2025
Project repository for group 'the happy group'

## Ruby installation

Requires ruby version >= 3.4.1

Before running the project, you will need to install all the dependencies from the Gemfile.
Run `bundle install` from the terminal in order to do so.

Now you will be able to run the project from the terminal

```
ruby minitwit.rb
```

## Docker

This assumes you have installed Docker on your computer.

In order to run the application in a docker container, run the following two commands

```
docker build -t thg/rubytwit:latest .
docker run --rm -p 4567:4567 thg/rubytwit
```

And you should be able to access the container at http://localhost:4567/public