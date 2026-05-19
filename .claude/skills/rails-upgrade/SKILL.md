---
name: rails-upgrade
description: Project conventions for Rails version upgrades in this app. Follow these whenever planning or executing a Rails minor/major upgrade (e.g. 7.1 → 7.2, 7.2 → 8.0), in addition to any general rails-upgrade tooling.
---

When upgrading Rails in this app, follow these two conventions. They override the defaults of any general-purpose Rails upgrade workflow.

## 1. Do not use the dual-boot pattern

Skip `next_rails`, `Gemfile.next`, `NextRails.next?` branches, and a dual-boot CI matrix. Deliver each Rails version upgrade as a single PR that bumps Rails and applies all required fixes together.

The team and app are small enough that the overhead of maintaining a dual-boot environment (extra lockfile, conditional Gemfile, doubled CI runtime, code branches that have to be cleaned up later) is not worth the safety it adds. A single-PR upgrade is simpler to review, deploy, and revert.

For breaking-change fixes that would normally need a `NextRails.next?` branch in a dual-boot world, apply the new-version-only API directly in the same PR as the Rails bump — both changes ship together.

## 2. Carefully review every diff that `rails app:update` produces

`rails app:update` is interactive; for each conflicting file it offers `Y`/`n`/`d`/`h`. Use `d` to view the diff and then decide per file. Three categories:

- **Take stock changes** when they are real improvements with no app-specific cost (e.g. modern Puma threading defaults, adding `:email` to `filter_parameter_logging`, new useful defaults that don't conflict with custom config).
- **Keep our version** when stock generator output would erase app-specific configuration (custom `log_tags`, `hosts` allowlist, asset paths, CORS policy, `frame_ancestors`, `queue_adapter`, `exceptions_app`, custom URL options, environment-specific deploy concerns, etc.).
- **Cherry-pick** lines worth taking and leave everything else untouched.

**Do not just `n`-decline every conflict.** That shortcut quietly accumulates config drift — your config files keep aging away from current Rails defaults, and you lose legitimate improvements baked into the updated generator templates.

A reliable workflow when working through `app:update` non-interactively (e.g. via Claude Code):

```bash
# 1. Back up the conflict files
mkdir -p /tmp/<app>-pre-update
cp <each conflict file> /tmp/<app>-pre-update/<same path>

# 2. Force-write stock templates
bin/rails app:update --force

# 3. Per-file: diff stock vs backup
diff -u /tmp/<app>-pre-update/<file> <file>

# 4. Decide per file: keep stock, restore backup, or merge selectively
cp /tmp/<app>-pre-update/<file> <file>   # restore mine
# (or leave stock in place, or edit by hand to merge)
```

This produces one reviewable diff per file instead of the interactive prompt and makes the per-file decisions easy to discuss and document in the PR.