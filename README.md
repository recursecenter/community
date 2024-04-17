# Community

Community is a hybrid forum and mailing list server.

[![CircleCI Build Status](https://circleci.com/gh/recursecenter/community.png?circle-token=b21bc07728805b01ea238d0585f7de34dd3b23c3)](https://circleci.com/gh/recursecenter/community)

## Dependencies

- Ruby
- OpenJDK 8 (newer versions don't work)
- Leiningen
- Node (for tests)
- Postgres
- Redis

Also, note that because Community is tied to the Recurse Center API, you'll need to be a Recurser to run this.

### Installing dependencies on macOS

```sh
$ cd path/to/community
```

**Ruby (using ruby-install and chruby)**

For detailed setup instructions, see the [chruby README](https://github.com/postmodern/chruby/blob/master/README.md).

```sh
$ brew install ruby-install chruby
$ echo "source $(brew --prefix chruby)/share/chruby/chruby.sh" >> ~/.zshrc
$ echo "source $(brew --prefix chruby)/share/chruby/auto.sh" >> ~/.zshrc
$ source $(brew --prefix chruby)/share/chruby/chruby.sh
$ source $(brew --prefix chruby)/share/chruby/auto.sh
$ ruby-install ruby-3.2.1
$ ruby -v
ruby 3.2.1 (2023-02-08 revision 31819e82c8) [arm64-darwin22]
```

**Jenv and OpenJDK 8**

```sh
$ brew install jenv
$ echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
$ echo 'eval "$(jenv init -)"' >> ~/.zshrc
$ eval "$(jenv init -)"
$ jenv prefix
jenv: version `1.8' is not installed
```

Download and install the latest version of the Eclipse Temurin build of [OpenJDK 8](https://adoptium.net/temurin/releases/?version=8).

Then tell jenv about it:

```sh
$ jenv add /Library/Java/JavaVirtualMachines/temurin-8.jdk/Contents/Home
```

**Leiningen**

```sh
$ brew install leiningen
$ lein version
Leiningen 2.10.0 on Java 1.8.0_312 OpenJDK 64-Bit Server VM
```

**Node**

```sh
$ brew install node yarn
```

**Postgres**

Install [Postgres.app](http://postgresapp.com/).

```sh
$ echo 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' >> ~/.zshrc
$ export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
$ which pg_config
/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config
```

**Redis**

```sh
$ brew install redis
$ brew services
Name    Status  User  File
redis   started david ~/Library/LaunchAgents/homebrew.mxcl.redis.plist
```

If redis isn't running, the following command will start it and set it to run on boot:

```sh
$ brew services start redis
```

## Configuration

We use `foreman` which sets environment variables from a `.env` file. We don't
check this into version control because it contains secret information. Here is
a sample `.env` file to get you started:

```sh
PORT=5001
RACK_ENV=development
RAILS_LOG_TO_STDOUT=enabled
RACK_TIMEOUT_SERVICE_TIMEOUT=2592000
REDIS_URL=redis://localhost:6379

# You can generate a good value for these with `bin/rails secret`
SECRET_KEY_BASE=secret_key
EMAIL_SECRET_KEY=email_secret_key

# See below for instructions on getting this id and secret
HACKER_SCHOOL_CLIENT_ID=your_client_id
HACKER_SCHOOL_CLIENT_SECRET=your_client_secret

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

Install necessary dependencies and set up your database.

```sh
$ bundle install
$ bin/yarn
$ rails db:setup
```

After that, use `bin/dev` to start `foreman` which will run the Rails server as well as `rails cljs:watch` to continuously build the ClojureScript code.

```sh
$ bin/dev
```

`rails cljs:watch` can take as long as ~30 seconds to build all the ClojureScript, so be patient! The site won't work until it's done. Once it's finished, simply visit [localhost:5001](http://localhost:5001/).

### Running the production ClojureScript

The production client code will sometimes function differently than the development code. This can happen when you forget to add externs for a library you are calling, or if `lein cljsbuild auto` randomly makes a bad client. Because of this, we should test the production client before deploying. To do that, you can set `CLJS_ENV` to production and run `bin/dev`. If you don't set CLJS_ENV, it defaults to the Rails environment.

```sh
$ CLJS_ENV=production bin/dev
```

## ClojureScript testing

To build and run ClojureScript tests once, run:

```sh
$ rails cljs:build:test cljs:test
```

For a quicker feedback loop, build the tests in the background:

```sh
$ rails cljs:watch:test
```

Then run:

```sh
$ rails cljs:test
```

### Removing ClojureScript

If we keep using Community, we're eventually going to remove ClojureScript. Here's what you need to do.

Delete these files:

- .java-version
- app/clojurescript
- app/assets/builds
- bin/build
- config/initializers/clojure_script.rb
- lib/clojure_script.rb
- lib/tasks/cljs.rake
- package.json
- project.clj
- test/clojurescript
- test/assets

Remove references to ClojureScript from these files:

- .circleci/config.yml
- app/views/layouts/application.html.erb
- Procfile.dev
- README.md

Remove the heroku/clojure buildpack.

# License

Copyright © 2023 the Recurse Center

This software is licensed under the terms of the AGPL, Version 3. The complete license can be found at http://www.gnu.org/licenses/agpl-3.0.html.
