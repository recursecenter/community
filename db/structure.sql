SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
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

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: discussion_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_threads (
    id integer NOT NULL,
    title character varying(255),
    subforum_id integer,
    created_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    highest_post_number integer DEFAULT 0,
    pinned boolean DEFAULT false,
    last_post_created_at timestamp without time zone,
    last_post_created_by_id integer
);


--
-- Name: discussion_threads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_threads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_threads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_threads_id_seq OWNED BY public.discussion_threads.id;


--
-- Name: group_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_memberships (
    id integer NOT NULL,
    group_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: group_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_memberships_id_seq OWNED BY public.group_memberships.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id integer NOT NULL,
    name character varying(255),
    hacker_school_batch_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: groups_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups_posts (
    group_id integer,
    post_id integer
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    type character varying(255),
    user_id integer,
    mentioned_by_id integer,
    post_id integer,
    read boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id integer NOT NULL,
    body text,
    thread_id integer,
    author_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    post_number integer,
    broadcast_to_subscribers boolean DEFAULT true,
    message_id character varying(255)
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: roles_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles_users (
    user_id integer NOT NULL,
    role_id integer NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: subforum_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subforum_groups (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    ordinal integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: subforum_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subforum_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subforum_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subforum_groups_id_seq OWNED BY public.subforum_groups.id;


--
-- Name: subforums; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subforums (
    id integer NOT NULL,
    name character varying(255),
    subforum_group_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    ui_color character varying(255),
    required_role_ids integer[],
    description text
);


--
-- Name: subforums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subforums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subforums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subforums_id_seq OWNED BY public.subforums.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    subscribed boolean DEFAULT false,
    reason character varying(255),
    subscribable_id integer,
    subscribable_type character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    avatar_url character varying,
    batch_name character varying(255),
    hacker_school_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    email_on_mention boolean DEFAULT true,
    subscribe_on_create boolean DEFAULT true,
    subscribe_when_mentioned boolean DEFAULT true,
    subscribe_new_thread_in_subscribed_subforum boolean DEFAULT true,
    last_read_welcome_message_at timestamp without time zone,
    deactivated boolean DEFAULT false
);


--
-- Name: visited_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visited_statuses (
    id integer NOT NULL,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    thread_id integer,
    last_post_number_read integer DEFAULT 0
);


--
-- Name: threads_with_visited_status; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.threads_with_visited_status AS
 SELECT thread_users.id,
    thread_users.title,
    thread_users.subforum_id,
    thread_users.created_by_id,
    thread_users.created_at,
    thread_users.updated_at,
    thread_users.highest_post_number,
    thread_users.pinned,
    thread_users.last_post_created_at,
    thread_users.last_post_created_by_id,
    thread_users.user_id,
    visited_statuses.last_post_number_read,
    (visited_statuses.last_post_number_read < thread_users.highest_post_number) AS unread
   FROM (( SELECT discussion_threads.id,
            discussion_threads.title,
            discussion_threads.subforum_id,
            discussion_threads.created_by_id,
            discussion_threads.created_at,
            discussion_threads.updated_at,
            discussion_threads.highest_post_number,
            discussion_threads.pinned,
            discussion_threads.last_post_created_at,
            discussion_threads.last_post_created_by_id,
            users.id AS user_id
           FROM public.discussion_threads,
            public.users) thread_users
     JOIN public.visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND (thread_users.user_id = visited_statuses.user_id))))
UNION
 SELECT thread_users.id,
    thread_users.title,
    thread_users.subforum_id,
    thread_users.created_by_id,
    thread_users.created_at,
    thread_users.updated_at,
    thread_users.highest_post_number,
    thread_users.pinned,
    thread_users.last_post_created_at,
    thread_users.last_post_created_by_id,
    thread_users.user_id,
    0 AS last_post_number_read,
    true AS unread
   FROM (( SELECT discussion_threads.id,
            discussion_threads.title,
            discussion_threads.subforum_id,
            discussion_threads.created_by_id,
            discussion_threads.created_at,
            discussion_threads.updated_at,
            discussion_threads.highest_post_number,
            discussion_threads.pinned,
            discussion_threads.last_post_created_at,
            discussion_threads.last_post_created_by_id,
            users.id AS user_id
           FROM public.discussion_threads,
            public.users) thread_users
     LEFT JOIN public.visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND (thread_users.user_id = visited_statuses.user_id))))
  WHERE (visited_statuses.id IS NULL);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: visited_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.visited_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visited_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.visited_statuses_id_seq OWNED BY public.visited_statuses.id;


