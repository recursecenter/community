# Community

Community is a hybrid forum and mailing list server.

[![CircleCI Build Status](https://circleci.com/gh/recursecenter/community.png?circle-token=b21bc07728805b01ea238d0585f7de34dd3b23c3)](https://circleci.com/gh/recursecenter/community)

## Dependencies

- Ruby 2.4.1
  - bundler
- Postgres 9.5.4
- redis
- leiningen
- Elasticsearch 2.4

Also, note that because Community is tied to the Recurse Center API, you'll need to be a Recurser to run this.

### Installing dependencies on macOS

**Postgres:**

We recommend [Postgres.app](http://postgresapp.com/).

**Ruby (using rvm):**

```sh
# if you don't already have rvm, follow the instructions at https://rvm.io
$ rvm get stable
$ rvm install ruby-2.4.1
$ rvm use ruby-2.4.1
```

**Leiningen and redis (using Homebrew):**

```sh
# if you don't already have homebrew, follow the instructions at https://brew.sh
$ brew update
$ brew install leiningen redis elasticsearch
# if you'd rather not start redis-server and elasticsearch every time before hacking
# on community, follow the printed instructions to have redis and elasticsearch
# start automatically on boot
```

`elasticsearch` may fail to build if Java 1.7+ is not installed---if you run into this, you can just run:

```sh
# If you don't already have caskroom:
$ brew install caskroom/cask/brew-cask
# And then:
$ brew cask install java
$ brew install elasticsearch
```

## Configuration

We use `heroku local` which sets environment variables from a `.env` file. We don't
check this into version control because it contains secret information. Here is
a sample `.env` file to get you started:

```sh
PORT=5001
RACK_ENV=development
REDIS_URL=redis://localhost:6379

# See below for instructions on getting this id and secret
HACKER_SCHOOL_CLIENT_ID=your_client_id
HACKER_SCHOOL_CLIENT_SECRET=your_client_secret

JASMINE_CONFIG_PATH=test/javascripts/support/jasmine.yml

# If you want to import accounts from the Recurse Center
# (You won't be able to do this unless you are Recurse Center faculty)
# HACKER_SCHOOL_API_SECRET_TOKEN=hacker_school_api_secret

# If you want to develop against a local copy of the Hacker School API, add:
# HACKER_SCHOOL_SITE=http://localhost:5000

# Needed for batch mail sending in production
# MAILGUN_API_KEY=your_mailgun_api_key
```

To generate a Recurse Center client id and secret, go to your [Recurse Center settings page](https://www.recurse.com/settings) and make a new OAuth app. The redirect url should be `http://localhost:5001/login/complete` (or your development host name if you don't develop off of localhost).

## Running the code

Before doing anything, make sure that `redis-server`, `elasticsearch`, and `postgres` are running.

The first time you run the code, install necessary gems and set up your database.

```sh
$ gem install bundler
$ bundle
$ bin/rake db:setup
```

After that, start your development server and start building the client JS.

```sh
$ heroku local

# In another terminal:
$ cd client
$ lein cljsbuild auto
```

Lein can take as long as ~30 seconds to build all the Clojurescript, so be patient! The site won't work until it's done. Once it's finished, simply visit [localhost:5001](http://localhost:5001/).

### Running the production ClojureScript

The production client code will sometimes function differently than the development code. This can happen when you forget to add externs for a library you are calling, or if `lein cljsbuild auto` randomly makes a bad client. Because of this, we should test the production client before deploying. To do that, you can set `CLIENT_ENV` to production and run `heroku local`. If you don't set CLIENT_ENV, it defaults to the Rails environment.

```sh
$ CLIENT_ENV=production heroku local
```

## Where is `db/schema.rb`?

Look at `db/structure.sql` instead. We use this because it supports Postgres views.

## Client testing

We use a small ClojureScript wrapper over [Jasmine](http://jasmine.github.io/2.0/introduction.html) for testing our client. If you're running `lein cljsbuild auto` (as above), the client tests will be built automatically.

To run the client tests:

```sh
$ bin/rake jasmine
# Navigate to localhost:8888 to run the tests.
# Refresh the page to re-run the tests.
```

# License

Copyright © 2017 the Recurse Center

This software is licensed under the terms of the AGPL, Version 3. The complete license can be found at http://www.gnu.org/licenses/agpl-3.0.html.
