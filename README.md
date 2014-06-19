# community.hackerschool.com

## Development dependencies

- Ruby 2.1.2
  - bundler
  - foreman
- Postgres 9.3.4
- redis
- leiningen

### Installing dependencies on OS X using rvm, Homebrew, and Postgres.app

We recommend [Postgres.app](http://postgresapp.com/) if you're on OS X.

**Ruby stuff using rvm:**

```sh
$ rvm get head
$ rvm install ruby-2.1.2
$ rvm use ruby-2.1.2
$ gem install bundler
$ gem install foreman
```

**Leiningen and redis using Homebrew:**

```sh
$ brew update
$ brew install leiningen
$ brew install redis
# follow the printed instructions to have redis start automatically on boot
```

## Development configuration

We use foreman which sets environment variables from a `.env` file. We don't
check this into version control because it contains secret information. Here is
a sample `.env` file to get you started:

```sh
PORT=5001
RACK_ENV=development
DATABASE_URL=postgres://localhost/community_development
REDIS_URL=redis://localhost:6379

HACKER_SCHOOL_CLIENT_ID=your_client_id
HACKER_SCHOOL_CLIENT_SECRET=your_client_secret

# If you want to develop against a local copy of the Hacker School API, add:
HACKER_SCHOOL_SITE=http://localhost:5000

# If you want to import accounts from Hacker School
# (You won't be able to do this unless you are Hacker School faculty)
HACKER_SCHOOL_API_SECRET_TOKEN=hacker_school_api_secret
```

To generate a Hacker School client id and secret, go to your [Hacker School settings page](https://www.hackerschool.com/settings) and make a new OAuth app. The redirect url should be `http://localhost:5001/login/complete` (or your development host name if you don't develop off of localhost).

## Getting set up

```sh
$ bundle
$ bin/rake db:setup
```

## Running the code

```sh
$ foreman start

# In another terminal:
$ cd client
$ lein cljsbuild auto
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

Copyright © 2014 Hacker School

This software is licensed under the terms of the AGPL, Version 3. The complete license can be found at http://www.gnu.org/licenses/agpl-3.0.html.
