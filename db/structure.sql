--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    queue character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: discussion_threads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE discussion_threads (
    id integer NOT NULL,
    title character varying(255),
    subforum_id integer,
    created_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    marked_unread_at timestamp without time zone
);


--
-- Name: discussion_threads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE discussion_threads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_threads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE discussion_threads_id_seq OWNED BY discussion_threads.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posts (
    id integer NOT NULL,
    body text,
    thread_id integer,
    author_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE posts_id_seq OWNED BY posts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: subforum_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subforum_groups (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    ordinal integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: subforum_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subforum_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subforum_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subforum_groups_id_seq OWNED BY subforum_groups.id;


--
-- Name: subforums; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subforums (
    id integer NOT NULL,
    name character varying(255),
    subforum_group_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    marked_unread_at timestamp without time zone
);


--
-- Name: subforums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subforums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subforums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subforums_id_seq OWNED BY subforums.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    avatar_url character varying(255),
    batch_name character varying(255),
    hacker_school_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: visited_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visited_statuses (
    id integer NOT NULL,
    user_id integer,
    last_visited timestamp without time zone,
    visitable_id integer,
    visitable_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: subforums_with_visited_status; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW subforums_with_visited_status AS
 SELECT subforum_users.id,
    subforum_users.name,
    subforum_users.subforum_group_id,
    subforum_users.created_at,
    subforum_users.updated_at,
    subforum_users.marked_unread_at,
    subforum_users.user_id,
    visited_statuses.last_visited
   FROM (( SELECT subforums.id,
            subforums.name,
            subforums.subforum_group_id,
            subforums.created_at,
            subforums.updated_at,
            subforums.marked_unread_at,
            users.id AS user_id
           FROM subforums,
            users) subforum_users
   LEFT JOIN visited_statuses ON ((((subforum_users.id = visited_statuses.visitable_id) AND ((subforum_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL))) AND ((visited_statuses.visitable_type)::text = 'Subforum'::text))));


--
-- Name: threads_with_visited_status; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW threads_with_visited_status AS
 SELECT thread_users.id,
    thread_users.title,
    thread_users.subforum_id,
    thread_users.created_by_id,
    thread_users.created_at,
    thread_users.updated_at,
    thread_users.marked_unread_at,
    thread_users.user_id,
    visited_statuses.last_visited
   FROM (( SELECT discussion_threads.id,
            discussion_threads.title,
            discussion_threads.subforum_id,
            discussion_threads.created_by_id,
            discussion_threads.created_at,
            discussion_threads.updated_at,
            discussion_threads.marked_unread_at,
            users.id AS user_id
           FROM discussion_threads,
            users) thread_users
   LEFT JOIN visited_statuses ON ((((thread_users.id = visited_statuses.visitable_id) AND ((thread_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL))) AND ((visited_statuses.visitable_type)::text = 'DiscussionThread'::text))));


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: visited_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visited_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visited_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visited_statuses_id_seq OWNED BY visited_statuses.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_threads ALTER COLUMN id SET DEFAULT nextval('discussion_threads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subforum_groups ALTER COLUMN id SET DEFAULT nextval('subforum_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subforums ALTER COLUMN id SET DEFAULT nextval('subforums_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY visited_statuses ALTER COLUMN id SET DEFAULT nextval('visited_statuses_id_seq'::regclass);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: discussion_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY discussion_threads
    ADD CONSTRAINT discussion_threads_pkey PRIMARY KEY (id);


--
-- Name: posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: subforum_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subforum_groups
    ADD CONSTRAINT subforum_groups_pkey PRIMARY KEY (id);


--
-- Name: subforums_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subforums
    ADD CONSTRAINT subforums_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visited_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visited_statuses
    ADD CONSTRAINT visited_statuses_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_discussion_threads_on_created_by_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_discussion_threads_on_created_by_id ON discussion_threads USING btree (created_by_id);


--
-- Name: index_discussion_threads_on_subforum_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_discussion_threads_on_subforum_id ON discussion_threads USING btree (subforum_id);


--
-- Name: index_users_on_hacker_school_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_hacker_school_id ON users USING btree (hacker_school_id);


--
-- Name: index_visited_statuses_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_visited_statuses_on_user_id ON visited_statuses USING btree (user_id);


--
-- Name: index_visited_statuses_on_visitable_id_and_visitable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_visited_statuses_on_visitable_id_and_visitable_type ON visited_statuses USING btree (visitable_id, visitable_type);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20140510214628');

INSERT INTO schema_migrations (version) VALUES ('20140512214828');

INSERT INTO schema_migrations (version) VALUES ('20140513153440');

INSERT INTO schema_migrations (version) VALUES ('20140520150925');

INSERT INTO schema_migrations (version) VALUES ('20140520201523');

INSERT INTO schema_migrations (version) VALUES ('20140605200642');

INSERT INTO schema_migrations (version) VALUES ('20140605202151');

INSERT INTO schema_migrations (version) VALUES ('20140605212910');

INSERT INTO schema_migrations (version) VALUES ('20140605223603');

INSERT INTO schema_migrations (version) VALUES ('20140605224228');

INSERT INTO schema_migrations (version) VALUES ('20140606154516');

INSERT INTO schema_migrations (version) VALUES ('20140609195302');

INSERT INTO schema_migrations (version) VALUES ('20140611152940');

