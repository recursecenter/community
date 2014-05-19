# Random ideas

- use prismatic's [schema](https://github.com/prismatic/schema) to
  validate global app state and declaratively specify "models" on the
  client.



# Models

## User
- name
- email
- batch name
- avatar
- hacker school id
- has and belongs to many groups

## Groups
- examples: admin, prebatch

## Post
- belongs to a thread
- belongs to a user
- content
- implicitly ordered by create_time in a thread

## Thread
- title
- posts
- belongs to a subforum
- created by/ belongs to a user
- might be pinned (or it might just be "important" and subforums know
  to render them at the top)
  - pinned things might be ordered
- last posted to

## SubForum
- alphabetically ordered for now (within group)
- name
- description?
- threads
- visible to certain groups

## ThreadVisit (are there unread posts in the thread for a user)
- absence of this means user hasn't read thread at all
- has a thread and user
- last time user visited thread
- last post id the user visited

## ForumVisit
- absence of this means user hasn't visited forum
- has a forum and a user
- last time user visited forum

## SubForumGroup
- name
- ordered
- have subforums
