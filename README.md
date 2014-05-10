# community.hackerschool.com

## Configuration

We use foreman which sets environment variables from a `.env` file. We don't
check this into version control because it contains secret information. Here is
a sample `.env` file to get you started:

```sh
PORT=5001
RACK_ENV=development
DATABASE_URL=postgres://localhost/community_development

HACKER_SCHOOL_CLIENT_ID=your_client_id
HACKER_SCHOOL_CLIENT_SECRET=your_client_secret

# If you want to develop against a local copy of the Hacker School API, add:
HACKER_SCHOOL_SITE=http://localhost:5000
```

## Running the code

```sh
$ bundle
...snip...
$ foreman start

# In another terminal:
$ cd client
$ lein cljsbuild auto
```

## OAuth with Hacker School

1. Go to https://www.hackerschool.com/settings and make a new app. The redirect
   url should be http://your-dev-server/login/complete.

## Needs

- use HS accounts (single sign-on)
- subforums
- editing
- fine grained notification settings (per thread, per reply)
- pinned threads
- well integrated with HS.com
  - no forum profiles
  - no private messages
- can see batch under name
- @-mentions
- unread message highlighting
- revision history
- markdown, syntax highlighting
- @-mention autocomplete
- no signatures

## Wants

- community posts (anyone can edit, kind of like Stack Overflow wikis)
- keyboard shortcuts
- search
- Zulip integration (for pings)
- real-time updates
- infinite scroll
- quoting

## Maybe

- likes, staring messages
- emoji
- timezones vs canonical forum time