--
-- Name: welcome_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.welcome_messages (
    id integer NOT NULL,
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: welcome_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.welcome_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: welcome_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.welcome_messages_id_seq OWNED BY public.welcome_messages.id;


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: discussion_threads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_threads ALTER COLUMN id SET DEFAULT nextval('public.discussion_threads_id_seq'::regclass);


--
-- Name: group_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships ALTER COLUMN id SET DEFAULT nextval('public.group_memberships_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: subforum_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subforum_groups ALTER COLUMN id SET DEFAULT nextval('public.subforum_groups_id_seq'::regclass);


--
-- Name: subforums id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subforums ALTER COLUMN id SET DEFAULT nextval('public.subforums_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: visited_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visited_statuses ALTER COLUMN id SET DEFAULT nextval('public.visited_statuses_id_seq'::regclass);


--
-- Name: welcome_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.welcome_messages ALTER COLUMN id SET DEFAULT nextval('public.welcome_messages_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: discussion_threads discussion_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_threads
    ADD CONSTRAINT discussion_threads_pkey PRIMARY KEY (id);


--
-- Name: group_memberships group_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT group_memberships_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: subforum_groups subforum_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subforum_groups
    ADD CONSTRAINT subforum_groups_pkey PRIMARY KEY (id);


--
-- Name: subforums subforums_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subforums
    ADD CONSTRAINT subforums_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visited_statuses visited_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visited_statuses
    ADD CONSTRAINT visited_statuses_pkey PRIMARY KEY (id);


--
-- Name: welcome_messages welcome_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.welcome_messages
    ADD CONSTRAINT welcome_messages_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_discussion_threads_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_threads_on_created_by_id ON public.discussion_threads USING btree (created_by_id);


--
-- Name: index_discussion_threads_on_last_post_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_threads_on_last_post_created_by_id ON public.discussion_threads USING btree (last_post_created_by_id);


--
-- Name: index_discussion_threads_on_subforum_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_threads_on_subforum_id ON public.discussion_threads USING btree (subforum_id);


--
-- Name: index_notifications_on_mentioned_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_mentioned_by_id ON public.notifications USING btree (mentioned_by_id);


--
-- Name: index_notifications_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_post_id ON public.notifications USING btree (post_id);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_user_id ON public.notifications USING btree (user_id);


--
-- Name: index_posts_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_author_id ON public.posts USING btree (author_id);


--
-- Name: index_posts_on_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_thread_id ON public.posts USING btree (thread_id);


--
-- Name: index_roles_users_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_users_on_role_id ON public.roles_users USING btree (role_id);


--
-- Name: index_roles_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_users_on_user_id ON public.roles_users USING btree (user_id);


--
-- Name: index_subscriptions_on_subscribable_id_and_subscribable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_subscribable_id_and_subscribable_type ON public.subscriptions USING btree (subscribable_id, subscribable_type);


--
-- Name: index_users_on_hacker_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_hacker_school_id ON public.users USING btree (hacker_school_id);


--
-- Name: index_visited_statuses_on_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_visited_statuses_on_thread_id ON public.visited_statuses USING btree (thread_id);


--
-- Name: index_visited_statuses_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_visited_statuses_on_user_id ON public.visited_statuses USING btree (user_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20140510214628'),
('20140512214828'),
('20140513153440'),
('20140520150925'),
('20140520201523'),
('20140605200642'),
('20140605202151'),
('20140605212910'),
('20140605223603'),
('20140605224228'),
('20140606154516'),
('20140609195302'),
('20140611152940'),
('20140611180743'),
('20140702171957'),
('20140707203027'),
('20140708205925'),
('20140710163204'),
('20140712031258'),
('20140721223232'),
('20140722164601'),
('20140814153449'),
('20140814203855'),
('20140815163922'),
('20140819153927'),
('20140820160048'),
('20140820161336'),
('20140820175446'),
('20140826193115'),
('20140903171050'),
('20140904163524'),
('20140909190021'),
('20140911152147'),
('20140911192911'),
('20141014175857'),
('20141015164429'),
('20141015212555'),
('20141016191008'),
('20141016192618'),
('20141016193002'),
('20141016200108'),
('20141017154222'),
('20141017213409'),
('20150305194727'),
('20150324165214'),
('20151029200824'),
('20160309191432'),
('20160309194007'),
('20160309194724'),
('20170111160452'),
('20201106150006');


