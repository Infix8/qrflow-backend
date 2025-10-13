--
-- PostgreSQL database dump
--

\restrict 6Auhee9gIl5NAIE9jQFCfDACjO2GfA3I8EL3EyOsw6hvc1IkwmwCyAF8RzyaQoc

-- Dumped from database version 15.14
-- Dumped by pg_dump version 15.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: qrflow_user
--

CREATE TABLE public.activity_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    club_id integer,
    action_type character varying(100) NOT NULL,
    entity_type character varying(100) NOT NULL,
    entity_id integer,
    description text NOT NULL,
    changes_json text,
    ip_address character varying(50),
    "timestamp" timestamp with time zone DEFAULT now()
);


ALTER TABLE public.activity_logs OWNER TO qrflow_user;

--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: qrflow_user
--

CREATE SEQUENCE public.activity_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.activity_logs_id_seq OWNER TO qrflow_user;

--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: qrflow_user
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: attendees; Type: TABLE; Schema: public; Owner: qrflow_user
--

CREATE TABLE public.attendees (
    id integer NOT NULL,
    event_id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    roll_number character varying(100) NOT NULL,
    branch character varying(100) NOT NULL,
    year integer NOT NULL,
    section character varying(10) NOT NULL,
    phone character varying(20),
    gender character varying(20),
    qr_token character varying(500),
    qr_generated boolean,
    qr_generated_at timestamp with time zone,
    email_sent boolean,
    email_sent_at timestamp with time zone,
    email_error text,
    checked_in boolean,
    checkin_time timestamp with time zone,
    checked_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.attendees OWNER TO qrflow_user;

--
-- Name: attendees_id_seq; Type: SEQUENCE; Schema: public; Owner: qrflow_user
--

CREATE SEQUENCE public.attendees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendees_id_seq OWNER TO qrflow_user;

--
-- Name: attendees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: qrflow_user
--

ALTER SEQUENCE public.attendees_id_seq OWNED BY public.attendees.id;


--
-- Name: clubs; Type: TABLE; Schema: public; Owner: qrflow_user
--

CREATE TABLE public.clubs (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    email character varying(255),
    phone character varying(20),
    created_at timestamp with time zone DEFAULT now(),
    active boolean
);


ALTER TABLE public.clubs OWNER TO qrflow_user;

--
-- Name: clubs_id_seq; Type: SEQUENCE; Schema: public; Owner: qrflow_user
--

CREATE SEQUENCE public.clubs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clubs_id_seq OWNER TO qrflow_user;

--
-- Name: clubs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: qrflow_user
--

ALTER SEQUENCE public.clubs_id_seq OWNED BY public.clubs.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: qrflow_user
--

CREATE TABLE public.events (
    id integer NOT NULL,
    club_id integer NOT NULL,
    created_by integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    date timestamp with time zone NOT NULL,
    venue character varying(255),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.events OWNER TO qrflow_user;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: qrflow_user
--

CREATE SEQUENCE public.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.events_id_seq OWNER TO qrflow_user;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: qrflow_user
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: qrflow_user
--

CREATE TABLE public.payments (
    id integer NOT NULL,
    event_id integer NOT NULL,
    attendee_id integer,
    razorpay_payment_id character varying(255) NOT NULL,
    razorpay_order_id character varying(255),
    razorpay_signature character varying(500),
    amount integer NOT NULL,
    currency character varying(10),
    status character varying(50) NOT NULL,
    customer_name character varying(255) NOT NULL,
    customer_email character varying(255) NOT NULL,
    customer_phone character varying(20),
    form_data text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    payment_captured_at timestamp with time zone
);


ALTER TABLE public.payments OWNER TO qrflow_user;

--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: qrflow_user
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payments_id_seq OWNER TO qrflow_user;

--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: qrflow_user
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: qrflow_user
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(255),
    club_id integer,
    role character varying(50),
    created_at timestamp with time zone DEFAULT now(),
    last_login timestamp with time zone,
    disabled boolean
);


ALTER TABLE public.users OWNER TO qrflow_user;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: qrflow_user
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO qrflow_user;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: qrflow_user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: attendees id; Type: DEFAULT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.attendees ALTER COLUMN id SET DEFAULT nextval('public.attendees_id_seq'::regclass);


--
-- Name: clubs id; Type: DEFAULT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.clubs ALTER COLUMN id SET DEFAULT nextval('public.clubs_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: qrflow_user
--

COPY public.activity_logs (id, user_id, club_id, action_type, entity_type, entity_id, description, changes_json, ip_address, "timestamp") FROM stdin;
1	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-08 05:29:22.641835+00
2	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-08 05:29:32.316285+00
3	1	\N	create_club	club	1	Created club: E_CELL	\N	\N	2025-10-08 05:31:02.668344+00
4	1	\N	create_user	user	2	Created user: E-CELL (Role: organizer)	\N	\N	2025-10-08 05:32:05.682254+00
5	1	\N	logout	user	1	User admin logged out	\N	\N	2025-10-08 05:32:26.245188+00
6	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-08 05:32:57.218541+00
7	2	\N	create_event	event	1	Created event: ILLUMINATE	\N	\N	2025-10-08 05:33:52.488751+00
8	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-08 05:34:09.616229+00
9	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-08 05:51:01.317758+00
10	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-08 05:52:30.702817+00
11	2	\N	resend_qr	attendee	2	Resent QR code to: Indra (indrakshith.reddy@gmail.com)	\N	\N	2025-10-08 06:09:39.107776+00
12	2	\N	resend_qr	attendee	1	Resent QR code to: pranay (pranaykumarreddy8888@gmail.com)	\N	\N	2025-10-08 06:09:59.251847+00
13	2	\N	resend_qr	attendee	1	Resent QR code to: pranay (pranaykumarreddy8888@gmail.com)	\N	\N	2025-10-08 06:10:18.246953+00
14	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-08 06:11:43.357932+00
15	2	\N	checkin_scan	attendee	2	Checked in: Indra (23K81A0522) via QR scan	\N	\N	2025-10-08 06:11:58.020975+00
16	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-08 07:04:31.653419+00
17	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-09 06:10:43.28804+00
18	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-09 06:24:37.342835+00
19	2	\N	logout	user	2	User E-CELL logged out	\N	\N	2025-10-09 08:17:18.194404+00
20	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-10 00:53:06.908889+00
21	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-10 17:03:31.45959+00
22	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 01:19:39.660358+00
23	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 01:33:09.412567+00
24	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 01:34:57.99612+00
25	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 01:36:34.657182+00
26	2	\N	logout	user	2	User E-CELL logged out	\N	\N	2025-10-11 01:56:54.295821+00
27	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 01:57:10.013312+00
28	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 03:04:37.381846+00
29	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 03:05:05.224963+00
30	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 03:05:15.113016+00
31	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 03:54:46.57895+00
32	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 03:57:44.447118+00
33	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 04:36:15.494916+00
34	1	\N	create_attendee	attendee	17	Created attendee: Darshil Mishra (24K81A05L7) for event: ILLUMINATE	\N	\N	2025-10-11 04:40:51.117715+00
35	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 04:55:42.910022+00
36	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 05:13:44.740209+00
37	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 05:56:29.902805+00
38	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 06:02:58.460987+00
39	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 06:15:36.823164+00
40	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 06:23:06.761335+00
41	2	\N	generate_qr	event	1	Generated QR codes for 1 attendees in event: ILLUMINATE	\N	\N	2025-10-11 06:23:40.388027+00
42	2	\N	checkin_scan	attendee	1	Checked in: pranay (23k81A0519) via QR scan	\N	\N	2025-10-11 06:23:48.793128+00
43	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 06:55:57.696124+00
44	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 10:47:47.869982+00
45	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 10:49:15.61828+00
46	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 10:49:26.524384+00
47	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 10:49:47.573927+00
48	1	\N	logout	user	1	User admin logged out	\N	\N	2025-10-11 10:50:09.104126+00
49	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 10:50:28.535728+00
50	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 10:52:15.60287+00
51	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 10:52:28.009343+00
52	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 11:35:13.600697+00
53	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-11 14:55:54.502322+00
54	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 14:57:18.061865+00
55	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 14:57:27.414913+00
56	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 16:15:10.067899+00
57	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-11 16:15:18.963422+00
58	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-11 23:02:08.152768+00
59	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-12 03:13:04.422859+00
60	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-12 03:31:08.763625+00
61	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-12 03:40:20.431309+00
62	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-12 03:46:11.93858+00
63	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-12 03:46:19.643538+00
64	1	\N	create_attendee	attendee	35	Created attendee: Aditi (24K81A6667) for event: ILLUMINATE	\N	\N	2025-10-12 03:49:13.152205+00
65	2	\N	resend_qr	attendee	35	Resent QR code to: Aditi (aditipathak052005@gmail.com)	\N	\N	2025-10-12 03:49:52.138159+00
66	2	\N	resend_qr	attendee	35	Resent QR code to: Aditi (aditipathak052005@gmail.com)	\N	\N	2025-10-12 03:49:54.268578+00
67	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-12 03:59:55.069848+00
68	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-12 04:02:49.587098+00
69	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-12 04:14:39.546433+00
70	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-12 08:48:45.398579+00
71	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-12 08:48:50.104537+00
72	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-12 14:03:07.199936+00
73	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-12 14:03:17.944467+00
74	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-13 00:19:10.6691+00
75	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-13 02:49:08.875205+00
76	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-13 02:49:16.795879+00
77	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-13 02:49:25.328144+00
78	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-13 03:18:14.700685+00
79	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-13 03:42:37.252073+00
80	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-13 03:42:46.513193+00
81	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-13 03:55:14.682662+00
82	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-13 03:56:35.905132+00
83	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-13 04:12:39.998329+00
84	1	\N	manual_sync	payment	\N	Manual payment sync triggered by admin	\N	\N	2025-10-13 05:02:07.480828+00
85	2	\N	logout	user	2	User E-CELL logged out	\N	\N	2025-10-13 05:08:28.024602+00
86	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-13 05:08:33.018939+00
87	2	\N	logout	user	2	User E-CELL logged out	\N	\N	2025-10-13 05:22:11.009277+00
88	2	\N	login	user	2	User E-CELL logged in	\N	\N	2025-10-13 05:22:18.558586+00
89	1	\N	login	user	1	User admin logged in	\N	\N	2025-10-13 05:25:07.680308+00
\.


--
-- Data for Name: attendees; Type: TABLE DATA; Schema: public; Owner: qrflow_user
--

COPY public.attendees (id, event_id, name, email, roll_number, branch, year, section, phone, gender, qr_token, qr_generated, qr_generated_at, email_sent, email_sent_at, email_error, checked_in, checkin_time, checked_by, created_at, updated_at) FROM stdin;
15	1	R Darshini	darshiniraju2007@gmail.com	24K81A05Q2	CSE	2	D	8919312692	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjE1LCJlbWFpbCI6ImRhcnNoaW5pcmFqdTIwMDdAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUEwNVEyIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMFQxNzozNzo1MS44NjQ0NjIiLCJleHAiOjE3NjA1MjI0MDB9.z_az1o0xUtBs8w4Q7PQP2sPNeFoJNyZeMI-QRilgs-s	t	2025-10-10 17:37:51.864609+00	t	2025-10-10 17:37:53.004825+00	\N	f	\N	\N	2025-10-10 17:37:51.859375+00	2025-10-13 05:01:10.464327+00
14	1	G Varsha	varshagoturi@gmail.com	23K81A7284	AI DS 	3	B	8328478762	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjE0LCJlbWFpbCI6InZhcnNoYWdvdHVyaUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTcyODQiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEwVDE1OjA3OjQyLjIzNjc4OSIsImV4cCI6MTc2MDUyMjQwMH0.SzJjE2C9baWZvDeKsPX6Npaa8msZcYakzSC7S07jWgk	t	2025-10-10 15:07:42.236931+00	t	2025-10-10 15:07:43.440449+00	\N	f	\N	\N	2025-10-10 15:07:42.230083+00	2025-10-13 05:01:10.466182+00
13	1	Bhavadesh Goud	bhavadesh.dyna@gmail.com	24K81A05L6	CSE	2	D	8977281375	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjEzLCJlbWFpbCI6ImJoYXZhZGVzaC5keW5hQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBMDVMNiIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTBUMTM6MDc6MzQuMzg2NTYxIiwiZXhwIjoxNzYwNTIyNDAwfQ.SwFJHJwwQgxSLRpQc9LJ2FKfp4lOLq8_DEs-lQfnycU	t	2025-10-10 13:07:34.386734+00	t	2025-10-10 13:07:35.674248+00	\N	f	\N	\N	2025-10-10 13:07:34.379189+00	2025-10-13 05:01:10.468527+00
12	1	Shaik Rafi	shaikrafi12387@gmail.com	23K81A66B9	CSM	3	B	9502897006	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjEyLCJlbWFpbCI6InNoYWlrcmFmaTEyMzg3QGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjNLODFBNjZCOSIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTBUMTI6MDc6MjkuOTY5NzAwIiwiZXhwIjoxNzYwNTIyNDAwfQ.XbNSVekRemXAK5-LVTqlaxM-qPv1zvnXH_Vd9sjujjo	t	2025-10-10 12:07:29.969856+00	t	2025-10-10 12:07:31.138642+00	\N	f	\N	\N	2025-10-10 12:07:29.961468+00	2025-10-13 05:01:10.471761+00
1	1	pranay	pranaykumarreddy8888@gmail.com	23k81A0519	CSE	3	A	7893887885	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjEsImVtYWlsIjoicHJhbmF5a3VtYXJyZWRkeTg4ODhAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM2s4MUEwNTE5IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0wOFQwNTo0OToxMS4yMDUyMDQiLCJleHAiOjE3NjA1MjI0MDB9.d526TyslfJQgLBCMIW6QIlCK4ZUs4X58z1JzzQB0P8I	t	2025-10-08 05:49:11.227734+00	t	2025-10-08 06:10:18.243457+00	\N	t	2025-10-11 06:23:48.78926+00	2	2025-10-08 05:49:11.168448+00	2025-10-13 05:01:10.49982+00
11	1	Suryamohan shastry	shruthishastry5@gmail.com	23K81A12C1	IT	3	B	09032145855	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjExLCJlbWFpbCI6InNocnV0aGlzaGFzdHJ5NUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTEyQzEiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEwVDEwOjM3OjI0LjY4MDk4MyIsImV4cCI6MTc2MDUyMjQwMH0.SdddwMopy1Pu8b0RZ3Lq5G8aoCpvgBnv5EjDvM640ww	t	2025-10-10 10:37:24.681116+00	t	2025-10-10 10:37:25.792186+00	\N	f	\N	\N	2025-10-10 10:37:24.67378+00	2025-10-13 05:01:10.474467+00
10	1	P Srujan Reddy 	srujanpusuluru@gmail.com	24K81A05Q0	CSE	2	D	7207630081	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjEwLCJlbWFpbCI6InNydWphbnB1c3VsdXJ1QGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBMDVRMCIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTBUMTA6Mzc6MjMuMzY3ODQwIiwiZXhwIjoxNzYwNTIyNDAwfQ.LmLf9-PvMUqJLPjSaKaYV-msPUhyNTqonVUrCLwmFXw	t	2025-10-10 10:37:23.367975+00	t	2025-10-10 10:37:24.667048+00	\N	f	\N	\N	2025-10-10 10:37:23.362726+00	2025-10-13 05:01:10.476391+00
9	1	BANDI NAVYA TEJA	navyateja.bandi@gmail.com	24K81A6675	CSE AI ML	2	B	8978764113	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjksImVtYWlsIjoibmF2eWF0ZWphLmJhbmRpQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBNjY3NSIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTBUMTA6MDc6MjEuNDE3NDM3IiwiZXhwIjoxNzYwNTIyNDAwfQ.JpR9JZ_d2G1zZquLCqx4e9Vvb5KgnYbL9nugfjhPeiY	t	2025-10-10 10:07:21.417653+00	t	2025-10-10 10:07:22.603388+00	\N	f	\N	\N	2025-10-10 10:07:21.410918+00	2025-10-13 05:01:10.479016+00
8	1	Velaga Bhavya Vara Githika	1705bhavya@gmail.com	24K81A66C6	CSE AIML	2	B	9182398850	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjgsImVtYWlsIjoiMTcwNWJoYXZ5YUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI0SzgxQTY2QzYiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEwVDEwOjA3OjIwLjIyODU0MyIsImV4cCI6MTc2MDUyMjQwMH0.Mc7pVxSiGVVXo-2mBUdonBDtmEXc_eaN7yLQiR--TQE	t	2025-10-10 10:07:20.228675+00	t	2025-10-10 10:07:21.404101+00	\N	f	\N	\N	2025-10-10 10:07:20.222621+00	2025-10-13 05:01:10.481712+00
7	1	MOHD ABRAR KHASIM	abrarkhasim2023@gmail.com	24K81A04B2	ECE	2	B	8919398641	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjcsImVtYWlsIjoiYWJyYXJraGFzaW0yMDIzQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBMDRCMiIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTBUMDk6Mzc6MTguMzQ1NzA1IiwiZXhwIjoxNzYwNTIyNDAwfQ.jKf1HodgYVtG3HKQRdLbuqPzfetLBX-bmga1XIEwi6k	t	2025-10-10 09:37:18.345843+00	t	2025-10-10 09:37:19.507028+00	\N	f	\N	\N	2025-10-10 09:37:18.338321+00	2025-10-13 05:01:10.483891+00
6	1	Rambhathini vaishnavi 	rambathinivaishnavi@gmail.com	23K81A66A1	CSM	3	B	8466963259	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjYsImVtYWlsIjoicmFtYmF0aGluaXZhaXNobmF2aUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTY2QTEiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEwVDA5OjM3OjE3LjEzMDYyMSIsImV4cCI6MTc2MDUyMjQwMH0.mwj_O7e4p_sVw9oIpFFOO9UmvvobNQiP8c-dRUaMPqw	t	2025-10-10 09:37:17.132753+00	t	2025-10-10 09:37:18.330085+00	\N	f	\N	\N	2025-10-10 09:37:17.124507+00	2025-10-13 05:01:10.485845+00
5	1	S Vahini	vahini7249@gmail.com	23K81A7256	AIDS	3	A	8247769806	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjUsImVtYWlsIjoidmFoaW5pNzI0OUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTcyNTYiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEwVDA5OjA3OjE1LjI2MTgzNSIsImV4cCI6MTc2MDUyMjQwMH0.AyoQk07eQGaaJMYYHPAqv0aPvqzmoUAZSquaUyo8rQo	t	2025-10-10 09:07:15.26198+00	t	2025-10-10 09:07:16.453487+00	\N	f	\N	\N	2025-10-10 09:07:15.256171+00	2025-10-13 05:01:10.487893+00
4	1	vrunimahi	vrunimahi@gmail.com	24K81A0526	CSE	2	A	8309491861	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQsImVtYWlsIjoidnJ1bmltYWhpQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBMDUyNiIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMDlUMTY6MzY6MjYuODk1NzkwIiwiZXhwIjoxNzYwNTIyNDAwfQ.tdvidUaUbU8jFMJCkU_n7L-aYwE06NY7cf-mOBr1fIM	t	2025-10-09 16:36:26.895974+00	t	2025-10-09 16:36:28.163054+00	\N	f	\N	\N	2025-10-09 16:36:26.888298+00	2025-10-13 05:01:10.490162+00
3	1	Tanish Padala	padalatanish30@gmail.com	23K81A7444	CSG	3	A	9299559837	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjMsImVtYWlsIjoicGFkYWxhdGFuaXNoMzBAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUE3NDQ0IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0wOFQxNTowNToxMy4zNTUyODgiLCJleHAiOjE3NjA1MjI0MDB9.VtojX6okidd1_px6uN5IEWVzx6rw_M47O72KeqT9D1c	t	2025-10-08 15:05:13.355482+00	t	2025-10-08 15:05:14.843309+00	\N	f	\N	\N	2025-10-08 15:05:13.345429+00	2025-10-13 05:01:10.493865+00
2	1	Indra	indrakshith.reddy@gmail.com	23K81A0522	CSE	3	A	8019213363	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjIsImVtYWlsIjoiaW5kcmFrc2hpdGgucmVkZHlAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUEwNTIyIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0wOFQwNTo1MjozMS40MzU2ODciLCJleHAiOjE3NjA1MjI0MDB9.dHWKQzXttDbEiVvXVv3uiRaTP3Fz25pFMkjI1ItECUg	t	2025-10-08 05:52:31.435838+00	t	2025-10-08 06:09:39.096353+00	\N	t	2025-10-08 06:11:58.01758+00	2	2025-10-08 05:52:31.42938+00	2025-10-13 05:01:10.497036+00
38	1	Akhila Samreddy 	akhilareddy2112@gmail.com	24321A0508	COMPUTER SCIENCE AND ENGINEERING 	2	A	7989728117	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjM4LCJlbWFpbCI6ImFraGlsYXJlZGR5MjExMkBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI0MzIxQTA1MDgiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEyVDA1OjQwOjA1LjczMDg5MyIsImV4cCI6MTc2MDUyMjQwMH0.Uj0q6zkxwECJOY_4fTUJmgxq8e3YRgqRlHXgInHHO0Y	t	2025-10-12 05:40:05.731039+00	t	2025-10-12 05:40:06.828707+00	\N	f	\N	\N	2025-10-12 05:40:05.725418+00	2025-10-13 05:01:10.400243+00
20	1	Dineshreddy Byreddy	byreddydineshreddy11@gmail.com	23K81A0416	ECE	3	A	8639418367	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjIwLCJlbWFpbCI6ImJ5cmVkZHlkaW5lc2hyZWRkeTExQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjNLODFBMDQxNiIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTFUMDY6MDI6NTkuMzgzMTkyIiwiZXhwIjoxNzYwNTIyNDAwfQ.KwwQJerDc6bgFUo9NHOxXTBBuDEwApmID5DJs4spCQk	t	2025-10-11 06:02:59.383787+00	t	2025-10-11 06:03:00.491346+00	\N	f	\N	\N	2025-10-11 06:02:59.376481+00	2025-10-13 05:01:10.453691+00
19	1	G snehith	snehithg72@gmail.com	24K81A6685	CSM	2	B	7729028368	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjE5LCJlbWFpbCI6InNuZWhpdGhnNzJAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUE2Njg1IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMVQwNTozODozMC40MzY3NTUiLCJleHAiOjE3NjA1MjI0MDB9.ULdSE_ed2L7DcRNXqyqows58xyUrRRjYh8gqBXDP7a4	t	2025-10-11 05:38:30.436894+00	t	2025-10-11 05:38:32.284111+00	\N	f	\N	\N	2025-10-11 05:38:30.43083+00	2025-10-13 05:01:10.45648+00
18	1	Ardha Sudhir	ardhasudhir@gmail.com	24K81A6604	CSM	2	A	8331837410	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjE4LCJlbWFpbCI6ImFyZGhhc3VkaGlyQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBNjYwNCIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTFUMDQ6NTU6NDMuODUwOTUwIiwiZXhwIjoxNzYwNTIyNDAwfQ.xPDf46t_t0UN6kfvGlBCZ6gHXo6oFzuG3rRVdcJHbuk	t	2025-10-11 04:55:43.851088+00	t	2025-10-11 04:55:45.075192+00	\N	f	\N	\N	2025-10-11 04:55:43.845196+00	2025-10-13 05:01:10.458487+00
16	1	Vancha Akshitha Reddy 	akshithareddyvancha@gmail.com	23K81A6662	CSM	3	A	8143573052	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjE2LCJlbWFpbCI6ImFrc2hpdGhhcmVkZHl2YW5jaGFAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUE2NjYyIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMVQwMjozODoxOS43MjcxNzkiLCJleHAiOjE3NjA1MjI0MDB9.-xblwDhi7tqVDS-JGunuIwmvQUYE3ZdKxYvHDV9J6wM	t	2025-10-11 02:38:19.727339+00	t	2025-10-11 02:38:20.908882+00	\N	f	\N	\N	2025-10-11 02:38:19.721831+00	2025-10-13 05:01:10.461269+00
21	1	Navya Burrewar	navyaburrewar@gmail.com	23K81A6615	CSM	3	A	8106809341	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjIxLCJlbWFpbCI6Im5hdnlhYnVycmV3YXJAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUE2NjE1IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMVQwNjowMzowMC41MDQ3NzAiLCJleHAiOjE3NjA1MjI0MDB9.wBwsU-v94b2WkXTawNb58Of1VQKcYCZ4o-ELRJZ2PF8	t	2025-10-11 06:03:00.504908+00	t	2025-10-11 06:03:01.595954+00	\N	f	\N	\N	2025-10-11 06:03:00.499125+00	2025-10-13 05:01:10.451007+00
61	1	E NAGA MANOJ 	kkp2053manoj@gmail.com	2311IT010055	INFORMATION TECHNOLOGY 	1	A	9281044486	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjYxLCJlbWFpbCI6ImtrcDIwNTNtYW5vakBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzMTFJVDAxMDA1NSIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTNUMDU6MDI6MDguNjA0NDc2IiwiZXhwIjoxNzYwNTIyNDAwfQ.UP0IJmQkfUCtAHbd7C7x5ierPHd3YHCo1Avo_vpCo5Y	t	2025-10-13 05:02:08.604681+00	t	2025-10-13 05:02:09.915162+00	\N	f	\N	\N	2025-10-13 05:02:08.59339+00	2025-10-13 05:02:08.603424+00
23	1	Aashritha Badampudi	badampudi.aashritha@gmail.com	23K81A6611	CSE AI AND ML	3	A	6309728804	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjIzLCJlbWFpbCI6ImJhZGFtcHVkaS5hYXNocml0aGFAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUE2NjExIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMVQwNjoxNTozNy43MzIxNzkiLCJleHAiOjE3NjA1MjI0MDB9.8AFt5jCWha2V6uHlTgSjF0f83VRk9G4ANH2rFE7rxv0	t	2025-10-11 06:15:37.732339+00	t	2025-10-11 06:15:38.843554+00	\N	f	\N	\N	2025-10-11 06:15:37.722016+00	2025-10-13 05:01:10.445416+00
22	1	Sudheer Kumar 	palli.sudheerkumar@gmail.com	23K81A0453	ECE	3	A	6304386459	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjIyLCJlbWFpbCI6InBhbGxpLnN1ZGhlZXJrdW1hckBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTA0NTMiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTExVDA2OjAzOjAxLjYxMTY2MiIsImV4cCI6MTc2MDUyMjQwMH0.RwDRAw3OLrhUltWe87-xeoFAzAmAtcmptafewF-obwQ	t	2025-10-11 06:03:01.611825+00	t	2025-10-11 06:03:02.680162+00	\N	f	\N	\N	2025-10-11 06:03:01.603992+00	2025-10-13 05:01:10.447689+00
63	1	Janvi Parkalwar	goudjanvi06@gmail.com	24K81A66F8	CSM	2	C	8208349952	Not Specified	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-10-13 05:07:29.920351+00	2025-10-13 05:07:29.920351+00
17	1	Darshil Mishra	darshilmishra388@gmail.com	24K81A05L7	CSE	2	D	7396439867	Male	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjE3LCJlbWFpbCI6ImRhcnNoaWxtaXNocmEzODhAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUEwNUw3IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMVQwNjoyMzozOS4yNjMwNjQiLCJleHAiOjE3NjA1MjI0MDB9.iaVjMBPrezWOOzslc7RezG5dWd_5XegItn8dgU7yaxA	t	2025-10-11 06:23:39.263187+00	t	2025-10-11 06:23:40.383598+00	\N	f	\N	\N	2025-10-11 04:40:51.111146+00	2025-10-11 06:23:39.260756+00
37	1	Sathwika	sathwikaarigela0709@gmail.com	24K81A6671	CSM	2	B	8075023509	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjM3LCJlbWFpbCI6InNhdGh3aWthYXJpZ2VsYTA3MDlAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUE2NjcxIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQwNToxMDowMi45NDczNTUiLCJleHAiOjE3NjA1MjI0MDB9.QMl4dSkqPiOnEnHQzRe-srj2Yp9TBnS0MwZB8jMZxAQ	t	2025-10-12 05:10:02.947513+00	t	2025-10-12 05:10:04.055652+00	\N	f	\N	\N	2025-10-12 05:10:02.937736+00	2025-10-13 05:01:10.405582+00
36	1	Vaishnavi Reddy	annadivaishu@gmail.com	23K81A0575	CSE	3	B	8143950833	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjM2LCJlbWFpbCI6ImFubmFkaXZhaXNodUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTA1NzUiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEyVDA0OjQwOjAwLjAzMTQ4MSIsImV4cCI6MTc2MDUyMjQwMH0.T44Nr6MWwyCMj4O-D8Se085dV132YAAAD3YCFjX5hB4	t	2025-10-12 04:40:00.031643+00	t	2025-10-12 04:40:01.173551+00	\N	f	\N	\N	2025-10-12 04:40:00.01212+00	2025-10-13 05:01:10.409963+00
34	1	Sai Teja Chilkuri	saitejachilkurrri@gmail.com	23K81A7411	COMPUTER SCIENCE AND DESIGN	3	G	9515540392	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjM0LCJlbWFpbCI6InNhaXRlamFjaGlsa3VycnJpQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjNLODFBNzQxMSIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMDM6MzE6MTAuMTI2NjQ5IiwiZXhwIjoxNzYwNTIyNDAwfQ.XKJq9T5j-kLGnCnvpG3ss9mRlMuLdjNnlDNog3Q2RT0	t	2025-10-12 03:31:10.126832+00	t	2025-10-12 03:31:11.236308+00	\N	f	\N	\N	2025-10-12 03:31:10.120931+00	2025-10-13 05:01:10.412951+00
33	1	Sathvika	dyavarishettysathvika@gmail.com	23K81A1214	INFORMATION TECHNOLOGY 	3	A	9182822084	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjMzLCJlbWFpbCI6ImR5YXZhcmlzaGV0dHlzYXRodmlrYUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTEyMTQiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTExVDE4OjA5OjI1LjM2ODY5NSIsImV4cCI6MTc2MDUyMjQwMH0.jsPr4sK4zmcnGDIzIrSQDz4pXbTLi7s8PaVonNw8Q_o	t	2025-10-11 18:09:25.368839+00	t	2025-10-11 18:09:26.441796+00	\N	f	\N	\N	2025-10-11 18:09:25.363136+00	2025-10-13 05:01:10.416015+00
32	1	Pulluri Harshitha 	pulluriharshitha90@gmail.com	23K81A1250	INFORMATION TECHNOLOGY 	3	A	9849320759	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjMyLCJlbWFpbCI6InB1bGx1cmloYXJzaGl0aGE5MEBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIzSzgxQTEyNTAiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTExVDE4OjA5OjIzLjM0MTQzNiIsImV4cCI6MTc2MDUyMjQwMH0.efCVpgyRRb41I4X_VNjjQ1i_nqqM7heDWG-HpGprLpA	t	2025-10-11 18:09:23.341574+00	t	2025-10-11 18:09:25.355457+00	\N	f	\N	\N	2025-10-11 18:09:23.334122+00	2025-10-13 05:01:10.418614+00
31	1	B Sankeerth kumar	sankeerth632@gmail.com	24K81A05D7	CSE	2	C	7981066040	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjMxLCJlbWFpbCI6InNhbmtlZXJ0aDYzMkBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI0SzgxQTA1RDciLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTExVDE3OjA5OjE4LjY1NTkzNSIsImV4cCI6MTc2MDUyMjQwMH0.Z1_W8o1KNmTKGUfDEW0lLo1yehK70Yura9nw4YFIX8M	t	2025-10-11 17:09:18.656072+00	t	2025-10-11 17:09:19.793478+00	\N	f	\N	\N	2025-10-11 17:09:18.651524+00	2025-10-13 05:01:10.420978+00
30	1	Sahasra daroori	daroorisahasra@gmail.com	24K81A6613	CSM	2	A	9492474677	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjMwLCJlbWFpbCI6ImRhcm9vcmlzYWhhc3JhQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBNjYxMyIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTFUMTc6MDk6MTcuMjk4MTg1IiwiZXhwIjoxNzYwNTIyNDAwfQ.Os72M_-H2IWSIvBtwBQzRSmrkakjrZl4Kch1rDA3t64	t	2025-10-11 17:09:17.298351+00	t	2025-10-11 17:09:18.639691+00	\N	f	\N	\N	2025-10-11 17:09:17.291583+00	2025-10-13 05:01:10.423612+00
29	1	Trisha Banerjee 	banerjeetrisha270504@gmail.com	22K81A0558	CSE	4	A	8328513726	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjI5LCJlbWFpbCI6ImJhbmVyamVldHJpc2hhMjcwNTA0QGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjJLODFBMDU1OCIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTFUMTQ6NTc6MjguMzUxOTYxIiwiZXhwIjoxNzYwNTIyNDAwfQ.WlDCFbHSKH84zN25XNX9jcgkEAqqWjRV5U87UnGVg4k	t	2025-10-11 14:57:28.352102+00	t	2025-10-11 14:57:30.181196+00	\N	f	\N	\N	2025-10-11 14:57:28.344894+00	2025-10-13 05:01:10.426699+00
28	1	SAI HARSHITH JUJJURI	saiharshith236@gmail.com	24K81A0455	ECE	2	A	9701519761	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjI4LCJlbWFpbCI6InNhaWhhcnNoaXRoMjM2QGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBMDQ1NSIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTFUMTQ6MDk6MDUuMjcxNjcyIiwiZXhwIjoxNzYwNTIyNDAwfQ.Zb-E9_Le7hz2qR4cXLpzIYXL6nGp7OO0P_Gr1EKWy5g	t	2025-10-11 14:09:05.271811+00	t	2025-10-11 14:09:06.488405+00	\N	f	\N	\N	2025-10-11 14:09:05.265528+00	2025-10-13 05:01:10.429137+00
27	1	TALARI SHRAVANI 	shravanitalari7@gmail.com	24K81A6658	CSM	2	A	9490702738	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjI3LCJlbWFpbCI6InNocmF2YW5pdGFsYXJpN0BnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI0SzgxQTY2NTgiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTExVDEwOjA4OjUwLjA3Nzg4OCIsImV4cCI6MTc2MDUyMjQwMH0.SfADd3A8y0Tlk5tDGJWcdPoeVdywVNAX9Ytmu2LNg-U	t	2025-10-11 10:08:50.078025+00	t	2025-10-11 10:08:51.94324+00	\N	f	\N	\N	2025-10-11 10:08:50.071436+00	2025-10-13 05:01:10.4316+00
26	1	Abhinav Shashank Viswanatha	abhinavshashank.v003@gmail.com	24K81A66C7	CSE AI AND ML	2	B	7995505923	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjI2LCJlbWFpbCI6ImFiaGluYXZzaGFzaGFuay52MDAzQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBNjZDNyIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTFUMDg6Mzg6NDMuODAyMDY4IiwiZXhwIjoxNzYwNTIyNDAwfQ.Xk9XmQ8guP_N1IKhbRWGOZNGWygIq4eN3wPxBccnF_A	t	2025-10-11 08:38:43.802258+00	t	2025-10-11 08:38:45.003075+00	\N	f	\N	\N	2025-10-11 08:38:43.795643+00	2025-10-13 05:01:10.434419+00
25	1	Sania 	saniax286@gmail.com	22K81A05Q6	CSE	4	D	08790643670	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjI1LCJlbWFpbCI6InNhbmlheDI4NkBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjIySzgxQTA1UTYiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTExVDA3OjM4OjM5LjA1MzExMiIsImV4cCI6MTc2MDUyMjQwMH0.VNGNZyU4tqRoKmt-4lf5SgJVXwkckB4qUg5Niqvpe04	t	2025-10-11 07:38:39.053281+00	t	2025-10-11 07:38:40.195002+00	\N	f	\N	\N	2025-10-11 07:38:39.048198+00	2025-10-13 05:01:10.437659+00
35	1	Aditi	aditipathak052005@gmail.com	24K81A6667	CSM	2	B	9032600481	Female	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjM1LCJlbWFpbCI6ImFkaXRpcGF0aGFrMDUyMDA1QGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBNjY2NyIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMDM6NDk6NTEuMDg0MTA4IiwiZXhwIjoxNzYwNTIyNDAwfQ.FG97UzttbiLQu31_KxjXRsaPL-p7DagJEeb5ovo_kg8	t	2025-10-12 03:49:51.084249+00	t	2025-10-12 03:49:54.264738+00	\N	f	\N	\N	2025-10-12 03:49:13.145756+00	2025-10-12 03:49:52.556748+00
24	1	Sriyan Rajesh Bolenwar	sriyan1234rrr@gmail.com	24K81A0458	ECE	2	A	07666773742	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjI0LCJlbWFpbCI6InNyaXlhbjEyMzRycnJAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUEwNDU4IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMVQwNjo1NTo1OC41Nzk1NTYiLCJleHAiOjE3NjA1MjI0MDB9.Bo08UEzI_0qH0cgK0vLBr-XYeGmzH-e4N8_4o9b43Yc	t	2025-10-11 06:55:58.579949+00	t	2025-10-11 06:55:59.832336+00	\N	f	\N	\N	2025-10-11 06:55:58.57276+00	2025-10-13 05:01:10.442941+00
64	1	Janvi Parkalwar	goudjanvi06@gmail.com	24K81A66F8	CSM	2	C	8208349952	Not Specified	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-10-13 05:07:48.099564+00	2025-10-13 05:07:48.099564+00
48	1	Abhiram Kasturi 	abhiramkasturi19@gmail.com	24K81A6627	CSM	2	A	9059227073	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQ4LCJlbWFpbCI6ImFiaGlyYW1rYXN0dXJpMTlAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUE2NjI3IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxMzo0MDo0Mi45NDk2MjMiLCJleHAiOjE3NjA1MjI0MDB9.0a6UWWZPfF2xLd80lSYcWHpRFi4hDjSFEgMKW6iFR_E	t	2025-10-12 13:40:42.949755+00	t	2025-10-12 13:40:44.094607+00	\N	f	\N	\N	2025-10-12 13:40:42.942532+00	2025-10-13 05:01:10.370851+00
47	1	VEGIRAJU MAHAVEER VARMA	mahaveervarma.vegiraju@gmail.com	25K85A6602	CSM	2	A	6301873506	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQ3LCJlbWFpbCI6Im1haGF2ZWVydmFybWEudmVnaXJhanVAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNUs4NUE2NjAyIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxMzoxMDozOS44NzMzOTciLCJleHAiOjE3NjA1MjI0MDB9.q_hzEJkt18GjyKi_c1NGUks-tzCayNdUXbBmpQu3EZE	t	2025-10-12 13:10:39.873534+00	t	2025-10-12 13:10:41.78448+00	\N	f	\N	\N	2025-10-12 13:10:39.866742+00	2025-10-13 05:01:10.37294+00
46	1	Mir Saaduddin Ali 	mirsaaduddinali@gmail.com	24K81A6638	CSM	2	A	8639475925	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQ2LCJlbWFpbCI6Im1pcnNhYWR1ZGRpbmFsaUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI0SzgxQTY2MzgiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEyVDEyOjEwOjM0Ljc2NTM3MCIsImV4cCI6MTc2MDUyMjQwMH0.2NUIgV4iTY9s92mxVF9uoZ-A_DlkCF1oJW9wsz8PpIs	t	2025-10-12 12:10:34.765509+00	t	2025-10-12 12:10:36.44725+00	\N	f	\N	\N	2025-10-12 12:10:34.755179+00	2025-10-13 05:01:10.375948+00
44	1	MANOJ SAI KAMMATI	kammatimanojsai@gmail.com	24K81A05N8	CSE	2	D	7075282316	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQ0LCJlbWFpbCI6ImthbW1hdGltYW5vanNhaUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI0SzgxQTA1TjgiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEyVDExOjEwOjI5LjE0MDU1NiIsImV4cCI6MTc2MDUyMjQwMH0.WYKsFY6l_JmGHHSkbqzEtQTL8Dn3JqtAKGAnBN9DGYE	t	2025-10-12 11:10:29.140698+00	t	2025-10-12 11:10:30.847066+00	\N	f	\N	\N	2025-10-12 11:10:29.134803+00	2025-10-13 05:01:10.381965+00
42	1	Punitha 	kandrapunitha@gamil.com	24K81A66F9	CSE AIML 	2	C	9963472360	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQyLCJlbWFpbCI6ImthbmRyYXB1bml0aGFAZ2FtaWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUE2NkY5IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQwOTo0MDoyMi40ODM5MzMiLCJleHAiOjE3NjA1MjI0MDB9.i6S0aE0ujHhDQwGAbSSgsEhqe3DDTtXCfW3-ywPhtQk	t	2025-10-12 09:40:22.484068+00	t	2025-10-12 09:40:23.677934+00	\N	f	\N	\N	2025-10-12 09:40:22.478702+00	2025-10-13 05:01:10.388634+00
41	1	Busa Reethusri 	busareethu@gmail.com	23K81A0415	ECE	3	A	9912157587	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQxLCJlbWFpbCI6ImJ1c2FyZWV0aHVAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUEwNDE1IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQwNzo0MDoxNC41NDg2ODQiLCJleHAiOjE3NjA1MjI0MDB9.KU_Pnbf-jH244lKreCil7B7sJKTxk006EYwnOQ07hFw	t	2025-10-12 07:40:14.548822+00	t	2025-10-12 07:40:15.711776+00	\N	f	\N	\N	2025-10-12 07:40:14.543464+00	2025-10-13 05:01:10.391156+00
39	1	Harika Pagindla 	pagindlaharikaharika@gmail.com	24321A0533	COMPUTER SCIENCE AND ENGINEERING 	2	A	8309132453	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjM5LCJlbWFpbCI6InBhZ2luZGxhaGFyaWthaGFyaWthQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjQzMjFBMDUzMyIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMDU6NDA6MDYuODQ0OTU0IiwiZXhwIjoxNzYwNTIyNDAwfQ.-Z95Vn5v_Y7X0KVC3S4Pcel5EEaXXoGfirxAWcJGcGo	t	2025-10-12 05:40:06.845104+00	t	2025-10-12 05:40:07.857039+00	\N	f	\N	\N	2025-10-12 05:40:06.836514+00	2025-10-13 05:01:10.39731+00
43	1	ARISETTI DHEERAJ KIRAN 	dheerajkiran2006@gmail.com	24K81A6672	CSM	2	B	7981334595	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQzLCJlbWFpbCI6ImRoZWVyYWpraXJhbjIwMDZAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUE2NjcyIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxMToxMDoyNy45NzgxNzciLCJleHAiOjE3NjA1MjI0MDB9.5T0Tz8azwZ4yFCXEX417gtzLbj8StStXVO77nRXrK-k	t	2025-10-12 11:10:27.980148+00	t	2025-10-12 11:10:29.126865+00	\N	f	\N	\N	2025-10-12 11:10:27.971784+00	2025-10-13 05:01:10.384015+00
40	1	KATTA MAHATHI 	mahathi701@gmail.com	24321A0560	CSE	2	A	8555014357	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQwLCJlbWFpbCI6Im1haGF0aGk3MDFAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNDMyMUEwNTYwIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQwNjo0MDoxMC42MDQ2OTEiLCJleHAiOjE3NjA1MjI0MDB9.Ek2AG2YiCj_aAVIR77swEhEscbeyXi6202edKlbyh_g	t	2025-10-12 06:40:10.604829+00	t	2025-10-12 06:40:11.755055+00	\N	f	\N	\N	2025-10-12 06:40:10.597876+00	2025-10-13 05:01:10.394792+00
60	1	Rohit Pranav Naidu 	naidurohitpranav@gmail.com	24K81A05P5	CSE	2	D	9000445828	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjYwLCJlbWFpbCI6Im5haWR1cm9oaXRwcmFuYXZAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUEwNVA1IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xM1QwMzo0MDo1Ny40Mzc0NjciLCJleHAiOjE3NjA1MjI0MDB9.T4taGayVX5Z7JPpyhTTtXWTOvPOgj0ywZWrNd-c-GDw	t	2025-10-13 03:40:57.437622+00	t	2025-10-13 03:40:58.472322+00	\N	f	\N	\N	2025-10-13 03:40:57.430714+00	2025-10-13 05:01:10.315007+00
59	1	Varsha Bikkineni	bikkinenivarsha667@gmail.com	24K81A05L0	CSE 	2	D	8712198661	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjU5LCJlbWFpbCI6ImJpa2tpbmVuaXZhcnNoYTY2N0BnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI0SzgxQTA1TDAiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEzVDAzOjQwOjU2LjEyOTcwNCIsImV4cCI6MTc2MDUyMjQwMH0.9bnqTEKKJDcuWbEJatmUc6VN7QbbsoDXEkUaZh3XN8k	t	2025-10-13 03:40:56.162948+00	t	2025-10-13 03:40:57.413098+00	\N	f	\N	\N	2025-10-13 03:40:56.09664+00	2025-10-13 05:01:10.332535+00
58	1	SAI HARI	saihari143702367@gmail.com	24K81A6615	CSM	2	A	9014303660	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjU4LCJlbWFpbCI6InNhaWhhcmkxNDM3MDIzNjdAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyNEs4MUE2NjE1IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxNzo0MTowNy40NjU2NTkiLCJleHAiOjE3NjA1MjI0MDB9.5VY4WeD-zUmdYhPnlghDv-c4SdN4RDsqFyAe-xg_lvk	t	2025-10-12 17:41:07.465792+00	t	2025-10-12 17:41:08.699849+00	\N	f	\N	\N	2025-10-12 17:41:07.459694+00	2025-10-13 05:01:10.335482+00
57	1	Deekshith raj soppari	sopparideekshithraj@gmail.com	22k81A0457	ELECTRONICS AND COMMUNICATION ENGINEERING 	4	A	9182283301	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjU3LCJlbWFpbCI6InNvcHBhcmlkZWVrc2hpdGhyYWpAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyMms4MUEwNDU3IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxNzo0MTowNC44OTc0ODMiLCJleHAiOjE3NjA1MjI0MDB9.5C6TJJpAvyP3AZfzWzYaV2TLY73UbXex8MAG9DWuGzk	t	2025-10-12 17:41:04.897631+00	t	2025-10-12 17:41:07.452016+00	\N	f	\N	\N	2025-10-12 17:41:04.891247+00	2025-10-13 05:01:10.337967+00
56	1	Sri vaishnavi puvvada 	srivaishnavipuvvada@gmail.com	22k81A0453	ELECTRONICS AND COMMUNICATION ENGINEERING 	4	A	9676685690	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjU2LCJlbWFpbCI6InNyaXZhaXNobmF2aXB1dnZhZGFAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyMms4MUEwNDUzIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxNzoxMTowMi42OTk0NDEiLCJleHAiOjE3NjA1MjI0MDB9.D3OrO0XaFGso_YwPJWlfg9TbcfdB3nDFp0LBevIDJWw	t	2025-10-12 17:11:02.699605+00	t	2025-10-12 17:11:03.83618+00	\N	f	\N	\N	2025-10-12 17:11:02.692027+00	2025-10-13 05:01:10.340953+00
55	1	Varshasri sayannagari	varshasrisayannagari@gmail.com	22k81A0455	ELECTRONICS AND COMMUNICATION ENGINEERING 	4	A	9030303988	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjU1LCJlbWFpbCI6InZhcnNoYXNyaXNheWFubmFnYXJpQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjJrODFBMDQ1NSIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMTc6MTE6MDAuODU4NzY3IiwiZXhwIjoxNzYwNTIyNDAwfQ.7DAQtn7dprNUuSc611yGJX71K6SyCevJAt5tR5rAJPw	t	2025-10-12 17:11:00.858915+00	t	2025-10-12 17:11:02.683451+00	\N	f	\N	\N	2025-10-12 17:11:00.851935+00	2025-10-13 05:01:10.342879+00
54	1	THATAVARTHI VENKATARAMANA 	venkataramana0609@gmail.com	24K81A0210	ELECTRICAL AND ELECTRONICS ENGINEERING 	2	A	9849501104	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjU0LCJlbWFpbCI6InZlbmthdGFyYW1hbmEwNjA5QGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBMDIxMCIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMTY6NDA6NTguNjU4ODgzIiwiZXhwIjoxNzYwNTIyNDAwfQ.0d7G48N4XTHVlHqbkvj34m49bvT8p_Bsu6Egtb7Hp5M	t	2025-10-12 16:40:58.659029+00	t	2025-10-12 16:40:59.790906+00	\N	f	\N	\N	2025-10-12 16:40:58.652509+00	2025-10-13 05:01:10.345435+00
53	1	Ande Akhilraj 	akhilrajande71@gmail.com	24K81A0214	ELECTRICAL AND ELECTRONICS ENGINEERING 	2	A	7981918509	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjUzLCJlbWFpbCI6ImFraGlscmFqYW5kZTcxQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBMDIxNCIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMTY6MTA6NTYuNDY3NjA3IiwiZXhwIjoxNzYwNTIyNDAwfQ.ZIZowne33bMnV21qYur-fl7vXkfzHuomk4o5RMT39HU	t	2025-10-12 16:10:56.467756+00	t	2025-10-12 16:10:57.503023+00	\N	f	\N	\N	2025-10-12 16:10:56.461828+00	2025-10-13 05:01:10.348068+00
52	1	R SNEHA	sneha.rameshwaram25@gmail.com	23K81A7253	AIDS	3	A	8142345729	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjUyLCJlbWFpbCI6InNuZWhhLnJhbWVzaHdhcmFtMjVAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUE3MjUzIiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxNjoxMDo1NC43Mjk1NjMiLCJleHAiOjE3NjA1MjI0MDB9.MDRmIqVQWdJDHIrCfosP7FfjCLtG7Z293gloY5j7NQo	t	2025-10-12 16:10:54.729699+00	t	2025-10-12 16:10:56.448264+00	\N	f	\N	\N	2025-10-12 16:10:54.722457+00	2025-10-13 05:01:10.350577+00
51	1	Balaji	sribalaji.dangeti@gmail.com	25K81A04D6	ECE	1	C	9032982759	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjUxLCJlbWFpbCI6InNyaWJhbGFqaS5kYW5nZXRpQGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjVLODFBMDRENiIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMTY6MTA6NTMuMTk4ODk0IiwiZXhwIjoxNzYwNTIyNDAwfQ.f-WMwMM9oJzKY2X-Fam9G-rJvK9hGPc-L4T-EPl-1W4	t	2025-10-12 16:10:53.199036+00	t	2025-10-12 16:10:54.714201+00	\N	f	\N	\N	2025-10-12 16:10:53.192513+00	2025-10-13 05:01:10.352425+00
50	1	Manasa	manasareddyeltepu16@gmail.com	23K81A1216	IT	3	A	7893445765	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjUwLCJlbWFpbCI6Im1hbmFzYXJlZGR5ZWx0ZXB1MTZAZ21haWwuY29tIiwicm9sbF9udW1iZXIiOiIyM0s4MUExMjE2IiwiaXNzdWVkX2F0IjoiMjAyNS0xMC0xMlQxNDo0MDo0Ny4xMjQ4NjQiLCJleHAiOjE3NjA1MjI0MDB9.cJ5d2BbaI8_Yb_YvtOexLbHTlSymKiEmavriSMjx0pw	t	2025-10-12 14:40:47.125486+00	t	2025-10-12 14:40:48.916728+00	\N	f	\N	\N	2025-10-12 14:40:47.116162+00	2025-10-13 05:01:10.355174+00
49	1	Khushi Singh 	khushisingh.040821@gmail.com	25k81a66f6	CSM 	1	C	8790197135	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQ5LCJlbWFpbCI6ImtodXNoaXNpbmdoLjA0MDgyMUBnbWFpbC5jb20iLCJyb2xsX251bWJlciI6IjI1azgxYTY2ZjYiLCJpc3N1ZWRfYXQiOiIyMDI1LTEwLTEyVDE0OjAzOjE4LjkwNjYwMyIsImV4cCI6MTc2MDUyMjQwMH0.quxFlpSZeXgmbVzgj6DykSUyD4h4_Y7rNAvMjM-9bXs	t	2025-10-12 14:03:18.906783+00	t	2025-10-12 14:03:20.043878+00	\N	f	\N	\N	2025-10-12 14:03:18.899915+00	2025-10-13 05:01:10.363173+00
45	1	HIMANI JOSHI	himanijoshi218@gmail.com	24K81A6689	CSM	2	B	6301090687	Not Specified	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJldmVudF9pZCI6MSwiYXR0ZW5kZWVfaWQiOjQ1LCJlbWFpbCI6ImhpbWFuaWpvc2hpMjE4QGdtYWlsLmNvbSIsInJvbGxfbnVtYmVyIjoiMjRLODFBNjY4OSIsImlzc3VlZF9hdCI6IjIwMjUtMTAtMTJUMTI6MTA6MzMuNjA5NTQ0IiwiZXhwIjoxNzYwNTIyNDAwfQ.VF6v7rXLgrZS4UlfXJ4MFo3X8XjguvNHeJWhr41OZLw	t	2025-10-12 12:10:33.609688+00	t	2025-10-12 12:10:34.746113+00	\N	f	\N	\N	2025-10-12 12:10:33.602792+00	2025-10-13 05:01:10.378669+00
\.


--
-- Data for Name: clubs; Type: TABLE DATA; Schema: public; Owner: qrflow_user
--

COPY public.clubs (id, name, description, email, phone, created_at, active) FROM stdin;
1	E_CELL	E_CELL at St. Martin's Engineering College (SMEC) is a student-driven initiative focused on fostering a vibrant startup culture and entrepreneurial environment on campus. The Entrepreneurship Cell is dedicated to empowering aspiring student entrepreneurs by promoting innovation, nurturing creative ideas, and providing resources for students interested in startups and business ventures.\nCore Objectives\n\n    Encourage and support students in turning their innovative ideas into viable business opportunities by offering guidance and mentorship.\n\nBuild an active startup ecosystem within the college that engages students in entrepreneurship-focused workshops, competitions, and speaker sessions, ensuring exposure to industry trends and startup practices.\n\nFacilitate networking and collaboration opportunities with successful entrepreneurs, mentors, industry experts, and the wider entrepreneurial community to develop essential entrepreneurial skills.\nActivities and Initiatives\n\n    Organizes events, ideation workshops, pitch competitions, and training sessions to boost practical entrepreneurial skills within the student community.\n\nProvides guidance, resources, and a supportive environment for students aiming to launch startups or become future business leaders.\n\nActs as a bridge between academic learning and real-world business applications, driving innovation on campus and inspiring students to pursue entrepreneurship as a career pathway.\n\nE_CELL at SMEC plays a key role in shaping the next generation of changemakers by nurturing entrepreneurship, supporting the development of practical business skills, and strengthening the startup ecosystem both within the college and beyond	ecell.smec@gmail.com	6304052967	2025-10-08 05:31:02.660853+00	t
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: qrflow_user
--

COPY public.events (id, club_id, created_by, name, description, date, venue, created_at, updated_at) FROM stdin;
1	1	2	ILLUMINATE	Entrepreneurship Workshop	2025-10-14 10:00:00+00	7301 LAB	2025-10-08 05:33:52.481248+00	2025-10-08 05:33:52.481248+00
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: qrflow_user
--

COPY public.payments (id, event_id, attendee_id, razorpay_payment_id, razorpay_order_id, razorpay_signature, amount, currency, status, customer_name, customer_email, customer_phone, form_data, created_at, updated_at, payment_captured_at) FROM stdin;
7	1	\N	pay_RQrzQVmJq3F38Q	\N		100	INR	captured	Indra	indrakshith.reddy@gmail.com	8019213363	{"college_name": "St. Martins Engineering college", "department": "CSE", "roll_number": "23K81A0522", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9989646581", "college_name": "St. Martins Engineering college", "department": "CSE", "email": "indrakshith.reddy@gmail.com", "name": "Indra", "phone": "8019213363", "roll_number": "23K81A0522", "year_of_study": "3"}}	2025-10-08 05:52:31.425341+00	2025-10-09 05:35:55.295147+00	2025-10-09 05:35:55.295566+00
6	1	\N	pay_RQefMJqWElu3hV	\N		100	INR	captured	pranay	pranaykumarreddy8888@gmail.com	7893887885	{"college_name": "smec", "department": "cse", "roll_number": "23k81A0519", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7893887885", "college_name": "smec", "department": "cse", "email": "pranaykumarreddy8888@gmail.com", "name": "pranay", "phone": "7893887885", "roll_number": "23k81A0519", "year_of_study": "3nd"}}	2025-10-08 05:49:11.135928+00	2025-10-08 16:35:19.199766+00	2025-10-08 16:35:19.200144+00
15	1	\N	pay_RRivE87RHYyxAN	\N		67000	INR	failed	BANDI NAVYA TEJA	navyateja.bandi@gmail.com	8978764113	{"college_name": "St Martin's Engineering College ", "department": "CSE AI ML", "roll_number": "24K81A6675", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7287883116", "college_name": "St Martin's Engineering College ", "department": "CSE AI ML", "email": "navyateja.bandi@gmail.com", "name": "BANDI NAVYA TEJA", "phone": "8978764113", "roll_number": "24K81A6675", "section": "B", "year_of_study": "2"}}	2025-10-10 10:07:22.607112+00	2025-10-10 10:07:22.607112+00	\N
18	1	\N	pay_RRlGw6TzNs3xol	\N		67000	INR	captured	Shaik Rafi	shaikrafi12387@gmail.com	9502897006	{"college_name": "ST MARTIN'S ENGINEERING COLLEGE", "department": "CSM", "roll_number": "23K81A66B9", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9346461850", "college_name": "ST MARTIN'S ENGINEERING COLLEGE", "department": "CSM", "email": "shaikrafi12387@gmail.com", "name": "Shaik Rafi", "phone": "9502897006", "referral_name": "DANDUGALA BALA VARSHITH\\ud83d\\udcaa\\u2764\\ufe0f", "roll_number": "23K81A66B9", "section": "B", "year_of_study": "3"}}	2025-10-10 12:07:29.953648+00	2025-10-11 11:38:56.403272+00	2025-10-11 11:38:56.403604+00
8	1	\N	pay_RR1L5st84tw0aK	\N		67000	INR	captured	Tanish Padala	padalatanish30@gmail.com	9299559837	{"college_name": "St. Martin's Engineering College ", "department": "CSG", "roll_number": "23K81A7444", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9299559837", "college_name": "St. Martin's Engineering College ", "department": "CSG", "email": "padalatanish30@gmail.com", "name": "Tanish Padala", "phone": "9299559837", "roll_number": "23K81A7444", "year_of_study": "3"}}	2025-10-08 15:05:13.33793+00	2025-10-09 14:36:21.386872+00	2025-10-09 14:36:21.38799+00
9	1	\N	pay_RRR6RVEdqi92D5	\N		67000	INR	captured	vrunimahi	vrunimahi@gmail.com	8309491861	{"college_name": "St.Martin's engineering college", "department": "CSE", "roll_number": "24K81A0526", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7013528514", "college_name": "St.Martin's engineering college", "department": "CSE", "email": "vrunimahi@gmail.com", "name": "vrunimahi", "phone": "8309491861", "referral_name": "G.Pranay", "roll_number": "24K81A0526", "section": "A", "year_of_study": "2nd"}}	2025-10-09 16:36:26.880986+00	2025-10-10 16:07:47.548994+00	2025-10-10 16:07:47.549341+00
11	1	\N	pay_RRiimjV7SbY1D8	\N		67000	INR	captured	Rambhathini vaishnavi 	rambathinivaishnavi@gmail.com	8466963259	{"college_name": "St.martins engineering college ", "department": "CSM", "roll_number": "23K81A66A1", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8466963259", "college_name": "St.martins engineering college ", "department": "CSM", "email": "rambathinivaishnavi@gmail.com", "name": "Rambhathini vaishnavi ", "phone": "8466963259", "referral_name": "Pranay", "roll_number": "23K81A66A1", "section": "B", "year_of_study": "3"}}	2025-10-10 09:37:17.119766+00	2025-10-11 09:08:46.85201+00	2025-10-11 09:08:46.852363+00
13	1	\N	pay_RRjFVMGqeBE8zW	\N		67000	INR	captured	Velaga Bhavya Vara Githika	1705bhavya@gmail.com	9182398850	{"college_name": "St. Martin's Engineering College ", "department": "CSE AIML", "roll_number": "24K81A66C6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9985326339", "college_name": "St. Martin's Engineering College ", "department": "CSE AIML", "email": "1705bhavya@gmail.com", "name": "Velaga Bhavya Vara Githika", "phone": "9182398850", "referral_name": "Sathwika", "roll_number": "24K81A66C6", "section": "B", "year_of_study": "2nd"}}	2025-10-10 10:07:20.219032+00	2025-10-11 09:38:48.518241+00	2025-10-11 09:38:48.51859+00
12	1	\N	pay_RRiX9GDN506iqz	\N		67000	INR	captured	MOHD ABRAR KHASIM	abrarkhasim2023@gmail.com	8919398641	{"college_name": "St. Martins Engineering College", "department": "ECE", "roll_number": "24K81A04B2", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7780113051", "college_name": "St. Martins Engineering College", "department": "ECE", "email": "abrarkhasim2023@gmail.com", "name": "MOHD ABRAR KHASIM", "phone": "8919398641", "roll_number": "24K81A04B2", "section": "B", "year_of_study": "2"}}	2025-10-10 09:37:18.333526+00	2025-10-11 09:08:46.854466+00	2025-10-11 09:08:46.85535+00
17	1	\N	pay_RRjXYKnvVHxup6	\N		67000	INR	captured	Suryamohan shastry	shruthishastry5@gmail.com	09032145855	{"college_name": "St.Martins Engineering College ", "department": "IT", "roll_number": "23K81A12C1", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9396580676", "college_name": "St.Martins Engineering College ", "department": "IT", "email": "shruthishastry5@gmail.com", "name": "Suryamohan shastry", "phone": "09032145855", "referral_name": "Bala varshith", "roll_number": "23K81A12C1", "section": "B", "year_of_study": "3"}}	2025-10-10 10:37:24.670471+00	2025-10-11 10:08:52.01063+00	2025-10-11 10:08:52.011041+00
14	1	\N	pay_RRiwVhFOmGa5Qx	\N		67000	INR	captured	BANDI NAVYA TEJA	navyateja.bandi@gmail.com	8978764113	{"college_name": "St Martin's Engineering College ", "department": "CSE AI ML", "roll_number": "24K81A6675", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7287883116", "college_name": "St Martin's Engineering College ", "department": "CSE AI ML", "email": "navyateja.bandi@gmail.com", "name": "BANDI NAVYA TEJA", "phone": "8978764113", "roll_number": "24K81A6675", "section": "B", "year_of_study": "2"}}	2025-10-10 10:07:21.407507+00	2025-10-11 09:38:48.522817+00	2025-10-11 09:38:48.523189+00
10	1	\N	pay_RRi6RwIGgFt0jb	\N		67000	INR	captured	S Vahini	vahini7249@gmail.com	8247769806	{"college_name": "St.Martin's Engineering College ", "department": "AIDS", "roll_number": "23K81A7256", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7337032872", "college_name": "St.Martin's Engineering College ", "department": "AIDS", "email": "vahini7249@gmail.com", "name": "S Vahini", "phone": "8247769806", "roll_number": "23K81A7256", "section": "A", "year_of_study": "3"}}	2025-10-10 09:07:15.252572+00	2025-10-11 08:38:45.079974+00	2025-10-11 08:38:45.080352+00
24	1	\N	pay_RS0H609UUEuxWf	\N		67000	INR	failed	Tanuja Golla	gollatanuja06@gmail.com	8977512806	{"college_name": "St Martin's Engineering College ", "department": "CSM ", "roll_number": "22K81A66C6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8977512806", "college_name": "St Martin's Engineering College ", "department": "CSM ", "email": "gollatanuja06@gmail.com", "name": "Tanuja Golla", "phone": "8977512806", "roll_number": "22K81A66C6", "section": "B", "year_of_study": "4"}}	2025-10-11 02:38:19.711826+00	2025-10-11 03:05:16.037502+00	\N
30	1	\N	pay_RS3PpYUlvFYFoz	\N		67000	INR	captured	Sudheer Kumar 	palli.sudheerkumar@gmail.com	6304386459	{"college_name": "St.Martins Engineering college ", "department": "ECE", "roll_number": "23K81A0453", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8790534649", "college_name": "St.Martins Engineering college ", "department": "ECE", "email": "Palli.sudheerkumar@gmail.com", "name": "Sudheer Kumar ", "phone": "6304386459", "referral_name": "Bala Varshith ", "roll_number": "23K81A0453", "section": "A", "year_of_study": "3"}}	2025-10-11 06:03:01.600349+00	2025-10-12 05:40:07.921982+00	2025-10-12 05:40:07.922389+00
21	1	\N	pay_RRna8atQqoqgep	\N		67000	INR	failed	Aashritha Badampudi	badampudi.aashritha@gmail.com	6309728804	{"college_name": "St. Martin's Engineering Collage ", "department": "CSE AI and ML", "roll_number": "23K81A6611", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9705166704", "college_name": "St. Martin's Engineering Collage ", "department": "CSE AI and ML", "email": "badampudi.aashritha@gmail.com", "name": "Aashritha Badampudi", "phone": "6309728804", "roll_number": "23K81A6611", "section": "A", "year_of_study": "3rd"}}	2025-10-10 14:37:40.709429+00	2025-10-10 14:37:40.709429+00	\N
22	1	\N	pay_RRoJxza5K9T4Df	\N		67000	INR	captured	G Varsha	varshagoturi@gmail.com	8328478762	{"college_name": "St.Martin\\u2019s Engineering college ", "department": "AI DS ", "roll_number": "23K81A7284", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8328478762", "college_name": "St.Martin\\u2019s Engineering college ", "department": "AI DS ", "email": "varshagoturi@gmail.com", "name": "G Varsha", "phone": "8328478762", "referral_name": "Vishalakshi ", "roll_number": "23K81A7284", "section": "B", "year_of_study": "3"}}	2025-10-10 15:07:42.226099+00	2025-10-11 14:39:08.927854+00	2025-10-11 14:39:08.928203+00
26	1	\N	pay_RS2NkluXFZrlPy	\N		67000	INR	captured	Ardha Sudhir	ardhasudhir@gmail.com	8331837410	{"college_name": "St. Martin's Engineering College", "department": "CSM", "roll_number": "24K81A6604", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8331837438", "college_name": "St. Martin's Engineering College", "department": "CSM", "email": "ardhasudhir@gmail.com", "name": "Ardha Sudhir", "phone": "8331837410", "referral_name": "Pranay", "roll_number": "24K81A6604", "section": "A", "year_of_study": "2ND"}}	2025-10-11 04:55:43.841482+00	2025-10-12 04:40:01.242478+00	2025-10-12 04:40:01.242925+00
16	1	\N	pay_RRjYxbG3jpvCZz	\N		67000	INR	captured	P Srujan Reddy 	srujanpusuluru@gmail.com	7207630081	{"college_name": "St.Martins Engineering college ", "department": "CSE", "roll_number": "24K81A05Q0", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9885648466", "college_name": "St.Martins Engineering college ", "department": "CSE", "email": "srujanpusuluru@gmail.com", "name": "P Srujan Reddy ", "phone": "7207630081", "referral_name": "A.pranay", "roll_number": "24K81A05Q0", "section": "D", "year_of_study": "2"}}	2025-10-10 10:37:23.359034+00	2025-10-11 10:08:52.00672+00	2025-10-11 10:08:52.007073+00
23	1	\N	pay_RRqgI7mZEtDiCe	\N		67000	INR	captured	R Darshini	darshiniraju2007@gmail.com	8919312692	{"college_name": "St.Martin's Engineering College ", "department": "CSE", "roll_number": "24K81A05Q2", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9391025673", "college_name": "St.Martin's Engineering College ", "department": "CSE", "email": "darshiniraju2007@gmail.com", "name": "R Darshini", "phone": "8919312692", "referral_name": "A.Pranay", "roll_number": "24K81A05Q2", "section": "D", "year_of_study": "II"}}	2025-10-10 17:37:51.853904+00	2025-10-11 17:09:19.844403+00	2025-10-11 17:09:19.844731+00
29	1	\N	pay_RS3ZIM0QtRitwl	\N		67000	INR	captured	Navya Burrewar	navyaburrewar@gmail.com	8106809341	{"college_name": "st.martins engineering college ", "department": "CSM", "roll_number": "23K81A6615", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7893445765", "college_name": "st.martins engineering college ", "department": "CSM", "email": "navyaburrewar@gmail.com", "name": "Navya Burrewar", "phone": "8106809341", "referral_name": "A.Pranay ", "roll_number": "23K81A6615", "section": "A", "year_of_study": "3"}}	2025-10-11 06:03:00.495276+00	2025-10-12 05:40:07.9193+00	2025-10-12 05:40:07.919675+00
25	1	\N	pay_RS01eC2iWo2P3E	\N		67000	INR	captured	Vancha Akshitha Reddy 	akshithareddyvancha@gmail.com	8143573052	{"college_name": "ST MARTIN'S ENGINEERING COLLEGE ", "department": "CSM", "roll_number": "23K81A6662", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8143573052", "college_name": "ST MARTIN'S ENGINEERING COLLEGE ", "department": "CSM", "email": "akshithareddyvancha@gmail.com", "name": "Vancha Akshitha Reddy ", "phone": "8143573052", "roll_number": "23K81A6662", "section": "A", "year_of_study": "3rd"}}	2025-10-11 02:38:19.715187+00	2025-10-12 02:09:53.075144+00	2025-10-12 02:09:53.07549+00
19	1	\N	pay_RRmG1BHkg7k5HV	\N		67000	INR	captured	Bhavadesh Goud	bhavadesh.dyna@gmail.com	8977281375	{"college_name": "St. Martin's Engineering College", "department": "CSE", "roll_number": "24K81A05L6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9618961875", "college_name": "St. Martin's Engineering College", "department": "CSE", "email": "bhavadesh.dyna@gmail.com", "name": "Bhavadesh Goud", "phone": "8977281375", "referral_name": "Bhavadesh", "roll_number": "24K81A05L6", "section": "D", "year_of_study": "2"}}	2025-10-10 13:07:34.374151+00	2025-10-11 12:38:59.78787+00	2025-10-11 12:38:59.78819+00
20	1	\N	pay_RRm8jqrMUTbwd3	\N		67000	INR	captured	Darshil Mishra	darshilmishra388@email.com	7396439867	{"college_name": "St. Martin's Engineering College", "department": "CSE", "roll_number": "24K81A05L6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8977281375", "college_name": "St. Martin's Engineering College", "department": "CSE", "email": "darshilmishra388@email.com", "name": "Darshil Mishra", "phone": "7396439867", "referral_name": "Darshil", "roll_number": "24K81A05L6", "section": "D", "year_of_study": "2"}}	2025-10-10 13:07:35.677766+00	2025-10-11 12:38:59.790534+00	2025-10-11 12:38:59.790899+00
28	1	\N	pay_RS3brrlkY7exEh	\N		67000	INR	captured	Dineshreddy Byreddy	byreddydineshreddy11@gmail.com	8639418367	{"college_name": "St martins engineering college", "department": "Ece", "roll_number": "23K81A0416", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9912157587", "college_name": "St martins engineering college", "department": "Ece", "email": "byreddydineshreddy11@gmail.com", "name": "Dineshreddy Byreddy", "phone": "8639418367", "referral_name": "Bala varshith", "roll_number": "23K81A0416", "section": "A", "year_of_study": "3"}}	2025-10-11 06:02:59.372257+00	2025-10-12 05:40:07.916091+00	2025-10-12 05:40:07.916465+00
35	1	\N	pay_RS78P8AGqvczAE	\N		67000	INR	failed	J Abhign	janardhanabhign@gmail.com	9059911622	{"college_name": "St Martin's engineering college", "department": "CSE", "roll_number": "24K81A05M5", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9032803481", "college_name": "St Martin's engineering college", "department": "CSE", "email": "janardhanabhign@gmail.com", "name": "J Abhign", "phone": "9059911622", "referral_name": "G.pranay", "roll_number": "24K81A05M5", "section": "D", "year_of_study": "2"}}	2025-10-11 09:38:48.456512+00	2025-10-11 09:38:48.456512+00	\N
42	1	\N	pay_RSF4FPk51PAe7G	\N		67000	INR	captured	Aditi	aditipathak052005@gmail.com	9032600481	{"college_name": "St.Martin's Engineering College", "department": "CSM", "roll_number": "24K81A6667", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9182629371", "college_name": "St.Martin's Engineering College", "department": "CSM", "email": "aditipathak052005@gmail.com", "name": "Aditi", "phone": "9032600481", "roll_number": "24K81A6667", "section": "B", "year_of_study": "2"}}	2025-10-11 17:09:18.643313+00	2025-10-12 16:40:59.883461+00	2025-10-12 16:40:59.883824+00
39	1	\N	pay_RSBls7ud6lDBVD	\N		67000	INR	failed	SAI HARSHITH JUJJURI	saiharshith236@gmail.com	9701519761	{"college_name": "ST.MARTIN'S ENGINEERING COLLEGE", "department": "ECE", "roll_number": "24K81A0455", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9701519761", "college_name": "ST.MARTIN'S ENGINEERING COLLEGE", "department": "ECE", "email": "saiharshith236@gmail.com", "name": "SAI HARSHITH JUJJURI", "phone": "9701519761", "roll_number": "24K81A0455", "section": "A", "year_of_study": "2"}}	2025-10-11 14:09:06.491684+00	2025-10-11 14:09:06.491684+00	\N
38	1	\N	pay_RSBnl7UUjaOXyj	\N		67000	INR	captured	SAI HARSHITH JUJJURI	saiharshith236@gmail.com	9701519761	{"college_name": "ST.MARTIN'S ENGINEERING COLLEGE", "department": "ECE", "roll_number": "24K81A0455", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9701519761", "college_name": "ST.MARTIN'S ENGINEERING COLLEGE", "department": "ECE", "email": "saiharshith236@gmail.com", "name": "SAI HARSHITH JUJJURI", "phone": "9701519761", "roll_number": "24K81A0455", "section": "A", "year_of_study": "2"}}	2025-10-11 14:09:05.260862+00	2025-10-12 13:40:44.163348+00	2025-10-12 13:40:44.163724+00
31	1	\N	pay_RS3skqDIumn5VG	\N		67000	INR	captured	Aashritha Badampudi	badampudi.aashritha@gmail.com	6309728804	{"college_name": "St. Martin's Engineering Collage ", "department": "CSE AI and ML", "roll_number": "23K81A6611", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9705166704", "college_name": "St. Martin's Engineering Collage ", "department": "CSE AI and ML", "email": "badampudi.aashritha@gmail.com", "name": "Aashritha Badampudi", "phone": "6309728804", "roll_number": "23K81A6611", "section": "A", "year_of_study": "3"}}	2025-10-11 06:15:37.714774+00	2025-10-12 05:40:07.91324+00	2025-10-12 05:40:07.913892+00
34	1	\N	pay_RS6Bd2DlqNFwFG	\N		67000	INR	captured	Abhinav Shashank Viswanatha	abhinavshashank.v003@gmail.com	7995505923	{"college_name": "St. Martin's Engineering College ", "department": "CSE AI and ML", "roll_number": "24K81A66C7", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9703398877", "college_name": "St. Martin's Engineering College ", "department": "CSE AI and ML", "email": "abhinavshashank.v003@gmail.com", "name": "Abhinav Shashank Viswanatha", "phone": "7995505923", "referral_name": "sathwika", "roll_number": "24K81A66C7", "section": "B", "year_of_study": "2"}}	2025-10-11 08:38:43.789806+00	2025-10-12 08:10:17.416172+00	2025-10-12 08:10:17.416513+00
32	1	\N	pay_RS4TWamGYEHGlE	\N		67000	INR	captured	Sriyan Rajesh Bolenwar	sriyan1234rrr@gmail.com	07666773742	{"college_name": "st. martins engineering college", "department": "ECE", "roll_number": "24K81A0458", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9579143720", "college_name": "st. martins engineering college", "department": "ECE", "email": "sriyan1234rrr@gmail.com", "name": "Sriyan Rajesh Bolenwar", "phone": "07666773742", "roll_number": "24K81A0458", "section": "A", "year_of_study": "2"}}	2025-10-11 06:55:58.568475+00	2025-10-12 06:40:11.81655+00	2025-10-12 06:40:11.816879+00
41	1	\N	pay_RSF4fRZuxfjn8i	\N		67000	INR	captured	Sahasra daroori	daroorisahasra@gmail.com	9492474677	{"college_name": "St.Martins engineering college ", "department": "CSM", "roll_number": "24K81A6613", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8790092020", "college_name": "St.Martins engineering college ", "department": "CSM", "email": "daroorisahasra@gmail.com", "name": "Sahasra daroori", "phone": "9492474677", "roll_number": "24K81A6613", "section": "A", "year_of_study": "2"}}	2025-10-11 17:09:17.287983+00	2025-10-12 16:40:59.878798+00	2025-10-12 16:40:59.879307+00
37	1	\N	pay_RS7VZDCSpWz5qe	\N		67000	INR	failed	TALARI SHRAVANI 	shravanitalari7@gmail.com	9490702738	{"college_name": "St. Martin's Engineering College", "department": "CSM", "roll_number": "24K81A6658", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9059989660", "college_name": "St. Martin's Engineering College", "department": "CSM", "email": "shravanitalari7@gmail.com", "name": "TALARI SHRAVANI ", "phone": "9490702738", "roll_number": "24K81A6658", "section": "A", "year_of_study": "2"}}	2025-10-11 10:08:51.947747+00	2025-10-11 10:08:51.947747+00	\N
33	1	\N	pay_RS4zporgcNrp8H	\N		67000	INR	captured	Sania 	saniax286@gmail.com	08790643670	{"college_name": "St. Martin's Engineering College ", "department": "CSE", "roll_number": "22K81A05Q6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "08790643670", "college_name": "St. Martin's Engineering College ", "department": "CSE", "email": "saniax286@gmail.com", "name": "Sania ", "phone": "08790643670", "referral_name": "Khaja", "roll_number": "22K81A05Q6", "section": "D", "year_of_study": "4"}}	2025-10-11 07:38:39.044411+00	2025-10-12 07:10:13.566932+00	2025-10-12 07:10:13.567311+00
36	1	\N	pay_RS7imOIw8nLk4M	\N		67000	INR	captured	TALARI SHRAVANI 	shravanitalari7@gmail.com	9490702738	{"college_name": "St. Martin's Engineering College", "department": "CSM", "roll_number": "24K81A6658", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9059989660", "college_name": "St. Martin's Engineering College", "department": "CSM", "email": "shravanitalari7@gmail.com", "name": "TALARI SHRAVANI ", "phone": "9490702738", "roll_number": "24K81A6658", "section": "A", "year_of_study": "2"}}	2025-10-11 10:08:50.066349+00	2025-10-12 09:40:23.732949+00	2025-10-12 09:40:23.733327+00
27	1	\N	pay_RS39gRHDj4jsFC	\N		67000	INR	captured	G snehith	snehithg72@gmail.com	7729028368	{"college_name": "st martin engineering college ", "department": "CSM", "roll_number": "24K81A6685", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7729028368", "college_name": "st martin engineering college ", "department": "CSM", "email": "snehithg72@gmail.com", "name": "G snehith", "phone": "7729028368", "referral_name": "Rama krishna", "roll_number": "24K81A6685", "section": "B", "year_of_study": "2"}}	2025-10-11 05:38:30.426325+00	2025-10-12 05:10:04.118472+00	2025-10-12 05:10:04.12126+00
48	1	\N	pay_RSQuNRwaYWYVIw	\N		67000	INR	captured	Sathwika	sathwikaarigela0709@gmail.com	8075023509	{"college_name": "St. Martin's Engineering college", "department": "Csm", "roll_number": "24K81A6671", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8075023509", "college_name": "St. Martin's Engineering college", "department": "Csm", "email": "Sathwikaarigela0709@gmail.com", "name": "Sathwika", "phone": "8075023509", "referral_name": "Sathwika", "roll_number": "24K81A6671", "section": "B", "year_of_study": "2"}}	2025-10-12 05:10:02.931872+00	2025-10-13 04:32:22.79858+00	2025-10-13 04:32:22.799144+00
54	1	\N	pay_RSVlwbESPcTWIJ	\N		67000	INR	captured	Punitha 	kandrapunitha@gamil.com	9963472360	{"college_name": "St.martins engineering college ", "department": "CSE AIML ", "roll_number": "24K81A66F9", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9704650085", "college_name": "St.martins engineering college ", "department": "CSE AIML ", "email": "kandrapunitha@gamil.com", "name": "Punitha ", "phone": "9963472360", "roll_number": "24K81A66F9", "section": "C", "year_of_study": "2"}}	2025-10-12 09:40:22.473744+00	2025-10-13 07:02:32.38986+00	2025-10-13 07:02:32.390191+00
45	1	\N	pay_RSFngTjKu4V7l5	\N		67000	INR	captured	Sathvika	dyavarishettysathvika@gmail.com	9182822084	{"college_name": "St.Martins engineering college ", "department": "Information Technology ", "roll_number": "23K81A1214", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9110382854", "college_name": "St.Martins engineering college ", "department": "Information Technology ", "email": "dyavarishettysathvika@gmail.com", "name": "Sathvika", "phone": "9182822084", "referral_name": "A.Pranay ", "roll_number": "23K81A1214", "section": "A", "year_of_study": "3"}}	2025-10-11 18:09:25.358927+00	2025-10-12 17:41:08.783722+00	2025-10-12 17:41:08.784069+00
51	1	\N	pay_RSSoOyhwmk05Kb	\N		67000	INR	captured	KATTA MAHATHI 	mahathi701@gmail.com	8555014357	{"college_name": "BHOJ REDDY ENGINEERING COLLEGE FOR WOMEN ", "department": "CSE", "roll_number": "24321A0560", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8309132453", "college_name": "BHOJ REDDY ENGINEERING COLLEGE FOR WOMEN ", "department": "CSE", "email": "Mahathi701@gmail.com", "name": "KATTA MAHATHI ", "phone": "8555014357", "roll_number": "24321A0560", "year_of_study": "2"}}	2025-10-12 06:40:10.592489+00	2025-10-13 06:02:28.461195+00	2025-10-13 06:02:28.461965+00
47	1	\N	pay_RSQUQWJRai3Dh7	\N		67000	INR	captured	Vaishnavi Reddy	annadivaishu@gmail.com	8143950833	{"college_name": "St Martin's Engineering College ", "department": "Cse", "roll_number": "23K81A0575", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8143950833", "college_name": "St Martin's Engineering College ", "department": "Cse", "email": "annadivaishu@gmail.com", "name": "Vaishnavi Reddy", "phone": "8143950833", "referral_name": "A.Pranay", "roll_number": "23K81A0575", "section": "B", "year_of_study": "3"}}	2025-10-12 04:39:59.999836+00	2025-10-13 04:02:20.12431+00	2025-10-13 04:02:20.124647+00
40	1	\N	pay_RSCpzrxYF1wn79	\N		67000	INR	captured	Trisha Banerjee 	banerjeetrisha270504@gmail.com	8328513726	{"college_name": "St. Martin's Engineering College ", "department": "CSE", "roll_number": "22K81A0558", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8328513726", "college_name": "St. Martin's Engineering College ", "department": "CSE", "email": "banerjeetrisha270504@gmail.com", "name": "Trisha Banerjee ", "phone": "8328513726", "referral_name": "Khaja", "roll_number": "22K81A0558", "section": "A", "year_of_study": "4"}}	2025-10-11 14:57:28.339919+00	2025-10-12 14:40:48.989343+00	2025-10-12 14:40:48.989695+00
52	1	\N	pay_RSST7mtrGcGWeD	\N		67000	INR	failed	Kk	snsnsnsnsn@gmail.com	9999999999	{"college_name": "smec", "department": "Cse", "roll_number": "23k81a0680", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9999999999", "college_name": "smec", "department": "Cse", "email": "snsnsnsnsn@gmail.com", "name": "Kk", "phone": "9999999999", "roll_number": "23k81a0680", "year_of_study": "3"}}	2025-10-12 06:40:11.759084+00	2025-10-12 06:40:11.759084+00	\N
50	1	\N	pay_RSRSOH48JqGJPT	\N		67000	INR	captured	Harika Pagindla 	pagindlaharikaharika@gmail.com	8309132453	{"college_name": "Bhojreddy Engineering College for Women ", "department": "Computer science and engineering ", "roll_number": "24321A0533", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7671921006", "college_name": "Bhojreddy Engineering College for Women ", "department": "Computer science and engineering ", "email": "pagindlaharikaharika@gmail.com", "name": "Harika Pagindla ", "phone": "8309132453", "roll_number": "24321A0533", "year_of_study": "2"}}	2025-10-12 05:40:06.832836+00	2025-10-13 05:02:23.955516+00	2025-10-13 05:02:23.955893+00
44	1	\N	pay_RSFssgEQM7lyYD	\N		67000	INR	captured	Pulluri Harshitha 	pulluriharshitha90@gmail.com	9849320759	{"college_name": "St Martin's Engineering College ", "department": "Information Technology ", "roll_number": "23K81A1250", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9581652785", "college_name": "St Martin's Engineering College ", "department": "Information Technology ", "email": "Pulluriharshitha90@gmail.com", "name": "Pulluri Harshitha ", "phone": "9849320759", "referral_name": "A.Pranay", "roll_number": "23K81A1250", "section": "A", "year_of_study": "3"}}	2025-10-11 18:09:23.328072+00	2025-10-12 17:41:08.781225+00	2025-10-12 17:41:08.781563+00
46	1	\N	pay_RSPUYe4JlBgmkO	\N		67000	INR	captured	Sai Teja Chilkuri	saitejachilkurrri@gmail.com	9515540392	{"college_name": "St.Martin's Engineering College", "department": "Computer Science and Design", "roll_number": "23K81A7411", "emergency_contact": "", "original_notes": {"alternative_phone_number": "6301951224", "college_name": "St.Martin's Engineering College", "department": "Computer Science and Design", "email": "saitejachilkurrri@gmail.com", "name": "Sai Teja Chilkuri", "phone": "9515540392", "referral_name": "PAGADOJU SADHVIK", "roll_number": "23K81A7411", "section": "CSG", "year_of_study": "3"}}	2025-10-12 03:31:10.115395+00	2025-10-13 03:11:42.527466+00	2025-10-13 03:11:42.527788+00
43	1	\N	pay_RSEnc6Q9qjfttY	\N		67000	INR	captured	B Sankeerth kumar	sankeerth632@gmail.com	7981066040	{"college_name": "St Martin's engeneering college", "department": "CSE", "roll_number": "24K81A05D7", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9502965041", "college_name": "St Martin's engeneering college", "department": "CSE", "email": "sankeerth632@gmail.com", "name": "B Sankeerth kumar", "phone": "7981066040", "referral_name": "Abdul Sohail ", "roll_number": "24K81A05D7", "section": "C", "year_of_study": "2"}}	2025-10-11 17:09:18.646646+00	2025-10-12 16:40:59.886983+00	2025-10-12 16:40:59.887399+00
49	1	\N	pay_RSRaFu9ohSr2RW	\N		67000	INR	captured	Akhila Samreddy 	akhilareddy2112@gmail.com	7989728117	{"college_name": "Bhojreddy Engineering College for Women ", "department": "Computer science and engineering ", "roll_number": "24321A0508", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8309132453", "college_name": "Bhojreddy Engineering College for Women ", "department": "Computer science and engineering ", "email": "akhilareddy2112@gmail.com", "name": "Akhila Samreddy ", "phone": "7989728117", "roll_number": "24321A0508", "year_of_study": "2"}}	2025-10-12 05:40:05.720969+00	2025-10-13 05:02:23.948092+00	2025-10-13 05:02:23.948718+00
58	1	\N	pay_RSYRcsy683lpSW	\N		67000	INR	captured	HIMANI JOSHI	himanijoshi218@gmail.com	6301090687	{"college_name": "St.Martin's Engineering College ", "department": "CSM", "roll_number": "24K81A6689", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7240793996", "college_name": "St.Martin's Engineering College ", "department": "CSM", "email": "himanijoshi218@gmail.com", "name": "HIMANI JOSHI", "phone": "6301090687", "referral_name": "Shivani", "roll_number": "24K81A6689", "section": "B", "year_of_study": "2"}}	2025-10-12 12:10:33.597279+00	2025-10-13 07:02:32.374179+00	2025-10-13 07:02:32.374564+00
55	1	\N	pay_RSWWQqXizuaVoy	\N		67000	INR	captured	Janvi Parkalwar	goudjanvi06@gmail.com	8208349952	{"college_name": "St Martin's engineering college Kompally,Hyderabad ", "department": "CSM", "roll_number": "24K81A66F8", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8208529089", "college_name": "St Martin's engineering college Kompally,Hyderabad ", "department": "CSM", "email": "goudjanvi06@gmail.com", "name": "Janvi Parkalwar", "phone": "8208349952", "roll_number": "24K81A66F8", "section": "C", "year_of_study": "2"}}	2025-10-12 10:10:24.620411+00	2025-10-13 07:02:32.386466+00	2025-10-13 07:02:32.386877+00
71	1	\N	pay_RScjEcwqS163Jz	\N		67000	INR	failed	THATAVARTHI VENKATARAMANA 	venkataramana0609@gmail.com	9849501104	{"college_name": "St Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "roll_number": "24K81A0210", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8500760969", "college_name": "St Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "email": "venkataramana0609@gmail.com", "name": "THATAVARTHI VENKATARAMANA ", "phone": "9849501104", "roll_number": "24K81A0210", "section": "A", "year_of_study": "2"}}	2025-10-12 16:40:59.796612+00	2025-10-12 16:40:59.796612+00	\N
60	1	\N	pay_RSZDoJtajZBFZJ	\N		67000	INR	captured	VEGIRAJU MAHAVEER VARMA	mahaveervarma.vegiraju@gmail.com	6301873506	{"college_name": "St.Martin's Engineering College", "department": "CSM", "roll_number": "25K85A6602", "emergency_contact": "", "original_notes": {"alternative_phone_number": "6301873506", "college_name": "St.Martin's Engineering College", "department": "CSM", "email": "mahaveervarma.vegiraju@gmail.com", "name": "VEGIRAJU MAHAVEER VARMA", "phone": "6301873506", "roll_number": "25K85A6602", "section": "A", "year_of_study": "2"}}	2025-10-12 13:10:39.862782+00	2025-10-13 07:02:32.371+00	2025-10-13 07:02:32.371372+00
59	1	\N	pay_RSYJHTPnQAtgzC	\N		67000	INR	captured	Mir Saaduddin Ali 	mirsaaduddinali@gmail.com	8639475925	{"college_name": "St.Martins Engineering College ", "department": "CSM", "roll_number": "24K81A6638", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9849892488", "college_name": "St.Martins Engineering College ", "department": "CSM", "email": "mirsaaduddinali@gmail.com", "name": "Mir Saaduddin Ali ", "phone": "8639475925", "referral_name": "Mir Saaduddin Ali ", "roll_number": "24K81A6638", "section": "A", "year_of_study": "2"}}	2025-10-12 12:10:34.751435+00	2025-10-13 07:02:32.37687+00	2025-10-13 07:02:32.377598+00
61	1	\N	pay_RSa5iip9QOFu8k	\N		67000	INR	failed	Khushi Singh 	khushisingh.040821@gmail.com	8790197135	{"college_name": "St.martins engineering college ", "department": "CSM ", "roll_number": "25k81a66f6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9246119091", "college_name": "St.martins engineering college ", "department": "CSM ", "email": "khushisingh.040821@gmail.com", "name": "Khushi Singh ", "phone": "8790197135", "referral_name": "Sri neha ", "roll_number": "25k81a66f6", "section": "Csm c", "year_of_study": "1"}}	2025-10-12 13:40:42.932687+00	2025-10-12 14:03:20.047241+00	\N
66	1	\N	pay_RScY2TbLImvpqb	\N		67000	INR	captured	R SNEHA	sneha.rameshwaram25@gmail.com	8142345729	{"college_name": "St. Martin's Engineering College ", "department": "AIDS", "roll_number": "23K81A7253", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8142345728", "college_name": "St. Martin's Engineering College ", "department": "AIDS", "email": "sneha.rameshwaram25@gmail.com", "name": "R SNEHA", "phone": "8142345729", "roll_number": "23K81A7253", "section": "A", "year_of_study": "3"}}	2025-10-12 16:10:54.717928+00	2025-10-13 07:02:32.350585+00	2025-10-13 07:02:32.350934+00
56	1	\N	pay_RSXHpD7TDhNomu	\N		67000	INR	captured	ARISETTI DHEERAJ KIRAN 	dheerajkiran2006@gmail.com	7981334595	{"college_name": "St.Martin's Engineering College ", "department": "CSM", "roll_number": "24K81A6672", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9441187316", "college_name": "St.Martin's Engineering College ", "department": "CSM", "email": "dheerajkiran2006@gmail.com", "name": "ARISETTI DHEERAJ KIRAN ", "phone": "7981334595", "referral_name": "Shivani", "roll_number": "24K81A6672", "section": "B", "year_of_study": "2"}}	2025-10-12 11:10:27.968037+00	2025-10-13 07:02:32.379743+00	2025-10-13 07:02:32.380074+00
53	1	\N	pay_RSTumQAUazWkyQ	\N		67000	INR	captured	Busa Reethusri 	busareethu@gmail.com	9912157587	{"college_name": "St.martins engineering college ", "department": "ECE", "roll_number": "23K81A0415", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9177918812", "college_name": "St.martins engineering college ", "department": "ECE", "email": "busareethu@gmail.com", "name": "Busa Reethusri ", "phone": "9912157587", "roll_number": "23K81A0415", "year_of_study": "3"}}	2025-10-12 07:40:14.539235+00	2025-10-13 07:02:32.393588+00	2025-10-13 07:02:32.39391+00
57	1	\N	pay_RSXFD8N7AWGrVH	\N		67000	INR	captured	MANOJ SAI KAMMATI	kammatimanojsai@gmail.com	7075282316	{"college_name": "ST. MARTINS ENGINEERING COLLEGE ", "department": "CSE", "roll_number": "24K81A05N8", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9100482316", "college_name": "ST. MARTINS ENGINEERING COLLEGE ", "department": "CSE", "email": "kammatimanojsai@gmail.com", "name": "MANOJ SAI KAMMATI", "phone": "7075282316", "referral_name": "A.PRANAY", "roll_number": "24K81A05N8", "section": "D", "year_of_study": "2"}}	2025-10-12 11:10:29.130324+00	2025-10-13 07:02:32.382598+00	2025-10-13 07:02:32.382947+00
63	1	\N	pay_RSa7pRR4G9rAEq	\N		67000	INR	captured	Khushi Singh 	khushisingh.040821@gmail.com	8790197135	{"college_name": "St.martins engineering college ", "department": "CSM ", "roll_number": "25k81a66f6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9246119091", "college_name": "St.martins engineering college ", "department": "CSM ", "email": "khushisingh.040821@gmail.com", "name": "Khushi Singh ", "phone": "8790197135", "referral_name": "Sri neha ", "roll_number": "25k81a66f6", "section": "Csm c", "year_of_study": "1"}}	2025-10-12 14:03:18.895857+00	2025-10-13 07:02:32.363358+00	2025-10-13 07:02:32.363719+00
62	1	\N	pay_RSZhADwIc0uY45	\N		67000	INR	captured	Abhiram Kasturi 	abhiramkasturi19@gmail.com	9059227073	{"college_name": "St.Martins College ", "department": "CSM", "roll_number": "24K81A6627", "emergency_contact": "", "original_notes": {"alternative_phone_number": "7680803927", "college_name": "St.Martins College ", "department": "CSM", "email": "abhiramkasturi19@gmail.com", "name": "Abhiram Kasturi ", "phone": "9059227073", "roll_number": "24K81A6627", "section": "CSM A", "year_of_study": "2"}}	2025-10-12 13:40:42.938148+00	2025-10-13 07:02:32.36821+00	2025-10-13 07:02:32.368569+00
67	1	\N	pay_RScY0Of2NMlsJm	\N		67000	INR	failed	Balaji	sribalaji.dangeti@gmail.com	9032982759	{"college_name": "St.Martins Engineering College ", "department": "ECE", "roll_number": "25K81A04D6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8978899993", "college_name": "St.Martins Engineering College ", "department": "ECE", "email": "sribalaji.dangeti@gmail.com", "name": "Balaji", "phone": "9032982759", "roll_number": "25K81A04D6", "section": "C", "year_of_study": "1"}}	2025-10-12 16:10:56.451798+00	2025-10-12 16:40:59.812843+00	\N
68	1	\N	pay_RScXERymndlCQe	\N		67000	INR	captured	Ande Akhilraj 	akhilrajande71@gmail.com	7981918509	{"college_name": "St.Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "roll_number": "24K81A0214", "emergency_contact": "", "original_notes": {"alternative_phone_number": "6304789866", "college_name": "St.Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "email": "akhilrajande71@gmail.com", "name": "Ande Akhilraj ", "phone": "7981918509", "roll_number": "24K81A0214", "section": "A", "year_of_study": "2"}}	2025-10-12 16:10:56.456619+00	2025-10-13 07:02:32.354823+00	2025-10-13 07:02:32.355133+00
64	1	\N	pay_RSaihj0I74ndZ7	\N		67000	INR	captured	Manasa	manasareddyeltepu16@gmail.com	7893445765	{"college_name": "St.Martin's Enginnering College", "department": "IT", "roll_number": "23K81A1216", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9182822084", "college_name": "St.Martin's Enginnering College", "department": "IT", "email": "manasareddyeltepu16@gmail.com", "name": "Manasa", "phone": "7893445765", "referral_name": "A.pranay", "roll_number": "23K81A1216", "section": "A", "year_of_study": "3"}}	2025-10-12 14:40:47.111137+00	2025-10-13 07:02:32.358502+00	2025-10-13 07:02:32.360436+00
72	1	\N	pay_RScgsFc0K3XVXv	\N		67000	INR	failed	THATAVARTHI VENKATARAMANA 	venkataramana0609@gmail.com	9849501104	{"college_name": "St Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "roll_number": "24K81A0210", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8500760969", "college_name": "St Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "email": "venkataramana0609@gmail.com", "name": "THATAVARTHI VENKATARAMANA ", "phone": "9849501104", "roll_number": "24K81A0210", "section": "A", "year_of_study": "2"}}	2025-10-12 16:40:59.801195+00	2025-10-12 16:40:59.801195+00	\N
69	1	\N	pay_RScVyeM38Bclnh	\N		67000	INR	failed	Ande Akhilraj 	akhilrajande71@gmail.com	7981918509	{"college_name": "St.Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "roll_number": "24K81A0214", "emergency_contact": "", "original_notes": {"alternative_phone_number": "6304789866", "college_name": "St.Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "email": "akhilrajande71@gmail.com", "name": "Ande Akhilraj ", "phone": "7981918509", "roll_number": "24K81A0214", "section": "A", "year_of_study": "2"}}	2025-10-12 16:10:57.506812+00	2025-10-12 16:40:59.817891+00	\N
80	1	\N	pay_RSpT9nv45s7W6K	\N		67000	INR	captured	E NAGA MANOJ 	kkp2053manoj@gmail.com	9281044486	{"college_name": "Malla Reddy University ", "department": "Information technology ", "roll_number": "2311IT010055", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8639159685", "college_name": "Malla Reddy University ", "department": "Information technology ", "email": "kkp2053manoj@gmail.com", "name": "E NAGA MANOJ ", "phone": "9281044486", "referral_name": "DR GOWTHAM MAMIDISETTY ", "roll_number": "2311IT010055", "section": "Alpha", "year_of_study": "3"}}	2025-10-13 05:02:08.575315+00	2025-10-13 07:02:32.317745+00	2025-10-13 07:02:32.319095+00
76	1	\N	pay_RSdiRMpShU8GCT	\N		67000	INR	captured	SAI HARI	saihari143702367@gmail.com	9014303660	{"college_name": "St.martins engineering College ", "department": "CSM", "roll_number": "24K81A6615", "emergency_contact": "", "original_notes": {"alternative_phone_number": "6304669914", "college_name": "St.martins engineering College ", "department": "CSM", "email": "saihari143702367@gmail.com", "name": "SAI HARI", "phone": "9014303660", "referral_name": "MR.S", "roll_number": "24K81A6615", "section": "A", "year_of_study": "2"}}	2025-10-12 17:41:07.455381+00	2025-10-13 07:02:32.333811+00	2025-10-13 07:02:32.334143+00
70	1	\N	pay_RScm3D7GSiwdQm	\N		67000	INR	captured	THATAVARTHI VENKATARAMANA 	venkataramana0609@gmail.com	9849501104	{"college_name": "St Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "roll_number": "24K81A0210", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8500760969", "college_name": "St Martin's Engineering College ", "department": "Electrical and Electronics Engineering ", "email": "venkataramana0609@gmail.com", "name": "THATAVARTHI VENKATARAMANA ", "phone": "9849501104", "roll_number": "24K81A0210", "section": "A", "year_of_study": "2"}}	2025-10-12 16:40:58.647964+00	2025-10-13 07:02:32.343036+00	2025-10-13 07:02:32.343404+00
77	1	\N	pay_RSezytrxNYL2l7	\N		67000	INR	failed	Suhail ahmed butt	suhailahmed77063@gmail.com	9682621258	{"college_name": "ST MARTIN'S ENGINERNING  COLLEGE DHULAPLALY HDERABAD TELENGANA", "department": "CSE", "roll_number": "24K81A05Q9", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9682621258", "college_name": "ST MARTIN'S ENGINERNING  COLLEGE DHULAPLALY HDERABAD TELENGANA", "department": "CSE", "email": "suhailahmed77063@gmail.com", "name": "Suhail ahmed butt", "phone": "9682621258", "referral_name": "G.pranay", "roll_number": "24K81A05Q9", "section": "D", "year_of_study": "2"}}	2025-10-12 18:41:12.2951+00	2025-10-12 18:41:12.2951+00	\N
65	1	\N	pay_RScYGC0jEAbJaM	\N		67000	INR	captured	Balaji	sribalaji.dangeti@gmail.com	9032982759	{"college_name": "St.Martins Engineering College ", "department": "ECE", "roll_number": "25K81A04D6", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8978899993", "college_name": "St.Martins Engineering College ", "department": "ECE", "email": "sribalaji.dangeti@gmail.com", "name": "Balaji", "phone": "9032982759", "roll_number": "25K81A04D6", "section": "C", "year_of_study": "1"}}	2025-10-12 16:10:53.187867+00	2025-10-13 07:02:32.348124+00	2025-10-13 07:02:32.348482+00
73	1	\N	pay_RSdSFTc4QBLjei	\N		67000	INR	captured	Varshasri sayannagari	varshasrisayannagari@gmail.com	9030303988	{"college_name": "St.martins Engineering College ", "department": "Electronics and communication Engineering ", "roll_number": "22k81A0455", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9676685690", "college_name": "St.martins Engineering College ", "department": "Electronics and communication Engineering ", "email": "varshasrisayannagari@gmail.com", "name": "Varshasri sayannagari", "phone": "9030303988", "roll_number": "22k81A0455", "section": "A", "year_of_study": "4"}}	2025-10-12 17:11:00.846444+00	2025-10-13 07:02:32.336564+00	2025-10-13 07:02:32.336893+00
79	1	\N	pay_RSoMzKqdfrupy6	\N		67000	INR	captured	Rohit Pranav Naidu 	naidurohitpranav@gmail.com	9000445828	{"college_name": "St. Martins Engineering College ", "department": "CSE", "roll_number": "24K81A05P5", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8712198661", "college_name": "St. Martins Engineering College ", "department": "CSE", "email": "naidurohitpranav@gmail.com", "name": "Rohit Pranav Naidu ", "phone": "9000445828", "referral_name": "G. Pranay ", "roll_number": "24K81A05P5", "section": "D", "year_of_study": "2"}}	2025-10-13 03:40:57.420869+00	2025-10-13 07:02:32.326582+00	2025-10-13 07:02:32.326965+00
75	1	\N	pay_RSe40JmqSdov8r	\N		67000	INR	captured	Deekshith raj soppari	sopparideekshithraj@gmail.com	9182283301	{"college_name": "St.martins Engineering College ", "department": "Electronics and communication Engineering ", "roll_number": "22k81A0457", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9676685690", "college_name": "St.martins Engineering College ", "department": "Electronics and communication Engineering ", "email": "sopparideekshithraj@gmail.com", "name": "Deekshith raj soppari", "phone": "9182283301", "roll_number": "22k81A0457", "section": "A", "year_of_study": "4"}}	2025-10-12 17:41:04.886385+00	2025-10-13 07:02:32.330926+00	2025-10-13 07:02:32.33127+00
74	1	\N	pay_RSdOkcvg98luXc	\N		67000	INR	captured	Sri vaishnavi puvvada 	srivaishnavipuvvada@gmail.com	9676685690	{"college_name": "St.martins Engineering College ", "department": "Electronics and communication Engineering ", "roll_number": "22k81A0453", "emergency_contact": "", "original_notes": {"alternative_phone_number": "8332939107", "college_name": "St.martins Engineering College ", "department": "Electronics and communication Engineering ", "email": "srivaishnavipuvvada@gmail.com", "name": "Sri vaishnavi puvvada ", "phone": "9676685690", "roll_number": "22k81A0453", "section": "A", "year_of_study": "4"}}	2025-10-12 17:11:02.687258+00	2025-10-13 07:02:32.339754+00	2025-10-13 07:02:32.340086+00
78	1	\N	pay_RSoOtFPziMqqfr	\N		67000	INR	captured	Varsha Bikkineni	bikkinenivarsha667@gmail.com	8712198661	{"college_name": "St.Martin's Engineering college ", "department": "CSE ", "roll_number": "24K81A05L0", "emergency_contact": "", "original_notes": {"alternative_phone_number": "9000445828", "college_name": "St.Martin's Engineering college ", "department": "CSE ", "email": "bikkinenivarsha667@gmail.com", "name": "Varsha Bikkineni", "phone": "8712198661", "referral_name": "G.pranay", "roll_number": "24K81A05L0", "section": "D", "year_of_study": "2"}}	2025-10-13 03:40:56.04717+00	2025-10-13 07:02:32.323087+00	2025-10-13 07:02:32.323769+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: qrflow_user
--

COPY public.users (id, username, email, password_hash, full_name, club_id, role, created_at, last_login, disabled) FROM stdin;
2	E-CELL	ecell.smec@gmail.com	$2b$12$DUhGm7v00R1Bu00AcQ/mC.a7IJX/WR9YFwPr0wudUaZRul6Xe7Zze	E-CELL ADMIN	1	organizer	2025-10-08 05:32:05.346341+00	2025-10-13 05:22:18.554112+00	f
1	admin	indrakshith.reddy@gmail.com	$2b$12$lksWlyS4pfBlf4Iluskr1uYwTCPV64T87oIBOeg4ZTgKto54qTvS6	System Administrator	\N	admin	2025-10-08 05:29:08.023949+00	2025-10-13 05:25:07.675162+00	f
\.


--
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: qrflow_user
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 89, true);


--
-- Name: attendees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: qrflow_user
--

SELECT pg_catalog.setval('public.attendees_id_seq', 64, true);


--
-- Name: clubs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: qrflow_user
--

SELECT pg_catalog.setval('public.clubs_id_seq', 1, true);


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: qrflow_user
--

SELECT pg_catalog.setval('public.events_id_seq', 1, true);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: qrflow_user
--

SELECT pg_catalog.setval('public.payments_id_seq', 80, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: qrflow_user
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: attendees attendees_pkey; Type: CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.attendees
    ADD CONSTRAINT attendees_pkey PRIMARY KEY (id);


--
-- Name: clubs clubs_pkey; Type: CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.clubs
    ADD CONSTRAINT clubs_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_activity_logs_action_type; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_activity_logs_action_type ON public.activity_logs USING btree (action_type);


--
-- Name: ix_activity_logs_id; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_activity_logs_id ON public.activity_logs USING btree (id);


--
-- Name: ix_activity_logs_timestamp; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_activity_logs_timestamp ON public.activity_logs USING btree ("timestamp");


--
-- Name: ix_attendees_branch; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_attendees_branch ON public.attendees USING btree (branch);


--
-- Name: ix_attendees_email; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_attendees_email ON public.attendees USING btree (email);


--
-- Name: ix_attendees_id; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_attendees_id ON public.attendees USING btree (id);


--
-- Name: ix_attendees_name; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_attendees_name ON public.attendees USING btree (name);


--
-- Name: ix_attendees_qr_token; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE UNIQUE INDEX ix_attendees_qr_token ON public.attendees USING btree (qr_token);


--
-- Name: ix_attendees_roll_number; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_attendees_roll_number ON public.attendees USING btree (roll_number);


--
-- Name: ix_attendees_section; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_attendees_section ON public.attendees USING btree (section);


--
-- Name: ix_attendees_year; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_attendees_year ON public.attendees USING btree (year);


--
-- Name: ix_clubs_id; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_clubs_id ON public.clubs USING btree (id);


--
-- Name: ix_clubs_name; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE UNIQUE INDEX ix_clubs_name ON public.clubs USING btree (name);


--
-- Name: ix_events_id; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_events_id ON public.events USING btree (id);


--
-- Name: ix_events_name; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_events_name ON public.events USING btree (name);


--
-- Name: ix_payments_customer_email; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_payments_customer_email ON public.payments USING btree (customer_email);


--
-- Name: ix_payments_id; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_payments_id ON public.payments USING btree (id);


--
-- Name: ix_payments_razorpay_payment_id; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE UNIQUE INDEX ix_payments_razorpay_payment_id ON public.payments USING btree (razorpay_payment_id);


--
-- Name: ix_payments_status; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_payments_status ON public.payments USING btree (status);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: qrflow_user
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: activity_logs activity_logs_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id);


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: attendees attendees_checked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.attendees
    ADD CONSTRAINT attendees_checked_by_fkey FOREIGN KEY (checked_by) REFERENCES public.users(id);


--
-- Name: attendees attendees_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.attendees
    ADD CONSTRAINT attendees_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: events events_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id);


--
-- Name: events events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: payments payments_attendee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_attendee_id_fkey FOREIGN KEY (attendee_id) REFERENCES public.attendees(id);


--
-- Name: payments payments_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: users users_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: qrflow_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 6Auhee9gIl5NAIE9jQFCfDACjO2GfA3I8EL3EyOsw6hvc1IkwmwCyAF8RzyaQoc

