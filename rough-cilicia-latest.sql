--
-- PostgreSQL database dump
--


-- Dumped from database version 17.9 (Ubuntu 17.9-1.pgdg24.04+1)
-- Dumped by pg_dump version 18.1

-- Started on 2026-07-20 15:47:35 +03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 10 (class 2615 OID 22657)
-- Name: cilicia; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA cilicia;


ALTER SCHEMA cilicia OWNER TO postgres;

--
-- TOC entry 4780 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA cilicia; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA cilicia IS 'Rough Cilicia Arkeolojik Araştırma Projesi - Eğitim Veritabanı (CC BY 4.0)';


--
-- TOC entry 9 (class 2615 OID 22470)
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- TOC entry 4781 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- TOC entry 2 (class 3079 OID 21383)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 4782 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 3 (class 3079 OID 22471)
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- TOC entry 4783 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- TOC entry 4 (class 3079 OID 22646)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 4784 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 285 (class 1255 OID 22810)
-- Name: distance_km(public.geometry, public.geometry); Type: FUNCTION; Schema: cilicia; Owner: postgres
--

CREATE FUNCTION cilicia.distance_km(point1 public.geometry, point2 public.geometry) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    RETURN ST_Distance(
        ST_Transform(point1, 3857),
        ST_Transform(point2, 3857)
    ) / 1000.0;
END;
$$;


ALTER FUNCTION cilicia.distance_km(point1 public.geometry, point2 public.geometry) OWNER TO postgres;

--
-- TOC entry 400 (class 1255 OID 22811)
-- Name: find_subjects_within_radius(double precision, double precision, double precision); Type: FUNCTION; Schema: cilicia; Owner: postgres
--

CREATE FUNCTION cilicia.find_subjects_within_radius(center_lon double precision, center_lat double precision, radius_km double precision) RETURNS TABLE(uuid uuid, label text, class_label text, distance_km double precision)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    center_geom GEOMETRY;
BEGIN
    center_geom := ST_SetSRID(ST_MakePoint(center_lon, center_lat), 4326);
    RETURN QUERY
    SELECT
        s.uuid,
        s.label,
        s.class_label,
        distance_km(s.location, center_geom) AS dist
    FROM subjects s
    WHERE s.location IS NOT NULL
      AND ST_DWithin(
            ST_Transform(s.location, 3857),
            ST_Transform(center_geom, 3857),
            radius_km * 1000
          )
    ORDER BY dist;
END;
$$;


ALTER FUNCTION cilicia.find_subjects_within_radius(center_lon double precision, center_lat double precision, radius_km double precision) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 240 (class 1259 OID 22775)
-- Name: media; Type: TABLE; Schema: cilicia; Owner: postgres
--

CREATE TABLE cilicia.media (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_uuid uuid,
    subject_uuid uuid,
    oc_uri text,
    slug text,
    label text,
    media_type text,
    file_uri text,
    thumbnail_uri text,
    mime_type text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE cilicia.media OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 22748)
-- Name: observations; Type: TABLE; Schema: cilicia; Owner: postgres
--

CREATE TABLE cilicia.observations (
    id bigint NOT NULL,
    subject_uuid uuid,
    predicate_uuid uuid,
    predicate_label text,
    value_str text,
    value_num double precision,
    value_bool boolean,
    value_uri text,
    type_uuid uuid,
    type_label text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE cilicia.observations OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 22747)
-- Name: observations_id_seq; Type: SEQUENCE; Schema: cilicia; Owner: postgres
--

CREATE SEQUENCE cilicia.observations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cilicia.observations_id_seq OWNER TO postgres;

--
-- TOC entry 4785 (class 0 OID 0)
-- Dependencies: 238
-- Name: observations_id_seq; Type: SEQUENCE OWNED BY; Schema: cilicia; Owner: postgres
--

ALTER SEQUENCE cilicia.observations_id_seq OWNED BY cilicia.observations.id;


--
-- TOC entry 236 (class 1259 OID 22712)
-- Name: predicates; Type: TABLE; Schema: cilicia; Owner: postgres
--

CREATE TABLE cilicia.predicates (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_uuid uuid,
    oc_uri text,
    slug text,
    label text NOT NULL,
    data_type text,
    var_type text
);


ALTER TABLE cilicia.predicates OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 22658)
-- Name: projects; Type: TABLE; Schema: cilicia; Owner: postgres
--

CREATE TABLE cilicia.projects (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    label text NOT NULL,
    slug text,
    description text,
    abstract text,
    issued date,
    modified date,
    license text,
    creator text,
    bbox public.geometry(MultiPolygon,4326),
    time_start integer,
    time_end integer
);


ALTER TABLE cilicia.projects OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 22668)
-- Name: sites; Type: TABLE; Schema: cilicia; Owner: postgres
--

CREATE TABLE cilicia.sites (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_uuid uuid,
    oc_uri text,
    slug text,
    label text NOT NULL,
    context_path text,
    item_type text,
    class_uri text,
    location public.geometry(Point,4326),
    bbox public.geometry(Polygon,4326),
    precision_note text,
    time_start integer,
    time_end integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE cilicia.sites OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 22687)
-- Name: subjects; Type: TABLE; Schema: cilicia; Owner: postgres
--

CREATE TABLE cilicia.subjects (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_uuid uuid,
    site_uuid uuid,
    oc_uri text,
    slug text,
    label text NOT NULL,
    item_type text,
    class_uri text,
    class_label text,
    context_path text,
    location public.geometry(Point,4326),
    location_type text,
    precision_note text,
    time_start integer,
    time_end integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE cilicia.subjects OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 22727)
-- Name: types; Type: TABLE; Schema: cilicia; Owner: postgres
--

CREATE TABLE cilicia.types (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_uuid uuid,
    oc_uri text,
    slug text,
    label text NOT NULL,
    predicate_uuid uuid
);


ALTER TABLE cilicia.types OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 22805)
-- Name: v_sites_summary; Type: VIEW; Schema: cilicia; Owner: postgres
--

CREATE VIEW cilicia.v_sites_summary AS
 SELECT s.uuid,
    s.label AS site_name,
    s.context_path,
    public.st_astext(s.location) AS location_wkt,
    count(sub.uuid) AS subject_count
   FROM (cilicia.sites s
     LEFT JOIN cilicia.subjects sub ON ((sub.site_uuid = s.uuid)))
  GROUP BY s.uuid, s.label, s.context_path, s.location
  ORDER BY (count(sub.uuid)) DESC;


ALTER VIEW cilicia.v_sites_summary OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 22801)
-- Name: v_subjects_by_class; Type: VIEW; Schema: cilicia; Owner: postgres
--

CREATE VIEW cilicia.v_subjects_by_class AS
 SELECT class_label,
    count(*) AS record_count,
    min(time_start) AS earliest_date,
    max(time_end) AS latest_date
   FROM cilicia.subjects
  GROUP BY class_label
  ORDER BY (count(*)) DESC;


ALTER VIEW cilicia.v_subjects_by_class OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 22796)
-- Name: v_subjects_with_coords; Type: VIEW; Schema: cilicia; Owner: postgres
--

CREATE VIEW cilicia.v_subjects_with_coords AS
 SELECT s.uuid,
    s.label,
    s.class_label,
    s.context_path,
    s.time_start,
    s.time_end,
    public.st_astext(s.location) AS location_wkt,
    public.st_x(s.location) AS longitude,
    public.st_y(s.location) AS latitude,
    p.label AS project_name
   FROM (cilicia.subjects s
     LEFT JOIN cilicia.projects p ON ((p.uuid = s.project_uuid)))
  WHERE (s.location IS NOT NULL);


ALTER VIEW cilicia.v_subjects_with_coords OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 22816)
-- Name: finds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.finds (
    id integer NOT NULL,
    subject_id text,
    label text,
    category text,
    period text,
    latitude double precision,
    longitude double precision,
    geom public.geometry(Point,4326),
    site_id integer,
    tomb_type text,
    typology text,
    inscribed text,
    feature_desc text,
    material text,
    detail text,
    comment text,
    has_note text,
    length text,
    width text,
    thick text,
    elevation text,
    utm_x text,
    utm_y text
);


ALTER TABLE public.finds OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 22815)
-- Name: finds_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.finds_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.finds_id_seq OWNER TO postgres;

--
-- TOC entry 4786 (class 0 OID 0)
-- Dependencies: 244
-- Name: finds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.finds_id_seq OWNED BY public.finds.id;


--
-- TOC entry 247 (class 1259 OID 22865)
-- Name: sites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sites (
    id integer NOT NULL,
    subject_id text,
    label text,
    location_code text,
    site_category text,
    cultural_type text,
    topography text,
    geom public.geometry(Point,4326)
);


ALTER TABLE public.sites OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 22864)
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sites_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sites_id_seq OWNER TO postgres;

--
-- TOC entry 4787 (class 0 OID 0)
-- Dependencies: 246
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sites_id_seq OWNED BY public.sites.id;


--
-- TOC entry 4540 (class 2604 OID 22751)
-- Name: observations id; Type: DEFAULT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.observations ALTER COLUMN id SET DEFAULT nextval('cilicia.observations_id_seq'::regclass);


--
-- TOC entry 4544 (class 2604 OID 22819)
-- Name: finds id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finds ALTER COLUMN id SET DEFAULT nextval('public.finds_id_seq'::regclass);


--
-- TOC entry 4545 (class 2604 OID 22868)
-- Name: sites id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites ALTER COLUMN id SET DEFAULT nextval('public.sites_id_seq'::regclass);


--
-- TOC entry 4770 (class 0 OID 22775)
-- Dependencies: 240
-- Data for Name: media; Type: TABLE DATA; Schema: cilicia; Owner: postgres
--

COPY cilicia.media (uuid, project_uuid, subject_uuid, oc_uri, slug, label, media_type, file_uri, thumbnail_uri, mime_type, created_at) FROM stdin;
\.


--
-- TOC entry 4769 (class 0 OID 22748)
-- Dependencies: 239
-- Data for Name: observations; Type: TABLE DATA; Schema: cilicia; Owner: postgres
--

COPY cilicia.observations (id, subject_uuid, predicate_uuid, predicate_label, value_str, value_num, value_bool, value_uri, type_uuid, type_label, created_at) FROM stdin;
\.


--
-- TOC entry 4766 (class 0 OID 22712)
-- Dependencies: 236
-- Data for Name: predicates; Type: TABLE DATA; Schema: cilicia; Owner: postgres
--

COPY cilicia.predicates (uuid, project_uuid, oc_uri, slug, label, data_type, var_type) FROM stdin;
\.


--
-- TOC entry 4763 (class 0 OID 22658)
-- Dependencies: 233
-- Data for Name: projects; Type: TABLE DATA; Schema: cilicia; Owner: postgres
--

COPY cilicia.projects (uuid, label, slug, description, abstract, issued, modified, license, creator, bbox, time_start, time_end) FROM stdin;
295b5bf4-0f44-4698-80cd-7a39cb6f133d	Rough Cilicia	21-rough-cilicia	Survey exploring Roman provincial acculturation through the lens of Rough Cilician material and cultural remains	\N	2012-04-28	2021-11-26	CC BY 4.0	Nicholas K. Rauh	0106000020E61000000F00000001030000000100000005000000CA3795D4494A404093502720E9164240C5C576B36F4D404093502720E9164240C5C576B36F4D4040BBE6F68573194240CA3795D4494A4040BBE6F68573194240CA3795D4494A404093502720E916424001030000000100000005000000F9F6E65BD23540404BD8C2AB9C2942402DC90BBDF93840404BD8C2AB9C2942402DC90BBDF9384040736E9211272C4240F9F6E65BD2354040736E9211272C4240F9F6E65BD23540404BD8C2AB9C29424001030000000100000005000000A0D41C1A5A434040195D2497EF1F4240E5410EB380464040195D2497EF1F4240E5410EB3804640403FF3F3FC79224240A0D41C1A5A4340403FF3F3FC79224240A0D41C1A5A434040195D2497EF1F4240010300000001000000050000008BFE8A12804140402C5D667DEF1342400DD78FBBA54440402C5D667DEF1342400DD78FBBA54440409A17D475301742408BFE8A12804140409A17D475301742408BFE8A12804140402C5D667DEF13424001030000000100000005000000E96E4BA266244040C8E051F82621424050EF3546632A4040C8E051F82621424050EF3546632A40408A39083A5A264240E96E4BA2662440408A39083A5A264240E96E4BA266244040C8E051F82621424001030000000100000005000000A63B8629172E404025E92AD19330424021713F1B3F31404025E92AD19330424021713F1B3F3140404D7FFA361E334240A63B8629172E40404D7FFA361E334240A63B8629172E404025E92AD19330424001030000000100000005000000A0294C3F9734404018855901641342404067C9D5BC37404018855901641342404067C9D5BC374040401B2967EE154240A0294C3F97344040401B2967EE154240A0294C3F97344040188559016413424001030000000100000005000000469F15F2852E4040CBB30150EF3442408295733EAE314040CBB30150EF3442408295733EAE314040F449D1B579374240469F15F2852E4040F449D1B579374240469F15F2852E4040CBB30150EF3442400103000000010000000500000008381AD73539404082573226441C4240F56150245C3C404082573226441C4240F56150245C3C4040ABED018CCE1E424008381AD735394040ABED018CCE1E424008381AD73539404082573226441C424001030000000100000005000000A8953AAF4E1E4040D5333DEAE32842400F25DE2A1D244040D5333DEAE32842400F25DE2A1D244040FCC90C506E2B4240A8953AAF4E1E4040FCC90C506E2B4240A8953AAF4E1E4040D5333DEAE328424001030000000100000005000000C9D2E2E79A3A4040477343D72E184240B69E211CB33E4040477343D72E184240B69E211CB33E40408D7A8846F71A4240C9D2E2E79A3A40408D7A8846F71A4240C9D2E2E79A3A4040477343D72E18424001030000000100000005000000A284141BA6304040C4E19ED314154240E8F553D4CB334040C4E19ED314154240E8F553D4CB334040EC776E399F174240A284141BA6304040EC776E399F174240A284141BA6304040C4E19ED31415424001030000000100000005000000C87628D755344040B6E990767A34424039DF051A7E374040B6E990767A34424039DF051A7E374040DC7F60DC04374240C87628D755344040DC7F60DC04374240C87628D755344040B6E990767A34424001030000000100000005000000B183EFA2542A4040EB53A209E31B4240E49C7D8A082E4040EB53A209E31B4240E49C7D8A082E404012EA716F6D1E4240B183EFA2542A404012EA716F6D1E4240B183EFA2542A4040EB53A209E31B4240010300000001000000050000009BFFAF7E7F3240400630AB5A021C4240AC6099C6A53540400630AB5A021C4240AC6099C6A53540402EC67AC08C1E42409BFFAF7E7F3240402EC67AC08C1E42409BFFAF7E7F3240400630AB5A021C4240	1	330
\.


--
-- TOC entry 4764 (class 0 OID 22668)
-- Dependencies: 234
-- Data for Name: sites; Type: TABLE DATA; Schema: cilicia; Owner: postgres
--

COPY cilicia.sites (uuid, project_uuid, oc_uri, slug, label, context_path, item_type, class_uri, location, bbox, precision_note, time_start, time_end, created_at) FROM stdin;
\.


--
-- TOC entry 4765 (class 0 OID 22687)
-- Dependencies: 235
-- Data for Name: subjects; Type: TABLE DATA; Schema: cilicia; Owner: postgres
--

COPY cilicia.subjects (uuid, project_uuid, site_uuid, oc_uri, slug, label, item_type, class_uri, class_label, context_path, location, location_type, precision_note, time_start, time_end, created_at) FROM stdin;
56d5aec3-2549-4e80-9bb8-2032b7a35a05	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4fd04130-378b-483d-96fa-13cce9b8db38		Tomb: Corus-4	subjects			Asia/Turkey/Corus	0101000020E610000060259B82673740405FD517115E2A4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
c93aee53-5ee4-4121-8f20-7c9b8184fec7	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/ef169c04-d37a-4855-723b-6be03b8ea51a		Tomb: Kenetepe-13	subjects			Asia/Turkey/Kenetepe	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
13c26a3b-7169-459f-ab9b-045721eb8f2e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210310113321&proj=21-rough-cilicia&rows=100&type=subjects		Region (21)	subjects				0101000020E610000000000000F824404044CAFF16BC2B4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
28a8828c-9603-4a3d-9c79-4477486d0dd1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210310131111&proj=21-rough-cilicia&rows=100&type=subjects		Region (22)	subjects				0101000020E610000000000000982A40404AB7F4E833274240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
1c8d689a-5471-459d-afab-26b4a0ca785d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020202&proj=21-rough-cilicia&rows=100&type=subjects		Region (23)	subjects				0101000020E6100000FFFFFFFF672D40404C2BB927DD1B4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
b23ff422-3cab-4c9f-93a0-149479e03565	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020210&proj=21-rough-cilicia&rows=100&type=subjects		Region (24)	subjects				0101000020E6100000FFFFFFFF0733404042B92FF8211E4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
d2eaa7e0-6f63-4a7a-9335-eb7b9700785f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020232&proj=21-rough-cilicia&rows=100&type=subjects		Region (25)	subjects				0101000020E6100000FFFFFFFF07334040C2E4B72153174240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
c3e57654-e6d9-4825-b62e-e484b308169c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020303&proj=21-rough-cilicia&rows=100&type=subjects		Region (26)	subjects				0101000020E610000001000000783B40404C2BB927DD1B4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
fd8cedf0-bdd3-4b9c-8247-c98dbc84525d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020321&proj=21-rough-cilicia&rows=100&type=subjects		Region (27)	subjects				0101000020E610000001000000783B404076A9903598194240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
e3f22b74-ec3b-4b8c-a0e3-08ada459585f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311002120&proj=21-rough-cilicia&rows=100&type=subjects		Region (28)	subjects				0101000020E6100000FFFFFFFFA7384040FA6424DECA344240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
e4adbc63-7ee0-4e2e-8c9c-a1f567865028	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311002320&proj=21-rough-cilicia&rows=100&type=subjects		Region (29)	subjects				0101000020E6100000FFFFFFFFA738404044CAFF16BC2B4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
410ea277-d6f0-47b5-8637-034127083a83	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020300&proj=21-rough-cilicia&rows=100&type=subjects		Region (30)	subjects				0101000020E6100000FFFFFFFFA738404042B92FF8211E4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
c2a283ea-8130-445a-bb81-3a5194ffaf7d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/04c1327d-7b91-4de6-54cb-fa3221e04263		Tomb: Corus-3	subjects			Asia/Turkey/Corus	0101000020E610000008C76E97643740407D96E7C15D2A4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
1dd418f2-b3b3-4fff-b189-181c97d0c2a1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/53e47ad7-a6ac-4830-867e-c715c4e1bac7		Tomb: Hisar-3	subjects			Asia/Turkey/Hisar	0101000020E6100000B437BE17DB4B404059FAD005F5174240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
5d5b0e80-19d7-4fc0-906d-9e55dddc7de8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1fd7c417-f369-4434-c9be-2d544befa280		Tomb: Selinus-5	subjects			Asia/Turkey/Selinus	0101000020E61000007F2777E9702440408C5C813257214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
9d2cad39-d82a-46f6-987a-44f609e614ae	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4e73107f-19b9-4189-80b3-9a294edd7670		Tomb: Selinus-2	subjects			Asia/Turkey/Selinus	0101000020E61000007AEA6887852440407F17955842214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
4e7d57c6-1feb-41a7-a561-48846c0d1342	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/59ae78aa-4387-454e-2bc1-0e2462caf12c		Tomb: Lamos-3	subjects			Asia/Turkey/Lamos	0101000020E6100000822C76C1013A4040612B4FBDC11E4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
e767ae4c-95f8-4162-ba27-79e72f1a5a8e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/c5a349e9-dc60-4f6a-df04-d5717ddc4ba1		Tomb: Gocuk Asari-2	subjects			Asia/Turkey/Gocuk Asari	0101000020E6100000B0A1A36ECA3A40405EC3252A48184240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
3afb4faa-630d-4fa0-a09d-96a95d00f58f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/72ccaa5e-f6e9-4acc-235c-8ed51f32ad62		Tomb: Corus-8	subjects			Asia/Turkey/Corus	0101000020E610000015BC32B962374040388B30A8632A4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
2b3b390c-68a7-422f-b222-b3183e91a88d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/c71691ae-82e6-4ae1-9817-663645551629		Tomb: Selinus-6	subjects			Asia/Turkey/Selinus	0101000020E6100000604E5CD0732440401AEBB0FC58214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
96592f96-0406-4a5f-9766-3078c03a5c87	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d6b1a744-3dcb-43c5-b35d-411eaa7b0994		Tomb: Selinus-4	subjects			Asia/Turkey/Selinus	0101000020E610000087646DF8822440402561F8EB42214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
b88d4118-c2ce-453f-a55b-d593b3f4b018	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f37f6c1a-1575-40ba-b725-3951fd4aeb7d		Tomb: Direvli-7	subjects			Asia/Turkey/Direvli	0101000020E6100000A302AB13E5444040BE10D5083B214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
21746f63-5450-4741-af8b-6aa64b7c8b49	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/044d9840-218e-42d2-7fd0-24b52c9957cb		Tomb: Selinus-8	subjects			Asia/Turkey/Selinus	0101000020E6100000B643479B782440404CC11A6753214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
c3b6d497-a071-4a4b-a95e-2f015098411d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/c2280d01-d42d-4bb3-48c8-ec0443cd5b6a		Tomb: Selinus-7	subjects			Asia/Turkey/Selinus	0101000020E61000003B8501F074244040C2EF8DBE55214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
879b3ba2-227b-4bd3-8f54-ce7312d84920	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a071e18f-f70f-4633-7720-99345f4bfc5a		Tomb: Corus-2	subjects			Asia/Turkey/Corus	0101000020E61000009E6C35B1613740406CFE25CA5A2A4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
3431cafb-5663-4272-9266-b625c859ea8c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b3fcf54d-5cbb-47d7-3ff8-93f4cccdc90e		Tomb: Direvli-6	subjects			Asia/Turkey/Direvli	0101000020E610000012E2C268F3444040428303102D214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
edf3be48-9026-4866-8ae3-ee12005fe080	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/10446dac-5a25-4cb6-fc70-f302dd68f412		Tomb: Corus-9	subjects			Asia/Turkey/Corus	0101000020E6100000F7D0BA1D4C3740406B0597D8C6344240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
02469ae5-c3c1-4731-a077-f0fa977f740c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/251c8c8d-d831-49ec-388b-615d91ca44bf		Tomb: Direvli-3	subjects			Asia/Turkey/Direvli	0101000020E61000003D2F70D4E54440400952297634214240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
e63463f5-a2cc-4470-8be1-5480d617b811	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a6985668-f0ee-49b4-c7f8-12b62703a44d		Tomb: Hisar-2	subjects			Asia/Turkey/Hisar	0101000020E610000065D0E021D24B404097578DA964184240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
5704f419-11b8-428f-b648-c9ae52d429f9	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/105b9874-987e-4334-347a-b755c02f2dab		Tomb: Kir Ahmetler Mah.-5	subjects			Asia/Turkey/Kir Ahmetler Mah.	0101000020E610000091E167122B354040EDC19C87B0154240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
8765b3a7-34ca-468c-acc3-8badb98e0198	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/538eae7b-de79-4fef-42a8-a41ef541f633		Tomb: Kir Ahmetler Mah.-3	subjects			Asia/Turkey/Kir Ahmetler Mah.	0101000020E61000004BE82E8933334040D700216922164240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
fbefb8a5-bf53-40f3-8597-22cdbe1a6627	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/177d4594-ee31-476d-ceed-4f29c3dfa4ba		Tomb: Hisar-1	subjects			Asia/Turkey/Hisar	0101000020E61000007B975A08D54B4040F53C4DA067184240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
e6dc95f0-f430-4d39-b08e-a9080c3dd421	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/05f08e93-f7d5-454b-cf80-1f4983f238b1		Tomb: Lamos-2	subjects			Asia/Turkey/Lamos	0101000020E6100000FE028B0D273A40403550F07F8D1E4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
ac0f011e-723c-433b-8de7-ddbb3bfc98d4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/246cd5fb-0a28-4734-7a0a-3efeeadf3817		Tomb: Kenetepe-3	subjects			Asia/Turkey/Kenetepe	0101000020E610000022FB83F5BD2F404059D72E8EC6314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
ec123cc5-7683-4099-84b4-d8e64b0ec1ec	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/30be6a83-c066-4c4a-0e97-0c98a9588e26		Tomb: Kenetepe-12	subjects			Asia/Turkey/Kenetepe	0101000020E6100000B0404F5EBF2F4040C131D30FCD314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
f9f63db5-f48b-42b4-b432-44d84e6e4b06	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4afd4daf-29c0-42f1-bfe0-630a724114cf		Tomb: Kenetepe-5	subjects			Asia/Turkey/Kenetepe	0101000020E6100000326E7211C22F4040763BF359BB314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
64fb4954-f61c-4454-8f8e-136f984d6c19	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2de6aea2-dbcb-42f9-0dd8-6c71855f1c2b		Tomb: Kenetepe-7	subjects			Asia/Turkey/Kenetepe	0101000020E610000062827DE8C02F404013AE4F52C3314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
068b4007-1a56-4ff4-ac31-1f5d9c8b3846	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/bb71ac64-58bb-4f2d-79b4-801d3e0dd465		Tomb: Kenetepe-21	subjects			Asia/Turkey/Kenetepe	0101000020E6100000E08AFEAFBE2F4040EE5DC5DAC6314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
bf3e9858-3f29-4597-bd93-5756b70c89e1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2c2663ce-458a-4247-5248-ce25abc7cda0		Tomb: Kenetepe-20	subjects			Asia/Turkey/Kenetepe	0101000020E6100000A670F37CBC2F4040292EBFBAC7314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
9a7af881-cb53-48e4-b37a-ebf2db94ca4a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e1516cc3-78d7-42d4-e518-fe0522591aef		Tomb: Selinus-32	subjects			Asia/Turkey/Selinus	0101000020E61000004FEA89B67C244040183A7EC151214240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
a27a56f8-e43b-46a4-b09d-d3e4c6a25fe3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1b7c1650-07b8-4b8f-2ee6-10615a2c3092		Tomb: Gurcam Kale-1	subjects			Asia/Turkey/Gurcam Kale	0101000020E6100000B69E211CB33E40408D7A8846F71A4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
a941a6a0-4a39-4604-95a6-f189639b9653	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/0c8ba163-cc9a-4075-7c33-8a7a3ccd4509		Tomb: Corus-10	subjects			Asia/Turkey/Corus	0101000020E61000008853BD676A374040C28E18A0612A4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
8da3fd78-c686-4ca3-899c-87da6f98aa1a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/de849d82-a0ae-4334-e077-d1db97a47012		Tomb: Nergis Tepe-1	subjects			Asia/Turkey/Nergis Tepe	0101000020E61000000F25DE2A1D244040EB12BCBE622B4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
a5af1ef0-0329-41d5-a6bc-6c56851c833d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a1a229f0-ed2f-4795-3c5c-a9043fe27d6e		Tomb: Asar Tepe-1	subjects			Asia/Turkey/Asar Tepe	0101000020E61000006A462F383D34404016FC36C4F81C4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
527354b7-2604-48ee-9ebc-6f74842c5a86	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/8def2d52-c69d-4e3a-1007-14616d4b0498		Tomb: Kestros-3	subjects			Asia/Turkey/Kestros	0101000020E6100000AF06AC45592A40404016E45F321E4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
1c4434d8-9d32-4ac9-98ca-af80f3e1c9fb	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/8e266593-9d55-45e8-5d16-08bb3fcb736b		Tomb: Corus-1	subjects			Asia/Turkey/Corus	0101000020E610000056E5AD80633740405908BCDD5C2A4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
9314da6e-f6b3-42a7-8420-c6c379248257	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4468ddc0-3f17-4e14-e799-633ccf1f6e18		Tomb: Kenetepe-19	subjects			Asia/Turkey/Kenetepe	0101000020E61000002A956C4CBA2F40402F42256CC7314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
79f381a0-c468-42d5-9e78-bb8e5c4fb4db	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/64ea6815-05b8-4ee4-a27d-37896f52e211		Tomb: Direvli-8	subjects			Asia/Turkey/Direvli	0101000020E6100000C0249529E644404017CD14843C214240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
a6e7abba-de4c-4077-8204-bd320819dee0	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/11e8da71-dd0e-4ad1-afb3-b8fe946bbf03		Tomb: Kir Ahmetler Mah.-2	subjects			Asia/Turkey/Kir Ahmetler Mah.	0101000020E61000001FC7E6151533404077E094A05C164240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
725d44b1-a365-4ca3-aeef-a5bb5db22d2f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/549630d5-5a0c-45a6-b376-a4399242fc74		Tomb: Kenetepe-11	subjects			Asia/Turkey/Kenetepe	0101000020E61000005D2F3474BF2F40407953786DC2314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
df114358-731c-4a92-8543-a4ff30cc782b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/814106ba-c58a-4372-769b-27fc826bcba9		Tomb: Kenetepe-6	subjects			Asia/Turkey/Kenetepe	0101000020E6100000EBB5D1E7C02F4040F581E49DC3314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
e0aff2d0-7390-4bda-9138-5db4960edee3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d356508f-25a0-4f4a-3263-c125c2cf24cf		Tomb: Kenetepe-8	subjects			Asia/Turkey/Kenetepe	0101000020E61000009147ECEAC02F40406D6BD123C2314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
b2329f0d-3746-48af-9729-70fde84078d3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/9ee93348-43ac-4ca5-0c6b-da24c4bd5539		Tomb: Kenetepe-28	subjects			Asia/Turkey/Kenetepe	0101000020E610000036D0D787D02F4040E4086355CE314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
34eb9c3f-e2d0-4339-bc32-8e02b1ac3dd6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/cfe9e9ac-a820-4efc-254e-ebe437d48876		Tomb: Karasin necropolis-2	subjects			Asia/Turkey/Karasin necropolis	0101000020E61000009E9B919C2742404012BBF8D32D174240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
f7c81725-4654-48f8-b944-92c329eba79b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/49cbd60e-dc1f-4a60-2ea2-d233332f3c50		Tomb: Selinus-9	subjects			Asia/Turkey/Selinus	0101000020E6100000710446EA7F24404000D22FF851214240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
b087d2d8-31a4-4247-8123-5bd12618c3b8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/8124ebaa-fe3d-4d54-c6c2-8d36fa0c194e		Tomb: Karasin necropolis-1	subjects			Asia/Turkey/Karasin necropolis	0101000020E6100000971EEACA29424040598210B92E174240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
837ed5d9-50e4-4020-90ba-241560e85b87	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a41800bd-8683-43cd-582c-d085a6d02875		Tomb: Kenetepe-24	subjects			Asia/Turkey/Kenetepe	0101000020E6100000AF2778122A2F404005FE6CBBBB314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
30b899b9-fe19-4e59-aab2-454708cf44a0	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/7b7327d5-6c33-4183-426f-5e95ff19c059		Tomb: Sivaste-5	subjects			Asia/Turkey/Sivaste	0101000020E61000003822AD6B933440401A99F4B5B6364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
3c659d4b-2d7a-4488-9f9d-29e2cb0c1e33	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/57271541-3df6-4c7e-9a6d-019a5cfbf441		Tomb: Sivaste-4	subjects			Asia/Turkey/Sivaste	0101000020E61000003E63784F9234404025645A7AB8364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
2bc0fc53-ad37-42ba-9c9b-4168e8bf3ec7	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e4b4050f-d275-4102-cf30-21683b2b5e26		Tomb: Sivaste-2	subjects			Asia/Turkey/Sivaste	0101000020E610000031367C24883440405350BC90AF364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
caa06c95-261f-49b5-835c-3ab806dd9937	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f874f452-dc90-479c-ba7e-18b6cc66dafa		Tomb: Antioch-9	subjects			Asia/Turkey/Antioch	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
33dfe96b-185a-46f0-bbcd-8b6ad75ef0aa	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/14a85598-7d30-48f8-6a0b-a9491ec86bc9		Tomb: Antioch-6	subjects			Asia/Turkey/Antioch	0101000020E610000093BC42384935404042A87B32B9134240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
5b35aefd-ea43-4165-94c0-a0a0dc4471e2	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1ebdd4bf-7848-4666-a995-a1287a5a2831		Tomb: Antioch-8	subjects			Asia/Turkey/Antioch	0101000020E61000004898F5A4443540401705A846BB134240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
4ca5b5d5-14e9-4692-b112-cad0fe1eb2e6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e4f4a303-048b-465b-4e12-aba822bf048c		Tomb: Antioch-5	subjects			Asia/Turkey/Antioch	0101000020E6100000FBCD82584F3540403DFD56A1B7134240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
48c48408-f4fd-4b1b-bf83-1c000dd9d166	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/28047ce7-19c5-467c-a87e-3f18903e550b		Tomb: Antioch-7	subjects			Asia/Turkey/Antioch	0101000020E6100000B8E7F9D3463540408F243947BA134240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
71d2c0b5-0a43-4d2b-8f3c-4c467102e100	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1b6c81a4-31df-4727-f131-09bf7b7f4085		Tomb: Karasin necropolis-5	subjects			Asia/Turkey/Karasin necropolis	0101000020E610000072103A09214240409A17D47530174240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
190ab2ff-e1b2-4462-a82f-9353dbdc0a80	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/3c27664b-36bc-4e7c-5726-fbe651b965ee		Tomb: Karasin necropolis-4	subjects			Asia/Turkey/Karasin necropolis	0101000020E610000065DAA3DC224240408E686DE02F174240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
2315cb4c-07a9-45a3-ad36-023ffadd1ed4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/48246263-1faf-4246-2756-f00741f3e467		Tomb: Direvli-4	subjects			Asia/Turkey/Direvli	0101000020E610000036D24A08F3444040E2D4FF202F214240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
5ecbb4f5-7cb8-4265-8976-b6efcfe85951	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f6331f3a-b398-4641-3b14-c9e19391052a		Tomb: Kenetepe-17	subjects			Asia/Turkey/Kenetepe	0101000020E610000006CFADA5BA2F40406353F87DC9314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
aebdecd5-f162-4012-908d-385552f2be38	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b317fc0c-13af-467d-4887-c2fbef69488b		Tomb: Direvli-2	subjects			Asia/Turkey/Direvli	0101000020E6100000E21380B9F54440401447583336214240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
a14a90a2-218b-4291-b30a-37f8a24eb0b6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/fcada8a5-e904-4b06-cec4-d248fbe3696e		Tomb: Kenetepe-18	subjects			Asia/Turkey/Kenetepe	0101000020E61000009BB0BB48BA2F404028A6E231C9314240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
ea572d3e-cacb-48ef-a0f9-a06d7631a78c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/0ebc6560-976e-4c67-3ce4-0ab2e0a0b8fb		Tomb: Selinus-10	subjects			Asia/Turkey/Selinus	0101000020E6100000C1C5CC369E24404014AB698B29214240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
0fd4c512-2aac-4b41-8319-e908d1237325	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1304924f-9377-483b-4e4a-04f999bc0e8b		Tomb: IlIca Kale-5	subjects			Asia/Turkey/IlIca Kale	0101000020E610000022C7941732304040D6847A1B17364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
506214e6-45c7-4736-a860-ece2502eed6d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d27e4a9c-1ce7-494e-bad2-018b422d2bf0		Tomb: IlIca Kale-6	subjects			Asia/Turkey/IlIca Kale	0101000020E6100000E5FB77B7113040401C02CB3A31364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
c51cefd8-d565-49c8-a8d2-79f6b3034d2c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/7fb86e29-87fb-4180-7392-91ae606d3f16		Tomb: IlIca Kale-7	subjects			Asia/Turkey/IlIca Kale	0101000020E610000086DC35B6113040406F230AD231364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
69940dea-ccc8-4a7c-9faa-9b732727027a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/9eabe268-9d53-48b0-1929-eec89ae906a3		Tomb: Karasin necropolis-3	subjects			Asia/Turkey/Karasin necropolis	0101000020E610000080F95C54284240401165779A2F174240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
d3a3c613-59f6-43aa-8246-9b90b5c3c0a5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/cbebb10a-945c-4a1f-6234-34b9edaeb764		Tomb: IlIca Kale-2	subjects			Asia/Turkey/IlIca Kale	0101000020E6100000230D34C001304040A778F92950364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
9dc6f669-51a4-4c0b-869f-5ab9f8eff6fc	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/5ee952db-3127-48d4-cfb0-2a03bbd9a894		Tomb: IlIca Kale-8	subjects			Asia/Turkey/IlIca Kale	0101000020E6100000CBD93BA32D30404031EEA3A61F364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
f1fa4c02-8a9d-4071-945a-754cdd78b871	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/8a755ddd-cf9c-45c9-7282-57ca92798450		Tomb: IlIca Kale-10	subjects			Asia/Turkey/IlIca Kale	0101000020E610000002D13879363040403BE398B817364240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
5a5b4f10-5bf9-455c-8cc3-81e7f14b71f5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/328e9881-d476-414a-85ae-a3c812d4e881		Tomb: Lamos-1	subjects			Asia/Turkey/Lamos	0101000020E61000003465E93B263A40403CCD97518B1E4240	\N	\N	25	250	2026-03-08 17:07:27.952858+03
e3fde944-c5e1-436a-8ead-2fffc996ad67	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/45155db2-e0c6-40d1-a2ab-898e95bfe228		Tomb: Kenetepe-10	subjects			Asia/Turkey/Kenetepe	0101000020E61000008C45992EC02F40400DDA0EBAC2314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
e50ebb81-d29b-4bfa-bf32-2de092ec3282	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b96e9ced-3dd3-4e20-af1e-816de9d83f75		Tomb: Kenetepe-4	subjects			Asia/Turkey/Kenetepe	0101000020E6100000B075CA1FE32F404059DA2DF200324240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
31107c1b-2671-451d-855b-eecb894b5b5a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/117ef510-8119-4738-ab43-542bd65003ab		Tomb: Kenetepe-9	subjects			Asia/Turkey/Kenetepe	0101000020E6100000EB64DB2FC02F4040BAB8CF22C2314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
ac98411e-565a-4118-9aaa-d956f6f2d790	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/8fa9bc34-7cab-4a4e-452d-2b70d37f4426		Tomb: Kenetepe-30	subjects			Asia/Turkey/Kenetepe	0101000020E6100000BACB8F09C22F40404BD70231BF314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
acf40931-e502-4c7e-a6c8-838e12e338e3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/9f4d5843-7475-4550-06ca-999fb2f3d4de		Tomb: Kenetepe-26	subjects			Asia/Turkey/Kenetepe	0101000020E61000008A90FCB9CF2F4040F11DA97CD7314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
0f0b9531-fee2-405b-b6aa-991e1fbcef6f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d225debc-bb86-492a-74fe-d5effd1f12f1		Tomb: Kenetepe-29	subjects			Asia/Turkey/Kenetepe	0101000020E610000003F89FE3C02F4040D0B936AFC5314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
0b9fd065-142c-494d-b2c3-d8524cca2aea	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2473cbf9-37a5-47ae-e427-c3aad945449e		Tomb: Kenetepe-27	subjects			Asia/Turkey/Kenetepe	0101000020E61000009B57122CD02F4040553A0E72CD314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
be388972-94c9-460f-a636-c8357ce17eac	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6b6af458-4d60-4f92-baad-fdbbe593d492		Tomb: Kenetepe-25	subjects			Asia/Turkey/Kenetepe	0101000020E6100000B906CFE7D02F4040979F6527CD314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
9e5d6559-76de-4592-9dbc-af591f01e020	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/777b1b54-147b-4fe4-0a6f-7a6917e74af1		Tomb: Frengez Kale-1	subjects			Asia/Turkey/Frengez Kale	0101000020E6100000A6C0D91801444040082D77A89E164240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
94e15326-1994-49fa-b066-f7828b959096	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/27e9850d-8fe0-4b24-b950-d8bdf8d03121		Tomb: Direvli-9	subjects			Asia/Turkey/Direvli	0101000020E61000000DC4707DF1444040454EDB9633214240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
fff40006-6d79-4e82-a74d-425e824b5b93	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/8707b99c-93ec-461a-d964-a0194a8d9d0f		Tomb: Sivaste-1	subjects			Asia/Turkey/Sivaste	0101000020E6100000B6229CDC90344040E48DC4B2B6364240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
bc580fd5-a795-40b9-a2be-b2ab4fcc5d95	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/3ed664bf-633f-47e2-c1c3-aa50a8a32f9c		Tomb: Kenetepe-1	subjects			Asia/Turkey/Kenetepe	0101000020E610000019854D322C304040B2FC125401324240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
6e5586db-6873-42ab-a49f-59b164a2bcd4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b2fe8a5f-60c8-497b-a8d1-c93b5efb1287		Tomb: Sivaste-3	subjects			Asia/Turkey/Sivaste	0101000020E6100000088573D387344040F7819A10A9364240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
653f935a-3a28-4e2f-a586-164d12ca32c7	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/59a1accd-e534-4d2d-2b66-c04f216f67d7		Tomb: Hisar-6	subjects			Asia/Turkey/Hisar	0101000020E61000008B611C96E54B40401696CB8803184240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
667aaf2d-7163-412d-8fc0-657cda319e77	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a75268b3-91a4-4fd7-2856-7edc939b1e7a		Tomb: Hisar-4	subjects			Asia/Turkey/Hisar	0101000020E6100000E8A30880DC4B4040786FDAC6FE174240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
aaccf8e3-aa59-4a9c-80f9-9f2945b2a7e6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/916e3838-0c6f-4358-aaa4-73c0b258d57e		Tomb: Hisar-5	subjects			Asia/Turkey/Hisar	0101000020E610000092D13BF4E14B404094059F2801184240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
1854b7f5-e0a5-4b5c-83e9-6d5c87327290	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a4e8468d-8b15-4827-299b-dfad445389c9		Tomb: Gurcam Kale-2	subjects			Asia/Turkey/Gurcam Kale	0101000020E610000055C1246CAA3E40402DCAF0C8ED1A4240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
95495397-80f5-4704-9141-94182321fded	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1f22a0b9-3741-4b47-39db-d48b66332241		Tomb: Gocuk Asari-3	subjects			Asia/Turkey/Gocuk Asari	0101000020E6100000C9D2E2E79A3A40408E8A28BB53184240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
53a944c5-ce96-41a4-8d37-f304da6dc8af	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/bedcc460-3868-4afb-0f2d-da94f8c150f4		Tomb: IlIca Kale-1	subjects			Asia/Turkey/IlIca Kale	0101000020E61000008A183C6D093040404EE04A3450364240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
9209bf1f-15fa-4fe2-a72f-ada23dfbb2be	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/24e2cd28-d04a-4ad7-867f-7a18f3e533a2		Tomb: Gokcebelen Kale-1	subjects			Asia/Turkey/Gokcebelen Kale	0101000020E6100000E7EE4AFD82424040F8133A54F8134240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
557a4e41-93ca-4b7e-b10a-c8a0f2a7a8d3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b730393e-cfad-410c-20e0-5169a0b05fae		Tomb: Direvli-5	subjects			Asia/Turkey/Direvli	0101000020E6100000E8B30B1FF4444040E76F000530214240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
9effefa2-73d6-4f1e-9264-a857cea3cb67	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4bc22c83-185c-4199-5658-f901ca7dbd80		Tomb: Iotape-29	subjects			Asia/Turkey/Iotape	0101000020E610000041C826B7751E4040D0E769E12E294240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
81dcd8a6-29e0-4736-a64b-0ba589fe23ae	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/248849e0-1ab5-41c6-8610-b781f33ab806		Tomb: Kir Ahmetler Mah.-4	subjects			Asia/Turkey/Kir Ahmetler Mah.	0101000020E610000097E77FC1873340405092E84406164240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
ced846db-8bdc-4c92-891a-3bda378acd74	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/21b95963-22e0-49d5-cdd5-0739a3adb61e		Tomb: Iotape-9	subjects			Asia/Turkey/Iotape	0101000020E6100000159568249D1E404017B1366324294240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
c514f090-baea-465f-b217-88ad068b3876	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/39d50df4-bca2-4376-cc87-e2d1168b6528		Tomb: Iotape-21	subjects			Asia/Turkey/Iotape	0101000020E61000008976BA988B1E40408AFC0293FE284240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
5b27e3b6-741a-4e3e-9a55-092f1075cc96	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/13549c76-856e-4e1a-8f91-82449cf89b18		Tomb: Kenetepe-2	subjects			Asia/Turkey/Kenetepe	0101000020E6100000D0F18FC63A2F4040F93BEB85C8314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
218fc1e0-5ec2-4462-abbc-6be67c34f246	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/c82ddc85-f422-48f1-3268-edf82509ca2d		Tomb: Kenetepe-15	subjects			Asia/Turkey/Kenetepe	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
712fb404-3a48-404b-96aa-ddf8d7c7246e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b8ebf932-1c81-4098-9a0f-57cbd7911dc3		Tomb: Kenetepe-14	subjects			Asia/Turkey/Kenetepe	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
20055c92-06b4-4690-9798-e2a89a771b8c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/7642f3a4-87a4-420e-4539-5ca3ccda1698		Tomb: Frengez Kale-2	subjects			Asia/Turkey/Frengez Kale	0101000020E61000009373410104444040370EE5D99F164240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
a13a9e54-8ea7-4a72-9ee1-d572a3d1e58d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/dfdecad7-3303-45f7-68f4-1e33275ff2a7		Tomb: Frengez Kale-3	subjects			Asia/Turkey/Frengez Kale	0101000020E610000027C5E0C404444040708D19F299164240	\N	\N	25	250	2026-03-08 17:07:27.991117+03
a9f2d7f8-ddf2-4244-9a58-0f93921e0914	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f7e5af96-d750-4faa-55f5-a1eeeef262ae		Tomb: Frengez Kale-5	subjects			Asia/Turkey/Frengez Kale	0101000020E61000002711E15F044440403EFF66F79E164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
68d612c1-6212-4893-bdd4-017ab3d23985	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/12c0c631-fb3e-4959-3f1c-9b20336eb412		Tomb: Frengez Kale-4	subjects			Asia/Turkey/Frengez Kale	0101000020E6100000042159C0044440400F3455E69C164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
20e3b273-eebe-4c22-8443-6313a9a70b3d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/5d6677e3-1c5f-481a-55e8-e582c1dccab8		Tomb: Kenetepe-23	subjects			Asia/Turkey/Kenetepe	0101000020E6100000029E7254872F4040BD6B12B4B0314240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
5b6a8046-7c9c-4fc0-ae9a-b57398faa2e5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/3f25d3e0-dbd3-4110-09df-7dcfe30e16af		Tomb: Selinus-3	subjects			Asia/Turkey/Selinus	0101000020E6100000E7898CB38E2440407616207E3C214240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
f882c497-ef20-46a1-90a8-f654793c911f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e8a557bc-7c33-4a9b-fd92-51bb60c0a302		Tomb: Gocuk Asari-1	subjects			Asia/Turkey/Gocuk Asari	0101000020E6100000C65D31E19F3A4040477343D72E184240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
280e888e-aad3-499a-b510-13bfd9683ee7	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a41c0c8a-7947-443e-77ce-841bd07e67d4		Tomb: IlIca Kale-9	subjects			Asia/Turkey/IlIca Kale	0101000020E61000004F406E1A36304040352B574F18364240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
ab0ff1b1-bf88-41f4-9c77-4337e742516a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/93412968-5af9-4b84-9cf3-230f69c5f66e		Tomb: Nephelion-4	subjects			Asia/Turkey/Nephelion	0101000020E6100000487254C9DB304040EFA5F811A2164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
6dc685e9-df56-4e8f-a29b-e6aab7d6e036	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a3a781c0-cec4-419c-fab0-5efd356066de		Tomb: Nephelion-3	subjects			Asia/Turkey/Nephelion	0101000020E6100000E2B6CF8DDD304040B1BF0DADA5164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
c71cdfd7-6f6c-4dd4-a574-73b7d941deb7	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/93d22f4c-bb67-419e-790b-cc489e20694c		Tomb: Nephelion-1	subjects			Asia/Turkey/Nephelion	0101000020E6100000C5B1CB43E830404060C724C8AD164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
ac6bf257-f58d-4403-a9c1-96158e1dfb31	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/dbaae9ad-84eb-498b-b8b3-d588a7156c6d		Tomb: Nephelion-5	subjects			Asia/Turkey/Nephelion	0101000020E6100000E33124A3DA3040402B10E26FA0164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
5ee1c565-e7eb-42ac-898e-05c7501efb69	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/35b37885-66c2-4b5a-aaa9-65343577c159		Tomb: Nephelion-2	subjects			Asia/Turkey/Nephelion	0101000020E610000009C514B4E23040400338E60AA9164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
e5b860f0-1388-4cfb-9534-3c2683152b00	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e67bdf72-aecb-49b4-c1ab-7c1abe1a6bc6		Tomb: Iotape-2	subjects			Asia/Turkey/Iotape	0101000020E61000009E15C569901E40405240A054F7284240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
b9eb8e79-eef2-47f0-8f96-639333f7790e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2c534617-e376-4376-0a78-4a39802dd105		Tomb: Iotape-1	subjects			Asia/Turkey/Iotape	0101000020E6100000F98C7E138E1E4040F448CD68F5284240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
07d09709-d4bf-4900-b22c-5047572069b8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/cfc2a602-a9ad-4f7b-6972-0b24c466fb85		Tomb: Iotape-3	subjects			Asia/Turkey/Iotape	0101000020E6100000C3C716388F1E4040F8B8C2FDF8284240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
e94de4d9-eda4-40bc-bfc2-3baae0408e4c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/132d6f85-7907-4686-b156-b338acc49bbb		Tomb: Nephelion-12	subjects			Asia/Turkey/Nephelion	0101000020E6100000499F98EDF1304040E646AA52A7164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
52baa05a-380f-4cb2-8d76-571f2022ffaa	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2af84f4f-f5be-422f-a4e6-0e48712031a5		Tomb: Iotape-4	subjects			Asia/Turkey/Iotape	0101000020E6100000A436B38E911E40402CD90CCBFA284240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
8318c18b-9752-4e9b-bf56-0b35586de38f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/38c82210-4e19-4c75-da75-75d57c53ae69		Tomb: Nephelion-10	subjects			Asia/Turkey/Nephelion	0101000020E610000018821423E830404089DA4F29A3164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
331eb8ea-d9d5-42e1-a50c-70c7aa72da46	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6fcea17f-fc05-489a-accc-b3f3a766c6e4		Tomb: Nephelion-11	subjects			Asia/Turkey/Nephelion	0101000020E61000009A5FEE0FEB3040409FFE9A49A7164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
4f7753fa-ab52-4566-ac33-f8ade527c8dd	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/88019195-01d7-4a42-0067-c2cba7deb434		Tomb: Nephelion-14	subjects			Asia/Turkey/Nephelion	0101000020E61000007BBDB9C7EB3040405D4FF8959C164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
5cadbc60-847f-41cd-b7c7-47fe68c30476	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a6beb6a2-098b-4008-4041-3011d221d3cd		Tomb: Nephelion-17	subjects			Asia/Turkey/Nephelion	0101000020E6100000E756A580F6304040AC2A453CA3164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
a063e814-b382-485b-a31c-e643a6b01732	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/df8bbeb9-acb9-41c9-0e5a-592776bdc6dc		Tomb: Nephelion-13	subjects			Asia/Turkey/Nephelion	0101000020E6100000627028D7EF30404047F0B724A4164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
3f53ab48-3b0b-4bdb-bbe4-528b985652dd	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e488f3fb-969d-4dac-a768-1ac686ad775d		Tomb: Nephelion-15	subjects			Asia/Turkey/Nephelion	0101000020E610000006A7361FF43040404A31B4F89C164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
6354fe5c-4604-45bc-938e-78497ec16ac9	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/113ed69c-cb3f-4ca5-98e9-710e372a427b		Tomb: Nephelion-18	subjects			Asia/Turkey/Nephelion	0101000020E610000092DEA259FA304040264575849D164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
6089458c-f6fe-4e80-bf07-237d4c27d994	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/63de1996-0da7-4d15-0676-bac2ff8a2348		Tomb: Nephelion-16	subjects			Asia/Turkey/Nephelion	0101000020E61000008F6FEF1AF43040402CC6D01C9F164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
b12d80bd-58de-4486-a73a-d3366e9cce93	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/dd58c2f7-e06e-485f-a11e-ca91658b4c77		Tomb: Iotape-16	subjects			Asia/Turkey/Iotape	0101000020E610000068FCCA9C911E4040F25F200810294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
658eb22b-309a-4607-bfbc-ae2b003e22e4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/207dda8f-1330-48c3-11b2-b9a3669b55bb		Tomb: Nephelion-6	subjects			Asia/Turkey/Nephelion	0101000020E6100000B85A0620DE30404049E8BA32A0164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
b617fb9c-c7db-4d0e-a6f6-999108e3ac4f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/41342a28-18cd-4752-90dd-654fd45e1ad9		Tomb: Iotape-5	subjects			Asia/Turkey/Iotape	0101000020E61000003172FD58941E40409D1B8986FB284240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
8bdd6771-c828-4029-976c-e3a449fc8bee	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/64d696d7-0bf2-4b8c-afbd-1ef22bcb12db		Tomb: Nephelion-7	subjects			Asia/Turkey/Nephelion	0101000020E610000051B1FF74E230404055DB8F0CA0164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
6f183631-1d4e-4169-a99e-fea4c22c9f75	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b9e53c0e-512a-4fac-e7ed-f6ef10b0edcd		Tomb: Nephelion-8	subjects			Asia/Turkey/Nephelion	0101000020E6100000CD708776E3304040CA3B240899164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
d15f8d53-b755-4105-8188-68ffd5e215f1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/146f2d00-ac52-4a3d-ebdf-6168fc87b853		Tomb: Nephelion-9	subjects			Asia/Turkey/Nephelion	0101000020E610000025462AE7E6304040BB2494DF9E164240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
5b01775b-be90-4682-a38b-d1182319bc6a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6e09e87c-497d-4205-60a9-7ea584baff81		Tomb: Iotape-15	subjects			Asia/Turkey/Iotape	0101000020E610000098C2203C9C1E4040578E77E41B294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
09e7fbaa-0a52-4c4c-a8a9-188dc1d31fa6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/88ae2ad3-10b7-4dc0-95d5-452ba844ea52		Tomb: Iotape-14	subjects			Asia/Turkey/Iotape	0101000020E610000082BF0413A41E404035AF8FF323294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
3ad7e630-a77a-4a50-a452-100e5969fa53	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/92c7e8f5-8699-4812-6fcd-73a1dbd139d2		Tomb: Iotape-10	subjects			Asia/Turkey/Iotape	0101000020E610000057461B2E8F1E4040BE4BCA592F294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
4a1a1a73-f87f-47a2-96a7-14e5cbb523e1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/072a5818-139e-43e7-3394-9ac04f74f047		Tomb: Iotape-20	subjects			Asia/Turkey/Iotape	0101000020E6100000E70DA449B11E4040AB5FC86E0F294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
415a1a9e-41e0-4d79-a2e6-ea71d3329fc4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/0af124c0-28e2-4c88-57a0-1d03ebd3fc83		Tomb: Iotape-17	subjects			Asia/Turkey/Iotape	0101000020E6100000C92911139A1E4040E3FE44E10A294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
4d713d1b-c857-45a3-aba8-be441b1f04f2	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4c1a202e-0fd0-4f9a-3a8d-6ef9a8ad6c7e		Tomb: Iotape-13	subjects			Asia/Turkey/Iotape	0101000020E610000027EC0D84851E404096A2E8C32B294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
cc01828d-115c-4abc-ade5-9c2285d405f2	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/7a13e4bb-1123-40bc-2fba-5b14d8967a41		Tomb: Iotape-11	subjects			Asia/Turkey/Iotape	0101000020E610000011D3F0F3801E40406CBD95DB2C294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
25b74f3e-c48e-4c7a-8cc1-9efb1bf41033	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/86b1c7bc-676d-4031-6b5d-25b00c499323		Tomb: Iotape-19	subjects			Asia/Turkey/Iotape	0101000020E610000052B0EF58A61E4040FB351FF814294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
51c9a594-3dcb-42a3-b843-207ef0cc36bb	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/cbe15e7d-afdc-43fb-369d-a12434fb9dc2		Tomb: Iotape-18	subjects			Asia/Turkey/Iotape	0101000020E61000001B34ECDEA71E4040B67A77F910294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
d4d4b25b-7194-422b-b632-34b4b9514a89	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/14288f8f-ffa8-4801-608f-e2eb2e0b3bff		Tomb: Iotape-7	subjects			Asia/Turkey/Iotape	0101000020E6100000703B3C9D8E1E40401976D6762C294240	\N	\N	25	250	2026-03-08 17:07:28.030514+03
2c1f743d-b5b6-4bf5-8d4d-fb4b06207750	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/26a3987c-0a36-43d3-64e0-3a72991e4a3e		Tomb: Iotape-31	subjects			Asia/Turkey/Iotape	0101000020E61000002E0BFD7E771E40402EA890A73C294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
b601c6e3-cfad-4646-8701-e732509b982e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2e89e289-5ce5-4d18-7d3b-9ed879026656		Tomb: Iotape-12	subjects			Asia/Turkey/Iotape	0101000020E61000007BB6B354831E40403D31678D2C294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
7be01f7d-d904-45c1-a4c9-bd122f2b6b44	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6f886104-11b9-49ec-742f-33beea0cbff5		Tomb: Iotape-34	subjects			Asia/Turkey/Iotape	0101000020E61000009F7FD489781E4040A2D8233737294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
8a90cc76-6b16-4939-acc7-6013eb9821ae	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/7f676b4e-e6b2-4758-4a7f-df26cbec05ac		Tomb: Iotape-35	subjects			Asia/Turkey/Iotape	0101000020E6100000850384837B1E4040D814029836294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
8d66609f-6441-45d0-a813-0c342d185a2f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a7a2315e-c37f-485f-86fc-2b53a0c09738		Tomb: Iotape-6	subjects			Asia/Turkey/Iotape	0101000020E610000067AEDBB9931E404094DC400530294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
b4e556f2-76a0-444f-9f29-894cbfac62f5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b29ea957-83b7-4ff8-8188-01e3e9fb17c4		Tomb: Iotape-33	subjects			Asia/Turkey/Iotape	0101000020E6100000C4160EC6801E4040F7C5E7463F294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
667a47a4-07de-42da-ad83-9802879d6897	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e169f997-d65a-4eb4-e61e-25fb874053f5		Tomb: Iotape-23	subjects			Asia/Turkey/Iotape	0101000020E61000009B33AA25801E4040E5EA8D7BEF284240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
54ae7b4e-da61-4f93-a74d-173e38b21f3a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e43718b4-a29c-48f4-3af8-5325e312b09e		Tomb: Iotape-36	subjects			Asia/Turkey/Iotape	0101000020E6100000CAD78E77811E4040D9AF9E0735294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
61e6f297-e4ef-4e9d-b043-b2c637ebefb3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/75a83804-e8bc-465f-79fd-bb235786bf07		Tomb: Iotape-26	subjects			Asia/Turkey/Iotape	0101000020E61000002E2A56CBA51E404043DFA31F09294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
49507c17-d8e5-4e5b-9e8f-b2ddd59c0a02	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/c3b314f5-4d43-4997-c9b3-520b8c0a34f6		Tomb: Iotape-25	subjects			Asia/Turkey/Iotape	0101000020E6100000C484C93BA41E4040383D5A6206294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
4167ab54-5a73-4670-8b31-9abfa07d875b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/c754c7f9-23f0-4535-e865-deeb5993a6b5		Tomb: Iotape-22	subjects			Asia/Turkey/Iotape	0101000020E6100000A8953AAF4E1E40400575044F25294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
6fc1035e-a706-458f-a1ff-b61b67dfae61	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/415eb573-fbf6-49ae-c15e-5564b2511d4c		Tomb: Iotape-8	subjects			Asia/Turkey/Iotape	0101000020E61000003C01872F971E4040F279A44526294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
d8e1dfef-c44b-472e-8430-acc786c3405f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/47dacb69-9594-442e-8f91-789049ba2de5		Tomb: Iotape-32	subjects			Asia/Turkey/Iotape	0101000020E61000007AD514127A1E4040B7ADD2823C294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
687b8302-5319-4583-89dd-1c1ffc6e3679	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4a619b81-deca-4fee-781b-4ced7a0ab028		Tomb: Iotape-27	subjects			Asia/Turkey/Iotape	0101000020E61000008F4248CCA21E40403C0A21310B294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
89eda334-5aaf-4a80-b1e2-c6ecc29b5c19	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/839e754e-0568-4890-c95a-8c0b09e2b7b0		Tomb: Iotape-24	subjects			Asia/Turkey/Iotape	0101000020E61000001337FADAAB1E4040D4C23C9604294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
3d61345f-dfff-4b66-b3cd-01b913d27ddc	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b6ad40d2-da58-4134-40b3-05226aa6952c		Tomb: Iotape-38	subjects			Asia/Turkey/Iotape	0101000020E6100000ADAFA6998B1E4040C940F91631294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
c2115126-4f7f-42fe-a9a0-13c97d4b8e2f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f526e723-44c3-463e-3cdd-c8225f476496		Tomb: kestros-2	subjects			Asia/Turkey/Kestros	0101000020E6100000B183EFA2542A4040FBD1EC91381E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
33695c1a-d727-4822-9ba8-ac3e0dc6e69e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/91103ce2-eb8e-4db3-3127-43a9edcc3838		Tomb: Iotape-30	subjects			Asia/Turkey/Iotape	0101000020E61000001898158A741E40407C81B45A3B294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
7c03f340-1686-4d97-a669-1e1d4f17b154	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f16796f2-a495-4480-9584-175442113521		Tomb: Iotape-28	subjects			Asia/Turkey/Iotape	0101000020E6100000BF38A748741E40405B9CEFAF37294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
faced6b8-5780-46d1-8168-72df1fb943b6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/cc89b95c-3a69-43cc-3f95-56a1561e9659		Tomb: Iotape-37	subjects			Asia/Turkey/Iotape	0101000020E6100000AF4AD86D861E4040BCF0BD9E33294240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
17a2b02e-9596-4d6c-aaed-d6a9be4683b6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6fa43830-44b9-4fbd-f665-c742fadf904b		Tomb: Dede Tepe-1	subjects			Asia/Turkey/Dede Tepe	0101000020E6100000E49C7D8A082E4040006C27E7171C4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
4db38628-bc12-4e58-9f0d-a44b5d632fb6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/bfba80d0-cc63-4905-8886-2cfd8571f50f		Tomb: Kenetepe-16	subjects			Asia/Turkey/Kenetepe	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
ea6aaf8c-816f-4a62-98a2-3bcccead33f6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/5196bdb8-d27a-4fa5-9cae-77ab4fb3e986		Tomb: Corus-6	subjects			Asia/Turkey/Corus	0101000020E610000060259B82673740405FD517115E2A4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
559771bd-693e-4829-b726-8c2155570401	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1877a054-42b4-4477-5087-e28b60b8e295		Tomb: Corus-7	subjects			Asia/Turkey/Corus	0101000020E610000060259B82673740405FD517115E2A4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
732f580b-4523-4c32-81a4-0b7b7bbe91d7	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2c60bb1e-b863-4d9e-56dc-0b3a76419f20		Tomb: Gokcebelen Kale-2	subjects			Asia/Turkey/Gokcebelen Kale	0101000020E61000009C3237DF884240402C5D667DEF134240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
702cfd16-8d3b-4262-930a-243b2c60cad9	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/0d2af4ac-1ce9-41d9-d3ba-491598332d53		Tomb: Kenetepe-22	subjects			Asia/Turkey/Kenetepe	0101000020E610000000CA9DA1D12F40409D73A6BFCD314240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
d738afd7-28e7-4596-a0e1-e4d2dce637ba	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/850e3246-b93f-48cd-c5d7-42298a853670		Tomb: Sivaste-6	subjects			Asia/Turkey/Sivaste	0101000020E6100000E113BD1C8E344040167948E7B2364240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
c171f65e-a81f-41ff-96c4-a02150afc81a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/738d7c07-5b19-4922-906e-ae1ca869d768		Tomb: IlIca Kale-3	subjects			Asia/Turkey/IlIca Kale	0101000020E6100000C6CEEBBAFD2F4040EF149B2450364240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
07d93e74-75c1-42ca-a59a-1c963490db29	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/82474a93-0d67-4ad4-7af9-d2a7fff8c184		Tomb: IlIca Kale-4	subjects			Asia/Turkey/IlIca Kale	0101000020E6100000C66350B7FD2F4040E87858EA51364240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
6eb0a80e-5a3d-446a-b848-7967317aa414	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1eb15ea7-ec5f-4867-19e8-864c77e5c12b		Tomb: Kestros-1	subjects			Asia/Turkey/Kestros	0101000020E61000003079EA2E5C2A4040424FB9782E1E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
091bb70f-e88a-4b2a-8786-7f953c39772f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/0b51091f-0a8e-461a-8913-f1274c9b7925		Tomb: Kir Ahmetler Mah.-1	subjects			Asia/Turkey/Kir Ahmetler Mah.	0101000020E6100000B0F2570AF9324040CDEC6FE040164240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
1ade8290-9162-4845-a4c2-2f8111081ad1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/58625221-5578-40da-adfd-5682bb985039		Tomb: Corus-5	subjects			Asia/Turkey/Corus	0101000020E610000008C76E97643740407D96E7C15D2A4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
33eaac9b-40ee-418a-b116-519069c5384e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/784d4253-7958-45ff-23d1-893610591b84		Tomb: kestros-5	subjects			Asia/Turkey/Kestros	0101000020E61000001B0147C8612A404014C04139D91D4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
e9134e7e-cc09-40c4-9f02-19e500fd46fe	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/bf1c7a74-02f6-449c-93d3-7f05930e1dbc		Tomb: Lamos-4	subjects			Asia/Turkey/Lamos	0101000020E61000007E7534922D3A404097448BA6921E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
16354493-78dd-411c-b662-718584fd95ad	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2a6f3228-0f07-4b75-90f4-6886eb1663db		Tomb: Kestros-12	subjects			Asia/Turkey/Kestros	0101000020E6100000BFA6FF935C2A40405B1B53452B1E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
64360b98-58e9-4566-8dee-705fd93d1a25	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4c0c2839-45de-477e-1545-3b6dfb5697bb		Tomb: Kestros-15	subjects			Asia/Turkey/Kestros	0101000020E6100000094F4B20632A4040AA7655B9331E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
b20fc4bc-a2ae-4ff4-b198-3296e0d6e6f5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/57bcf1d7-6094-4370-e6de-ba81c927d3cf		Tomb: Kestros-11	subjects			Asia/Turkey/Kestros	0101000020E61000005B3710585A2A4040D64A32BC231E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
1a49043c-0c26-46d8-852d-7a5888b3f513	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/75c929fd-9780-4b59-5ab0-29ecc04357ae		Tomb: Kestros-14	subjects			Asia/Turkey/Kestros	0101000020E6100000C97B5192602A404076DF9466311E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
958ce7af-1e98-4e0c-9164-d5926fae5337	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/28d7b172-3a3a-4431-8d40-aa1e56f6a296		Tomb: Kestros-10	subjects			Asia/Turkey/Kestros	0101000020E61000003D6CF9B3652A40409E1EE3A3281E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
9b9327d0-3647-445f-86f6-ad1a6028ee6b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/fdfc64cd-7867-4095-ea2d-1b52956745f1		Tomb: Kestros-13	subjects			Asia/Turkey/Kestros	0101000020E6100000BFBC5BB45B2A4040BD6B12B4301E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
659eb254-2c72-4e50-ab91-9793323c6b3e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/5e0e1d23-a7f5-445c-c65b-3fd5f7d60aed		Tomb: Kestros-8	subjects			Asia/Turkey/Kestros	0101000020E6100000B74A4D0E612A4040C4A2B7B2231E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
09ac68a5-237f-4dad-a29f-751e657f1fac	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4374b010-6210-4307-1a76-abb72cb79bdc		Tomb: Kestros-6	subjects			Asia/Turkey/Kestros	0101000020E61000003FA23293622A4040215191D8281E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
62f6a901-79cb-43b1-a1f3-d199904c6a54	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/87ac2b9a-4f93-4847-7690-1a5e708875c7		Tomb: Kestros-9	subjects			Asia/Turkey/Kestros	0101000020E6100000AF670056642A40402D61A737271E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
9317f437-1d94-42aa-9d0c-5953e9c63934	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/ccf97c4b-3cf9-4fc4-a948-99589d437c0e		Tomb: Kestros-7	subjects			Asia/Turkey/Kestros	0101000020E610000081B24A65612A40409FCC3FFA261E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
493a6f8d-d6ca-4a84-bae2-27ca19e5d949	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/52001519-5a9d-4d11-d1b7-db1161d2bea0		Tomb: Direvli-1	subjects			Asia/Turkey/Direvli	0101000020E61000002AAC3342E844404076CF70B930214240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
ef7c53e7-de43-4e27-8ec6-7c0cf076407e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/3c161d34-1beb-4ca1-db22-959a77124bb1		Tomb: Antioch-12	subjects			Asia/Turkey/Antioch	0101000020E610000083DFA72698364040052D2CD1BC134240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
f14ff180-8812-4031-909b-8ff21036f0b1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/eb00834d-feb6-474a-48bd-231e1ef2a5fe		Tomb: Kestros-4	subjects			Asia/Turkey/Kestros	0101000020E61000002F464D895E2A4040A73D46F52D1E4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
71010585-a8b7-48e0-907a-f40908d539f4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f92a51aa-f1b5-41df-40f9-2b42841648fe		Tomb: Asar Tepe-2	subjects			Asia/Turkey/Asar Tepe	0101000020E61000008CE1E28F3F344040F4899F73F51C4240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
5bc0835e-e0d3-4ed8-880e-79eab14e8f8d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1bda1d74-d8ba-43c5-4473-cdb34788c763		Tomb: Gokcebelen Kale-3	subjects			Asia/Turkey/Gokcebelen Kale	0101000020E61000009C3237DF884240402C5D667DEF134240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
5e5b7840-e3ee-42ce-97fd-2861fc414424	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f7413bfb-c3d3-4ee2-11e6-31ccce1507f1		Tomb: Selinus-27	subjects			Asia/Turkey/Selinus	0101000020E6100000E4310395712440403DF9EC674E214240	\N	\N	25	250	2026-03-08 17:07:28.080414+03
cb4cf923-2dba-4845-b0f5-e16b4e5b850a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/cc7a95d7-661d-4bbd-da8a-0b7406e11328		Tomb: Selinus-1	subjects			Asia/Turkey/Selinus	0101000020E610000099B8761E6C244040BFFB993050214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
5737745d-f2b4-41e0-b188-c95a7a14d0ce	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/eea27d67-216f-4807-93c8-eaf7dad53f39		Tomb: Selinus-20	subjects			Asia/Turkey/Selinus	0101000020E6100000C34AC3F8822440403E3A1A2C41214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
ed7d44ba-f7e9-49ab-99c2-70b1f43729eb	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/7fe49b3d-4bf9-428a-9787-7db426c38155		Tomb: Selinus-21	subjects			Asia/Turkey/Selinus	0101000020E6100000E32869937D244040EF3F6CC843214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
56d5d01a-545b-4b37-8dc7-52604f08755d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/5413a4b2-881c-4ab6-0d2e-7a3644b0808f		Tomb: Selinus-24	subjects			Asia/Turkey/Selinus	0101000020E61000008436521973244040DC10C22746214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
c079047a-13b7-4753-af31-97263964f4d8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/60785520-ec0a-49f4-20b5-0a831b088641		Tomb: Selinus-30	subjects			Asia/Turkey/Selinus	0101000020E6100000E96E4BA266244040FC65838E4E214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
556daf38-4191-445b-9088-98175ec246c5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/0cc46d41-a953-4b92-8a82-d5fc14e59014		Tomb: Selinus-28	subjects			Asia/Turkey/Selinus	0101000020E610000056E4A5D56F244040FC26A0CB4C214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
c90cd35b-c630-40dd-ab72-c883d32bd49d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d68ac288-8fc0-4de4-2a36-bf42cefa1765		Tomb: Selinus-29	subjects			Asia/Turkey/Selinus	0101000020E610000063E04E5C6D244040A8D60CBA4E214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
dfa12f64-39b8-4376-83d2-2e33e4cc2dc9	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d3b8e378-4dc0-4416-2574-4b0c612b461d		Tomb: Selinus-19	subjects			Asia/Turkey/Selinus	0101000020E61000005B7B3C80872440406896E39940214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
a1888cdc-3047-42d4-b5bc-e97db4f53435	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/5e98548d-d8c6-4992-9fdb-d9b5f9ca6f7b		Tomb: Selinus-23	subjects			Asia/Turkey/Selinus	0101000020E6100000EDE9130E77244040F41CECA845214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
24a0cb4d-3f9a-420d-bcad-de221fb42a98	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b9d85d5a-02c6-49b9-944b-abc9f77dc4d1		Tomb: Selinus-25	subjects			Asia/Turkey/Selinus	0101000020E61000003231A715702440402E626DC648214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
b7f93d16-f979-42cc-9b02-253ba576c882	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210310113233&proj=21-rough-cilicia&rows=100&type=subjects		Region (1)	subjects				0101000020E610000000000000581F4040D243D81078294240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
35fca1a0-ad5b-45ab-870c-146b4c467a9f	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210310131123&proj=21-rough-cilicia&rows=100&type=subjects		Region (2)	subjects				0101000020E610000000000000F824404048A3F2A666204240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
15b8726a-858f-4155-885d-114268ccda28	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311002023&proj=21-rough-cilicia&rows=100&type=subjects		Region (3)	subjects				0101000020E6100000FFFFFFFF373040409A95FD5E87324240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
990b02e8-5602-4751-a168-7f4f4c93ead5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020223&proj=21-rough-cilicia&rows=100&type=subjects		Region (4)	subjects				0101000020E6100000FFFFFFFF37304040C2E4B72153174240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
1b4da464-8878-4528-9c31-81986dfcde1a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210310131311&proj=21-rough-cilicia&rows=100&type=subjects		Region (5)	subjects				0101000020E610000000000000982A404042B92FF8211E4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
4f7f42dd-f3e7-4d53-8083-3c77ee71b984	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311022013&proj=21-rough-cilicia&rows=100&type=subjects		Region (6)	subjects				0101000020E6100000FFFFFFFFD73540407C5BFC94C8124240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
f694a5d0-5c14-4dac-a89b-a433fc0fb25d	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311002003&proj=21-rough-cilicia&rows=100&type=subjects		Region (7)	subjects				0101000020E6100000FFFFFFFF373040409DE3863B0E374240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
ab7a2e11-446f-440a-a850-b5a9181edaa6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311021022&proj=21-rough-cilicia&rows=100&type=subjects		Region (8)	subjects				0101000020E610000000000000E843404048A3F2A666204240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
77ec49e2-1919-41af-b87c-8a09ef1c6934	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311002322&proj=21-rough-cilicia&rows=100&type=subjects		Region (9)	subjects				0101000020E6100000FFFFFFFFA7384040D243D81078294240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
b426cbf0-b0c5-4ba9-b57a-dd13ee29c46e	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311021233&proj=21-rough-cilicia&rows=100&type=subjects		Region (10)	subjects				0101000020E610000000000000584C4040C2E4B72153174240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
4ece3675-9192-45f8-85ad-deb18b543766	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311002013&proj=21-rough-cilicia&rows=100&type=subjects		Region (11)	subjects				0101000020E6100000FFFFFFFFD73540409DE3863B0E374240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
494ae2bc-07ed-4901-8c32-41c94f9addd8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020333&proj=21-rough-cilicia&rows=100&type=subjects		Region (12)	subjects				0101000020E61000000100000018414040C2E4B72153174240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
abb5dca6-e90a-47a7-aced-d163c59295ac	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311021222&proj=21-rough-cilicia&rows=100&type=subjects		Region (13)	subjects				0101000020E610000000000000E8434040C2E4B72153174240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
f94d960a-445a-4fb0-bff0-c6da55439256	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311022011&proj=21-rough-cilicia&rows=100&type=subjects		Region (14)	subjects				0101000020E6100000FFFFFFFFD7354040228F30EC0D154240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
8b132d14-afad-405e-9ac3-d0fbdd3255f3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020301&proj=21-rough-cilicia&rows=100&type=subjects		Region (15)	subjects				0101000020E610000001000000783B404042B92FF8211E4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
1ced1a71-b848-4f0d-b174-dba485971595	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020323&proj=21-rough-cilicia&rows=100&type=subjects		Region (16)	subjects				0101000020E610000001000000783B4040C2E4B72153174240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
ee7dd414-268b-4d70-94db-e8d9445d28d1	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311023000&proj=21-rough-cilicia&rows=100&type=subjects		Region (17)	subjects				0101000020E610000000000000E8434040228F30EC0D154240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
5e369373-dfaf-4845-8f7c-57c980268541	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020212&proj=21-rough-cilicia&rows=100&type=subjects		Region (18)	subjects				0101000020E6100000FFFFFFFF073340404C2BB927DD1B4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
735ebf24-b10c-4649-bbd5-a85595f318cf	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311020312&proj=21-rough-cilicia&rows=100&type=subjects		Region (19)	subjects				0101000020E610000001000000483E40404C2BB927DD1B4240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
edfcbedd-8ff2-4cdf-a09c-5b715a71c356	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/query/?allevent-geotile=12210311022010&proj=21-rough-cilicia&rows=100&type=subjects		Region (20)	subjects				0101000020E6100000FFFFFFFF07334040228F30EC0D154240	\N	\N	25	250	2026-03-08 17:07:27.490695+03
e16538ec-65e5-44ac-abff-2e2b47726e56	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/c783082b-e716-48f4-eafb-33a853b0a194		Tomb: Selinus-26	subjects			Asia/Turkey/Selinus	0101000020E61000000DB25D8872244040E685A6B249214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
8e4d2182-06d7-40ad-b770-12b879bf47ab	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/45367439-b97a-4ad9-5581-902b1b7e5fc7		Tomb: Selinus-16	subjects			Asia/Turkey/Selinus	0101000020E610000022E6AB478E2440405DEEBC2232214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
e974ab41-76d9-420e-a370-e821e5b17a70	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/47587e8a-adce-4af0-3ac2-665c5edba752		Tomb: Selinus-12	subjects			Asia/Turkey/Selinus	0101000020E6100000B8C00E3198244040917A153A2B214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
66c0e50f-073a-47ac-bfa2-48a4f11e89f2	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/54983e1b-74f5-409e-2460-a6088ea829f3		Tomb: Selinus-15	subjects			Asia/Turkey/Selinus	0101000020E6100000C20104DE8F2440401D7F793330214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
be581408-c986-4c1d-bd83-d3c9c1ba19e4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/725dc8f6-a828-4b80-1c66-36c22425548e		Tomb: Antioch-13	subjects			Asia/Turkey/Antioch	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
5d2ae895-cacc-470f-a538-1de947552d8a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d43d5b8e-20c8-4067-bd5b-7a94204aa7e7		Tomb: Selinus-18	subjects			Asia/Turkey/Selinus	0101000020E6100000EE7961DF8C2440407BA79FC33E214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
df0a7537-d637-4e5f-ac7b-5e5115373b43	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f6aca18b-42fc-4e82-98f1-9f71a22749ba		Tomb: Selinus-22	subjects			Asia/Turkey/Selinus	0101000020E61000002DC83B2C79244040488C1A2344214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
a93dd96b-056b-4e90-bb2c-b1a90768e486	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/ffa7ea00-899f-4048-f30e-738a53be021c		Tomb: Hisar-7	subjects			Asia/Turkey/Hisar	0101000020E61000002A2D2B66E74B4040AAFF205005184240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
21d93445-d4b2-41c3-bec3-7ccd01c509d5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/08b077a1-796f-490a-f840-1813471b7a15		Tomb: Selinus-11	subjects			Asia/Turkey/Selinus	0101000020E610000036F5EC7FA1244040C8E051F826214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
0a9c581f-00f5-4e03-9cd9-d1f877bd98b2	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4c696be2-b655-4e5b-7093-dab7f41c8556		Tomb: Selinus-13	subjects			Asia/Turkey/Selinus	0101000020E6100000D1B0398396244040960256372C214240	\N	\N	25	250	2026-03-08 17:07:28.141648+03
e0f88465-75a3-43eb-b856-76ea15f99229	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/ec65df53-923e-40ca-5116-b0009010fbe4		Tomb: Selinus-17	subjects			Asia/Turkey/Selinus	0101000020E610000001D22787892440402635D50F41214240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
410d42ba-f85e-4208-8eef-3e03d2e7fe7a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/8ef06447-343c-4d4a-8889-32e0fc45bbc3		Tomb: Selinus-14	subjects			Asia/Turkey/Selinus	0101000020E6100000929966159124404095360B6A2E214240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
c619e642-9686-4322-bed6-32e58c3f410c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6640884c-8d69-44d0-1a41-884c454854cb		Tomb: Selinus-33	subjects			Asia/Turkey/Selinus	0101000020E610000013E1157772244040D0AC538251214240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
c74b5bbf-6872-4b32-a390-b08d501b2453	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6a78d88f-0bbf-41b6-8baf-3cb277cf923b		Tomb: Selinus-34	subjects			Asia/Turkey/Selinus	0101000020E61000005059C99E6F244040527BB6B354214240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
c469e342-426f-47ce-8f87-5ccef10485f9	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/42652394-78af-46a2-6d7d-1f78cccfa71b		Tomb: Selinus-31	subjects			Asia/Turkey/Selinus	0101000020E61000000748B0487E2440406FA4852E55214240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
e49748a3-fef0-43ce-8fae-3e5ec736ebff	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d44dd42d-53fc-4d18-c9b5-739eb30deaf9		Tomb: Karasin necropolis-6	subjects			Asia/Turkey/Karasin necropolis	0101000020E61000009E9B919C2742404012BBF8D32D174240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
b50c8ca7-1f5a-45b7-a54f-11e0e147c5a3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/80285f76-ed41-41b5-6432-6a6fcb2cc738		Tomb: Lamos-5	subjects			Asia/Turkey/Lamos	0101000020E6100000B177563D263A4040487B51F58A1E4240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
7315a4a4-61a9-46cd-90de-502524923067	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/0fe6bfee-355b-49db-076a-eddef71cfdc8		Tomb: Antioch-14	subjects			Asia/Turkey/Antioch	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
5e3ff0f1-19dd-4e5d-b74e-769f7a57cac8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b34e5aa9-0122-4814-508a-4eec2a899b9b		Tomb: Antioch-15	subjects			Asia/Turkey/Antioch	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
b1b94a0c-adaa-4eb5-bd3d-53723a2e7664	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/69952fef-36e9-42a8-10b5-e78716c8b31a		Tomb: selinus-35	subjects			Asia/Turkey/Selinus	0101000020E6100000929966159124404095360B6A2E214240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
2c2ff635-90dd-4545-bcdf-bbbdd508e476	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/08aa15a8-5640-4361-ad8e-006be1152a09		Tomb: Meraklar Mah-1	subjects			Asia/Turkey/Meraklar Mah	0101000020E610000050EF3546632A40408A39083A5A264240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
00826570-d93d-4dc1-9f41-8ad3cf0d58e8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6917fe80-e4f1-4e01-0406-34557339b03b		Tomb: Gozkaya Tepe-1	subjects			Asia/Turkey/Gozkaya Tepe	0101000020E6100000BA7E66B5E5334040406C86A7991D4240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
b35ebe47-5409-4e58-9402-e9f5c5268491	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6f35f04d-9ddb-4bba-073d-f10077f3a6bc		Tomb: Goktas Tepe-1	subjects			Asia/Turkey/Goktas Tepe	0101000020E61000007B6DF439903B4040CB19E5F4501C4240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
6bf95fc6-1809-4800-a55f-9bcb56f9cc40	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d85669ab-918f-4212-f81e-609e2b89aa1a		Tomb: Antioch-1	subjects			Asia/Turkey/Antioch	0101000020E61000002D250D66FA3640406CDEE5E0A1134240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
50d8a917-365d-43ca-b761-a2dbfd2aeb09	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/5fda657b-e165-4126-ae67-48cded5ae2b8		Tomb: Antioch-2	subjects			Asia/Turkey/Antioch	0101000020E61000005E7BEA812437404099765A4CA6134240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
17d4c421-6ec0-4638-a7f5-10af86d83521	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2cfcff1a-3371-4652-9a41-09ddf136d26b		Tomb: Antioch-10	subjects			Asia/Turkey/Antioch	0101000020E610000050AFAD0229374040DFC40C6428144240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
0d7008d8-d03d-40c8-92e1-c18f30e8b317	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/3a03c817-bea9-4dc1-1173-e456e797ddd9		Tomb: Antioch-3	subjects			Asia/Turkey/Antioch	0101000020E6100000DC2C7F3AF53540401425DF74E4134240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
b97c4eea-608e-4218-9274-995726d87651	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b060ae3f-e7fd-4ec5-d993-de1f92de50bd		Tomb: Antioch-4	subjects			Asia/Turkey/Antioch	0101000020E6100000C32B8BBABD3640401BE914FD04144240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
321c67a6-6623-415d-82b5-9878ee2ebb87	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/9da6613d-e5fd-44ed-4ae4-f1adfc2d5335		Tomb: Antioch-11	subjects			Asia/Turkey/Antioch	0101000020E6100000BCCCF26D2837404078A7F1C121144240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
dc099c18-c3bf-450c-ae2b-ccdd3c12cfd8	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/15299192-5d17-4dc6-b304-e7c38a77256f		Tomb: Meydancik Tepe-1	subjects			Asia/Turkey/Meydancik Tepe	0101000020E6100000ABE552855435404063D2BE3DF8144240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
115f69dc-764c-4a32-b8af-61e041c5dc05	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/16c2ecda-0056-4fc8-7cc0-cdba54ebf897		Tomb: Sunbuller-1	subjects			Asia/Turkey/Sunbuller	0101000020E6100000132A3E9A9F3A4040E458B44337194240	\N	\N	25	250	2026-03-08 17:07:28.202212+03
999685b1-3338-4962-81c2-df37057ba8ee	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/efea6977-b1a1-4899-9d0f-be0f7782113b		Iotape	subjects			Asia/Turkey	0101000020E6100000C5FADC528D1E4040B28921611D294240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
77209345-1d2e-43d1-a86c-39f48388ec29	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/860270ef-5a56-40af-2db1-4ee8d96195b1		Selinus	subjects			Asia/Turkey	0101000020E6100000828355DC7F244040B49A882A44214240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
efc578ab-05e5-4726-8880-a5fc6092d328	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e49d2e0d-dbba-46aa-4921-cd9eee25ff30		Kenetepe	subjects			Asia/Turkey	0101000020E610000003B0DEF1BA2F40401067AE5ECA314240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
72b7887d-7565-4862-8abd-e0565a6aaec9	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/ddf39997-c412-4cd2-8d9f-549f71368099		Nephelion	subjects			Asia/Turkey	0101000020E61000006E247D18E9304040CEDA8623A2164240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
6595a06e-5e42-47bc-aa73-89227d78f6d6	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/dfb462d0-6333-4647-ab9e-064053fc2dfc		Antioch	subjects			Asia/Turkey	0101000020E6100000C25A990600364040CF0AD555CF134240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
ba2d551f-9d30-4425-805d-170dfdf9a5b5	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/858205a3-660b-45f6-a48f-ab88d716ee12		Kestros	subjects			Asia/Turkey	0101000020E610000014E086EB5E2A404030E8C6FC261E4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
ca06c9d8-8a0d-4f19-87d3-c99deee30c49	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/3c62301a-cf06-4b4b-505d-b2e8bdc8f48a		IlIca Kale	subjects			Asia/Turkey	0101000020E61000004A30C8A21830404095F4356D34364240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
07920cb7-42db-4938-a7c6-85614902788a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/7da849da-9421-4219-b516-22a230f4b67c		Corus	subjects			Asia/Turkey	0101000020E6100000DF84EC036337404053482FF3682B4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
e0396531-a87b-4731-9830-e844065a4b56	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b23a9987-59d3-49a2-bde9-58e92650c5e3		Direvli	subjects			Asia/Turkey	0101000020E610000039B2A8ADED4440404AD114DC33214240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
42d77c3a-03d3-4ef1-a0a7-53cd61b2b3c3	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/6955a00d-0c2d-48d7-0e9a-2471321cdb74		Karasin necropolis	subjects			Asia/Turkey	0101000020E6100000E1090C3526424040F4249F0D2F174240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
486479fb-339a-4920-b2ff-28ff7bab73c9	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/9a067e37-e45f-45f8-b3c8-5495fd0556a7		Hisar	subjects			Asia/Turkey	0101000020E6100000B260A562DD4B404062F1DDDE1C184240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
27b80c35-a06f-4456-92c9-dc347f361825	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1958ab54-7e80-498c-3c2a-0d548d5815a8		Sivaste	subjects			Asia/Turkey	0101000020E6100000E113BD1C8E344040167948E7B2364240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
ab378c35-b7c5-4ec5-a789-6c781d62e356	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b2ea397e-b17a-44b6-786f-cf8e50ac222a		Kir Ahmetler Mah.	subjects			Asia/Turkey	0101000020E6100000A748444C97334040123A22BE17164240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
57d22a55-4ae4-4622-89c4-eb32baa0936c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/defd1a73-1214-4295-4141-15e2d8de7ae0		Frengez Kale	subjects			Asia/Turkey	0101000020E61000001C6FA4CC0344404032FF09AA9D164240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
79200a63-31d7-4aba-aab7-39ec91f0ebe2	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a2f1d967-1df4-47b6-7a2e-3e88b00743a3		Lamos	subjects			Asia/Turkey	0101000020E610000060801792203A404023688A08981E4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
a47788d9-9f85-4b02-8641-dde0d42ccbc4	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/ebe8692e-b487-4310-46cb-779d68fb5fa5		Gokcebelen Kale	subjects			Asia/Turkey	0101000020E6100000B5C63DE9864240409FEFAC6FF2134240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
11f8cc3d-5c8f-4ff4-a788-57b0c74b143c	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/63a2e81a-abad-4294-f1fc-014c5a456b0a		Gocuk Asari	subjects			Asia/Turkey	0101000020E6100000C0F0E767AC3A40408D95309443184240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
dc642837-8911-4473-81fb-d5d98698cf29	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/e9b39c92-2796-44e3-7281-c60823f9832c		Gurcam Kale	subjects			Asia/Turkey	0101000020E6100000063023C4AE3E40405DA2BC87F21A4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
cd56e140-5ddf-430d-8c5f-be89c6c8633b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/f04ce262-d5c8-4cea-efcf-546faf4a6332		Meydancik Tepe	subjects			Asia/Turkey	0101000020E6100000ABE552855435404063D2BE3DF8144240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
e38ad564-1696-42b2-b26e-eb3e0359b94b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/484e5d72-f954-43c7-a26c-71772519e88f		Asar Tepe	subjects			Asia/Turkey	0101000020E6100000FB1309643E3440400543EB1BF71C4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
420e0c8b-85a1-437c-b447-3961535e0b7b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/a86865a5-88c3-4122-3673-4f2b80407b69		Gozkaya Tepe	subjects			Asia/Turkey	0101000020E6100000BA7E66B5E5334040406C86A7991D4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
c57040fe-a3c6-42b1-a6bc-2e400a4d3600	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/b1619628-933b-43fe-0718-be842bb496c6		Meraklar Mah	subjects			Asia/Turkey	0101000020E610000050EF3546632A40408A39083A5A264240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
14269610-9f98-4f1e-8ffe-d240d141264b	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/1d8be001-1e66-4067-8a7b-ed1d85a214de		Nergis Tepe	subjects			Asia/Turkey	0101000020E61000000F25DE2A1D244040EB12BCBE622B4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
0442db1c-20aa-490c-a616-b48065650389	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/4ffec74a-b676-4d85-5c4f-f0944f70a76b		Goktas Tepe	subjects			Asia/Turkey	0101000020E61000007B6DF439903B4040CB19E5F4501C4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
1e752476-e72c-4109-b729-714c028bc4b7	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/2a50603a-92f8-42de-ca9c-4b1d45e91388		Dede Tepe	subjects			Asia/Turkey	0101000020E6100000E49C7D8A082E4040006C27E7171C4240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
b78f4898-efe7-4221-a019-3541f92d558a	295b5bf4-0f44-4698-80cd-7a39cb6f133d	\N	https://opencontext.org/subjects/d26eca07-b534-490c-7b5f-aa8886102407		Sunbuller	subjects			Asia/Turkey	0101000020E6100000132A3E9A9F3A4040E458B44337194240	\N	\N	\N	\N	2026-03-08 17:07:28.202212+03
\.


--
-- TOC entry 4767 (class 0 OID 22727)
-- Dependencies: 237
-- Data for Name: types; Type: TABLE DATA; Schema: cilicia; Owner: postgres
--

COPY cilicia.types (uuid, project_uuid, oc_uri, slug, label, predicate_uuid) FROM stdin;
\.


--
-- TOC entry 4772 (class 0 OID 22816)
-- Dependencies: 245
-- Data for Name: finds; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.finds (id, subject_id, label, category, period, latitude, longitude, geom, site_id, tomb_type, typology, inscribed, feature_desc, material, detail, comment, has_note, length, width, thick, elevation, utm_x, utm_y) FROM stdin;
350	#record-1-of-257	Tomb: Antioch-1	Feature	25 - 250	36.15337764	32.42951656	0101000020E61000002D250D66FA3640406CDEE5E0A1134240	1	2	2 storey vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	305	448683.1699	4001111.225
351	#record-2-of-257	Tomb: Antioch-2	Feature	25 - 250	36.15351252	32.43080162	0101000020E61000005E7BEA812437404099765A4CA6134240	1	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	350	448798.8536	4001125.507
352	#record-3-of-257	Tomb: Antioch-3	Feature	25 - 250	36.15540944	32.42154628	0101000020E6100000DC2C7F3AF53540401425DF74E4134240	1	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	225	447967.5522	4001340.832
353	#record-4-of-257	Tomb: Antioch-4	Feature	25 - 250	36.15640224	32.42766506	0101000020E6100000C32B8BBABD3640401BE914FD04144240	1	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	349	448518.5964	4001447.691
354	#record-5-of-257	Tomb: Antioch-5	Feature	25 - 250	36.15404145	32.41648394	0101000020E6100000FBCD82584F3540403DFD56A1B7134240	1	2	LR Vault tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	447511.2731	4001191.821
355	#record-6-of-257	Tomb: Antioch-6	Feature	25 - 250	36.15408927	32.41629699	0101000020E610000093BC42384935404042A87B32B9134240	1	2	LR Vault tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	447494.4883	4001197.226
356	#record-7-of-257	Tomb: Antioch-7	Feature	25 - 250	36.15412226	32.416224	0101000020E6100000B8E7F9D3463540408F243947BA134240	1	2	LR Vault tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	447487.9451	4001200.924
357	#record-8-of-257	Tomb: Antioch-8	Feature	25 - 250	36.15415271	32.41615736	0101000020E61000004898F5A4443540401705A846BB134240	1	2	LR Vault tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	447481.9709	4001204.338
360	#record-11-of-257	Tomb: Antioch-12	Feature	25 - 250	36.15419974	32.42651828	0101000020E610000083DFA72698364040052D2CD1BC134240	1	2	tomb inscription	to memna koinos	\N	corporate tomb	\N	in modern house	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	290	448414	4001204
361	#record-12-of-257	Tomb: Antioch-13	Feature	25 - 250	36.15435074	32.41626659	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	1	2	inscribed tomb	koinon taphos	corporate tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	190	447491.9279	4001226.244
362	#record-13-of-257	Tomb: Antioch-14	Feature	25 - 250	36.15435074	32.41626659	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	1	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	200	447491.9279	4001226.244
363	#record-14-of-257	Tomb: Antioch-15	Feature	25 - 250	36.15435074	32.41626659	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	1	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	205	447491.9279	4001226.244
364	#record-15-of-257	Tomb: Antioch-9	Feature	25 - 250	36.15435074	32.41626659	0101000020E6100000D53B3F3948354040EA34DAC3C1134240	1	2	LR Vault tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	447491.9279	4001226.244
365	#record-16-of-257	Tomb: Asar Tepe-1	Feature	25 - 250	36.22634175	32.40811827	0101000020E61000006A462F383D34404016FC36C4F81C4240	2	1	temple tomb 1	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	544	446807.6706	4009215.921
366	#record-17-of-257	Tomb: Asar Tepe-2	Feature	25 - 250	36.22624059	32.40818976	0101000020E61000008CE1E28F3F344040F4899F73F51C4240	2	1	temple tomb 2	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	546	446814.027	4009204.661
367	#record-18-of-257	Tomb: Corus-1	Feature	25 - 250	36.33095905	32.43272408	0101000020E610000056E5AD80633740405908BCDD5C2A4240	3	3	dressed block	\N	\N	\N	without relief	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	110	80	55	517	449087	4020807
368	#record-19-of-257	Tomb: Corus-10	Feature	25 - 250	36.33110429	32.43293473	0101000020E61000008853BD676A374040C28E18A0612A4240	3	3	dressed block	\N	\N	necropolis	no relief	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	170	65	40	513	449106	4020823
369	#record-20-of-257	Tomb: Corus-2	Feature	25 - 250	36.33089568	32.43266883	0101000020E61000009E6C35B1613740406CFE25CA5A2A4240	3	3	dressed block with relief	\N	\N	triangular roof gable	birds on vine	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	75	60	80	524	449082	4020800
370	#record-21-of-257	Tomb: Corus-3	Feature	25 - 250	36.33098625	32.43275731	0101000020E610000008C76E97643740407D96E7C15D2A4240	3	3	dressed block with relief	\N	\N	2 figures	figure on horse with standing figure in front	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	90	70	50	518	449090	4020810
371	#record-22-of-257	Tomb: Corus-4	Feature	25 - 250	36.33099569	32.43284638	0101000020E610000060259B82673740405FD517115E2A4240	3	3	dressed block with relief	\N	\N	damaged	possible tree	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	90	95	55	518	449098	4020811
372	#record-23-of-257	Tomb: Corus-5	Feature	25 - 250	36.33098625	32.43275731	0101000020E610000008C76E97643740407D96E7C15D2A4240	3	3	dressed block	\N	\N	\N	no relief	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	70	125	40	518	449090	4020810
373	#record-24-of-257	Tomb: Corus-6	Feature	25 - 250	36.33099569	32.43284638	0101000020E610000060259B82673740405FD517115E2A4240	3	3	dressed block with relief	\N	\N	plough scene	man ploughing with oxen	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	116	32	70	518	449098	4020811
374	#record-25-of-257	Tomb: Corus-7	Feature	25 - 250	36.33099569	32.43284638	0101000020E610000060259B82673740405FD517115E2A4240	3	3	dressed block with relief	\N	\N	2 figures	1 seated, one reclining	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	118	62	81	518	449098	4020811
375	#record-26-of-257	Tomb: Corus-8	Feature	25 - 250	36.33116629	32.4327003	0101000020E610000015BC32B962374040388B30A8632A4240	3	4	larnax base	\N	\N	necropolis	standing figure w grapes	heads in intaglio on sides	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	70	84	55	513	449085	4020830
376	#record-27-of-257	Tomb: Corus-9	Feature	25 - 250	36.4123183	32.43201038	0101000020E6100000F7D0BA1D4C3740406B0597D8C6344240	3	4	larnax base	\N	\N	necropolis	3 standing figures	heads in intaglio on sides	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	110	80	50	512	449076	4029832
377	#record-28-of-257	Tomb: Dede Tepe-1	Feature	25 - 250	36.21947946	32.35963565	0101000020E6100000E49C7D8A082E4040006C27E7171C4240	4	2	necropolis	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	346	442445.4644	4008482.445
378	#record-29-of-257	Tomb: Direvli-1	Feature	25 - 250	36.25929945	32.53833797	0101000020E61000002AAC3342E844404076CF70B930214240	5	3	corporate tomb	\N	\N	inscribed limestone block	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	85	59	\N	980	458528	4012808
379	#record-30-of-257	Tomb: Direvli-2	Feature	25 - 250	36.25946657	32.53874892	0101000020E6100000E21380B9F54440401447583336214240	5	1	ruined temple tomb	\N	\N	\N	\N	described as ruins of temple tomb	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	1000	458565.005	4012826.361
380	#record-31-of-257	Tomb: Direvli-3	Feature	25 - 250	36.2594135	32.53826385	0101000020E61000003D2F70D4E54440400952297634214240	5	3	rock cut tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	980	458521.4019	4012820.683
381	#record-32-of-257	Tomb: Direvli-4	Feature	25 - 250	36.25925076	32.53866676	0101000020E610000036D24A08F3444040E2D4FF202F214240	5	3	rock cut tomb	koinon memnes	\N	corporate tomb	\N	inscribed on sarcophagus lid	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	980	458557.5103	4012802.459
382	#record-33-of-257	Tomb: Direvli-5	Feature	25 - 250	36.25927794	32.53869999	0101000020E6100000E8B30B1FF4444040E76F000530214240	5	3	rock cut tomb	koinon memnes	\N	corporate tomb	\N	inscribed on lid	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	980	458560.5103	4012805.459
383	#record-34-of-257	Tomb: Direvli-6	Feature	25 - 250	36.2591877	32.53867826	0101000020E610000012E2C268F3444040428303102D214240	5	3	rock cut tomb	\N	\N	\N	\N	inscribed on lid	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	976	458558.5103	4012795.459
384	#record-35-of-257	Tomb: Direvli-7	Feature	25 - 250	36.25961409	32.53824087	0101000020E6100000A302AB13E5444040BE10D5083B214240	5	3	rock cut tomb	koinon ta memna	\N	corporate tomb	acroteria with pediment bust	open door with busts	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	1040	458519.4433	4012842.942
385	#record-36-of-257	Tomb: Direvli-8	Feature	25 - 250	36.2596593	32.538274	0101000020E6100000C0249529E644404017CD14843C214240	5	3	rock cut tomb	koinon ta memna	\N	corporate tomb	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	1040	458522.4433	4012847.942
386	#record-37-of-257	Tomb: Direvli-9	Feature	25 - 250	36.25938688	32.53861969	0101000020E61000000DC4707DF1444040454EDB9633214240	5	3	rock cut tomb	to memna	get photo of steps	corporate tomb	approached by steps	ruined, mutilated bust	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	980	458553.3535	4012817.577
387	#record-38-of-257	Tomb: Frengez Kale-1	Feature	25 - 250	36.17671686	32.53128348	0101000020E6100000A6C0D91801444040082D77A89E164240	6	2	vaulted tombs	\N	\N	blocks w mortar	2 tiers of tombs	upper level set against cliff	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	198	273	188	880	457850	4003651
388	#record-39-of-257	Tomb: Frengez Kale-2	Feature	25 - 250	36.17675327	32.53137222	0101000020E61000009373410104444040370EE5D99F164240	6	2	vaulted tombs	\N	\N	blocks w mortar	2 tiers of tombs	upper level set against cliff	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	897	457858	4003655
389	#record-40-of-257	Tomb: Frengez Kale-3	Feature	25 - 250	36.17657305	32.53139554	0101000020E610000027C5E0C404444040708D19F299164240	6	2	vaulted tombs	\N	\N	blocks w mortar	2 tiers of tombs	upper level set against cliff	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	898	457860	4003635
390	#record-41-of-257	Tomb: Frengez Kale-4	Feature	25 - 250	36.1766632	32.531395	0101000020E6100000042159C0044440400F3455E69C164240	6	2	vaulted tombs	\N	\N	blocks w mortar	2 tiers of tombs	upper level set against cliff	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	898	457860	4003645
391	#record-42-of-257	Tomb: Frengez Kale-5	Feature	25 - 250	36.17672627	32.5313835	0101000020E61000002711E15F044440403EFF66F79E164240	6	2	vaulted tombs	\N	\N	blocks w mortar	2 tiers of tombs	upper level set against cliff	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	897	457859	4003652
392	#record-43-of-257	Tomb: Gocuk Asari-1	Feature	25 - 250	36.18892947	32.45800414	0101000020E6100000C65D31E19F3A4040477343D72E184240	7	5	poss urn field	\N	numerous stamnos rims	\N	visible stone casements	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	664.27	451267.76	4005039.93
446	#record-97-of-257	Tomb: Iotape-28	Feature	25 - 250	36.32201194	32.2379237	0101000020E6100000BF38A748741E40405B9CEFAF37294240	14	2	vault tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	431595.5797	4019934.746
393	#record-44-of-257	Tomb: Gocuk Asari-2	Feature	25 - 250	36.18970229	32.45930274	0101000020E6100000B0A1A36ECA3A40405EC3252A48184240	7	3	rock cut tomb	\N	heads in intaglio	limestone	open top for gable roof	long unreadable inscription	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	344	135	53	685	451385	4005125
394	#record-45-of-257	Tomb: Gocuk Asari-3	Feature	25 - 250	36.19005527	32.45785235	0101000020E6100000C9D2E2E79A3A40408E8A28BB53184240	7	3	poss house tomb	\N	head in intaglio	limestone	stylobate block	archtectural fragment	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	688.77	451254.81	4005164.88
395	#record-46-of-257	Tomb: Gokcebelen Kale-1	Feature	25 - 250	36.1560159	32.51962248	0101000020E6100000E7EE4AFD82424040F8133A54F8134240	8	2	tomb	\N	\N	medium stone w mortar	pi shaped	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	340	115	971	456790	4001360
396	#record-47-of-257	Tomb: Gokcebelen Kale-2	Feature	25 - 250	36.15574615	32.519802	0101000020E61000009C3237DF884240402C5D667DEF134240	8	3	sarcophagus niche	\N	\N	rock cut setting for sarcophagus	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	965	456806	4001330
397	#record-48-of-257	Tomb: Gokcebelen Kale-3	Feature	25 - 250	36.15574615	32.519802	0101000020E61000009C3237DF884240402C5D667DEF134240	8	3	sarcophagus niche	\N	\N	rock cut setting for sarcophagus	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	965	456806	4001330
398	#record-49-of-257	Tomb: Goktas Tepe-1	Feature	25 - 250	36.2212206	32.46533894	0101000020E61000007B6DF439903B4040CB19E5F4501C4240	9	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	667	451947	4008618
399	#record-50-of-257	Tomb: Gozkaya Tepe-1	Feature	25 - 250	36.23125166	32.40544765	0101000020E6100000BA7E66B5E5334040406C86A7991D4240	10	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	524	446571	4009762
400	#record-51-of-257	Tomb: Gurcam Kale-1	Feature	25 - 250	36.21067125	32.489841	0101000020E6100000B69E211CB33E40408D7A8846F71A4240	11	2	tomb	\N	collapsed stone tomb	large stone slabs	human skull found within	skull dated 5th cent AD	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	711	454143	4007436
401	#record-52-of-257	Tomb: Gurcam Kale-2	Feature	25 - 250	36.21038162	32.48957588	0101000020E610000055C1246CAA3E40402DCAF0C8ED1A4240	11	2	sarcophagus niche	\N	rock cut ledge	sarcophagus niche	above larger room	ledge for sarcophagus?	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	300	200	\N	694	454119	4007404
402	#record-53-of-257	Tomb: Hisar-1	Feature	25 - 250	36.19066242	32.59243874	0101000020E61000007B975A08D54B4040F53C4DA067184240	12	2	poss tombs	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	900	463356	4005173
403	#record-54-of-257	Tomb: Hisar-2	Feature	25 - 250	36.19057197	32.59235023	0101000020E610000065D0E021D24B404097578DA964184240	12	2	tomb relief frag	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	907	463348	4005163
404	#record-55-of-257	Tomb: Hisar-3	Feature	25 - 250	36.187165	32.59262368	0101000020E6100000B437BE17DB4B404059FAD005F5174240	12	1	temple tomb?	\N	large ashlar block structure	\N	door on side	no visible entablature	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	920	840	\N	989	463371	4004785
405	#record-56-of-257	Tomb: Hisar-4	Feature	25 - 250	36.18746267	32.59266663	0101000020E6100000E8A30880DC4B4040786FDAC6FE174240	12	2	plundered tomb	\N	\N	tiles & pottery	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	1002	463375	4004818
406	#record-57-of-257	Tomb: Hisar-5	Feature	25 - 250	36.18753536	32.59283307	0101000020E610000092D13BF4E14B404094059F2801184240	12	2	plundered tomb	\N	\N	blocks pottery	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	990	463390	4004826
407	#record-58-of-257	Tomb: Hisar-6	Feature	25 - 250	36.18760786	32.59294392	0101000020E61000008B611C96E54B40401696CB8803184240	12	2	built tomb	\N	\N	pot & tile	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	989	463400	4004834
408	#record-59-of-257	Tomb: Hisar-7	Feature	25 - 250	36.18766214	32.59299924	0101000020E61000002A2D2B66E74B4040AAFF205005184240	12	2	tombs visible	\N	\N	pottery	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	991	463405	4004840
409	#record-60-of-257	Tomb: IlIca Kale-1	Feature	25 - 250	36.42432264	32.37528768	0101000020E61000008A183C6D093040404EE04A3450364240	13	4	larnax	\N	larnax relief	limestone	2 standing human figs	gown with cross folding	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	985	443999	4031195
410	#record-61-of-257	Tomb: IlIca Kale-10	Feature	25 - 250	36.42259891	32.3766624	0101000020E610000002D13879363040403BE398B817364240	13	3	poss tomb frag	\N	fragment of lion relief	limestone	similar to previous	gps location is arbitrary	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	970	444121	4031003
411	#record-62-of-257	Tomb: IlIca Kale-2	Feature	25 - 250	36.42432141	32.37505343	0101000020E6100000230D34C001304040A778F92950364240	13	4	poss larnax	\N	bucranion relief	limestone	corner fragment	small stone monument	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	985	443978	4031195
412	#record-63-of-257	Tomb: IlIca Kale-3	Feature	25 - 250	36.42432077	32.37493073	0101000020E6100000C6CEEBBAFD2F4040EF149B2450364240	13	3	heroion	heroion	grave inscription	\N	ETAM 1998	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	985	443967	4031195
413	#record-64-of-257	Tomb: IlIca Kale-4	Feature	25 - 250	36.42437486	32.3749303	0101000020E6100000C66350B7FD2F4040E87858EA51364240	13	3	heroion	heroion	grave inscription	\N	ETAM 1998	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	985	443967	4031201
414	#record-65-of-257	Tomb: IlIca Kale-5	Feature	25 - 250	36.42258018	32.37652869	0101000020E610000022C7941732304040D6847A1B17364240	13	4	larnax	\N	larnax with inscribed relief	limestone	human figure in flowing gown	1 inscribed line below relief	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	972	444109	4031001
415	#record-66-of-257	Tomb: IlIca Kale-6	Feature	25 - 250	36.42337737	32.37554067	0101000020E6100000E5FB77B7113040401C02CB3A31364240	13	4	poss larnax	\N	relief block fragment	limestone	corner edge visible	human figure in folded cloak	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	960	444021	4031090
416	#record-67-of-257	Tomb: IlIca Kale-7	Feature	25 - 250	36.4233954	32.37554052	0101000020E610000086DC35B6113040406F230AD231364240	13	4	poss larnax	\N	relief block fragment	limestone	relief of human figures	female figure at rt	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	960	444021	4031092
417	#record-68-of-257	Tomb: IlIca Kale-8	Feature	25 - 250	36.42284091	32.37639275	0101000020E6100000CBD93BA32D30404031EEA3A61F364240	13	3	poss house tomb	\N	Relief block	limestone	Relief of a human figure	solid rectangular block	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	972	444097	4031030
418	#record-69-of-257	Tomb: IlIca Kale-9	Feature	25 - 250	36.42261688	32.3766511	0101000020E61000004F406E1A36304040352B574F18364240	13	3	poss tomb frag	\N	Block with lion relief	limestone	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	970	444120	4031005
419	#record-70-of-257	Tomb: Iotape-1	Feature	25 - 250	36.3199893	32.23871082	0101000020E6100000F98C7E138E1E4040F448CD68F5284240	14	1	temple tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	35	431664.4674	4019709.831
420	#record-71-of-257	Tomb: Iotape-2	Feature	25 - 250	36.32004793	32.23878214	0101000020E61000009E15C569901E40405240A054F7284240	14	2	5 large tombs	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	40	431670.9205	4019716.284
421	#record-72-of-257	Tomb: Iotape-3	Feature	25 - 250	36.32009861	32.2387457	0101000020E6100000C3C716388F1E4040F8B8C2FDF8284240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	40	431667.6939	4019721.931
422	#record-73-of-257	Tomb: Iotape-4	Feature	25 - 250	36.3201536	32.23881706	0101000020E6100000A436B38E911E40402CD90CCBFA284240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	40	431674.147	4019727.981
423	#record-74-of-257	Tomb: Iotape-5	Feature	25 - 250	36.32017595	32.23890221	0101000020E61000003172FD58941E40409D1B8986FB284240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	25	431681.81	4019730.4
424	#record-75-of-257	Tomb: Iotape-6	Feature	25 - 250	36.32177797	32.23888324	0101000020E610000067AEDBB9931E404094DC400530294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	65	431681.5058	4019908.115
425	#record-76-of-257	Tomb: Iotape-10	Feature	25 - 250	36.32175753	32.23874451	0101000020E610000057461B2E8F1E4040BE4BCA592F294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	55	431669.0348	4019905.946
426	#record-77-of-257	Tomb: Iotape-11	Feature	25 - 250	36.32168145	32.23831033	0101000020E610000011D3F0F3801E40406CBD95DB2C294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	55	431629.9953	4019897.813
427	#record-78-of-257	Tomb: Iotape-12	Feature	25 - 250	36.32167213	32.2383829	0101000020E61000007BB6B354831E40403D31678D2C294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	55	431636.5019	4019896.728
428	#record-79-of-257	Tomb: Iotape-13	Feature	25 - 250	36.32164811	32.23844958	0101000020E610000027EC0D84851E404096A2E8C32B294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	60	431642.4662	4019894.017
429	#record-80-of-257	Tomb: Iotape-14	Feature	25 - 250	36.32140965	32.23938215	0101000020E610000082BF0413A41E404035AF8FF323294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	55	431725.9675	4019866.907
430	#record-81-of-257	Tomb: Iotape-15	Feature	25 - 250	36.32116371	32.23914291	0101000020E610000098C2203C9C1E4040578E77E41B294240	14	2	ruined tombs	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	55	431704.2789	4019839.796
431	#record-82-of-257	Tomb: Iotape-16	Feature	25 - 250	36.32080175	32.23881874	0101000020E610000068FCCA9C911E4040F25F200810294240	14	2	large chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	431674.8637	4019799.875
432	#record-83-of-257	Tomb: Iotape-17	Feature	25 - 250	36.32064453	32.23907698	0101000020E6100000C92911139A1E4040E3FE44E10A294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	45	431697.9078	4019782.253
433	#record-84-of-257	Tomb: Iotape-7	Feature	25 - 250	36.32166944	32.23872724	0101000020E6100000703B3C9D8E1E40401976D6762C294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	65	431667.4082	4019896.186
434	#record-85-of-257	Tomb: Iotape-8	Feature	25 - 250	36.32148047	32.23898882	0101000020E61000003C01872F971E4040F279A44526294240	14	2	seated tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	65	431690.7235	4019875.04
435	#record-86-of-257	Tomb: Iotape-9	Feature	25 - 250	36.32142296	32.2391706	0101000020E6100000159568249D1E404017B1366324294240	14	2	chamber tomb inscr	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	65	431706.9899	4019868.533
436	#record-87-of-257	Tomb: Iotape-18	Feature	25 - 250	36.32083052	32.23949801	0101000020E61000001B34ECDEA71E4040B67A77F910294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	431735.8629	4019802.586
573	#record-224-of-257	Antioch	Area	\N	36.154764870667	32.421875786667	0101000020E6100000C25A990600364040CF0AD555CF134240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
574	#record-225-of-257	Asar Tepe	Area	\N	36.22629117	32.408154015	0101000020E6100000FB1309643E3440400543EB1BF71C4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
575	#record-226-of-257	Corus	Area	\N	36.339140318	32.432709208	0101000020E6100000DF84EC036337404053482FF3682B4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
576	#record-227-of-257	Dede Tepe	Area	\N	36.21947946	32.35963565	0101000020E6100000E49C7D8A082E4040006C27E7171C4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
577	#record-228-of-257	Direvli	Area	\N	36.259395132222	32.538503367778	0101000020E610000039B2A8ADED4440404AD114DC33214240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
578	#record-229-of-257	Frengez Kale	Area	\N	36.17668653	32.531365948	0101000020E61000001C6FA4CC0344404032FF09AA9D164240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
358	#record-9-of-257	Tomb: Antioch-10	Feature	25 - 250	36.15748263	32.43093904	0101000020E610000050AFAD0229374040DFC40C6428144240	1	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	350	448813.7954	4001565.796
359	#record-10-of-257	Tomb: Antioch-11	Feature	25 - 250	36.1572802	32.43092131	0101000020E6100000BCCCF26D2837404078A7F1C121144240	1	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	45	448812.069	4001543.352
587	#record-238-of-257	Gocuk Asari	Area	\N	36.189562343333	32.45838641	0101000020E6100000C0F0E767AC3A40408D95309443184240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
588	#record-239-of-257	Gokcebelen Kale	Area	\N	36.155836066667	32.51974216	0101000020E6100000B5C63DE9864240409FEFAC6FF2134240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
589	#record-240-of-257	Goktas Tepe	Area	\N	36.2212206	32.46533894	0101000020E61000007B6DF439903B4040CB19E5F4501C4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
590	#record-241-of-257	Gozkaya Tepe	Area	\N	36.23125166	32.40544765	0101000020E6100000BA7E66B5E5334040406C86A7991D4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
591	#record-242-of-257	Gurcam Kale	Area	\N	36.210526435	32.48970844	0101000020E6100000063023C4AE3E40405DA2BC87F21A4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
592	#record-243-of-257	Hisar	Area	\N	36.18838106	32.592693644286	0101000020E6100000B260A562DD4B404062F1DDDE1C184240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
593	#record-244-of-257	IlIca Kale	Area	\N	36.423474933	32.375751827	0101000020E61000004A30C8A21830404095F4356D34364240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
594	#record-245-of-257	Iotape	Area	\N	36.321209088684	32.238687856579	0101000020E6100000C5FADC528D1E4040B28921611D294240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
595	#record-246-of-257	Karasin necropolis	Area	\N	36.18112345	32.516790991667	0101000020E6100000E1090C3526424040F4249F0D2F174240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
596	#record-247-of-257	Kenetepe	Area	\N	36.388988337667	32.372892602667	0101000020E610000003B0DEF1BA2F40401067AE5ECA314240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
597	#record-248-of-257	Kestros	Area	\N	36.235564801333	32.331021729333	0101000020E610000014E086EB5E2A404030E8C6FC261E4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
598	#record-249-of-257	Kir Ahmetler Mah.	Area	\N	36.17259957	32.403054746	0101000020E6100000A748444C97334040123A22BE17164240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
599	#record-250-of-257	Lamos	Area	\N	36.23901469	32.454118978	0101000020E610000060801792203A404023688A08981E4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
600	#record-251-of-257	Meraklar Mah	Area	\N	36.2996285	32.33115461	0101000020E610000050EF3546632A40408A39083A5A264240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
601	#record-252-of-257	Meydancik Tepe	Area	\N	36.16382572	32.41664187	0101000020E6100000ABE552855435404063D2BE3DF8144240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
602	#record-253-of-257	Nephelion	Area	\N	36.176823082778	32.382113515	0101000020E61000006E247D18E9304040CEDA8623A2164240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
603	#record-254-of-257	Nergis Tepe	Area	\N	36.33895096	32.28214012	0101000020E61000000F25DE2A1D244040EB12BCBE622B4240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
604	#record-255-of-257	Selinus	Area	\N	36.259892765714	32.285151998286	0101000020E6100000828355DC7F244040B49A882A44214240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
605	#record-256-of-257	Sivaste	Area	\N	36.4273347	32.410586922	0101000020E6100000E113BD1C8E344040167948E7B2364240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
606	#record-257-of-257	Sunbuller	Area	\N	36.1969990378	32.4579956821	0101000020E6100000132A3E9A9F3A4040E458B44337194240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
437	#record-88-of-257	Tomb: Iotape-19	Feature	25 - 250	36.32095243	32.23945152	0101000020E610000052B0EF58A61E4040FB351FF814294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	35	431731.7963	4019816.142
438	#record-89-of-257	Tomb: Iotape-20	Feature	25 - 250	36.32078347	32.23978539	0101000020E6100000E70DA449B11E4040AB5FC86E0F294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	50	431761.6182	4019797.164
439	#record-90-of-257	Tomb: Iotape-21	Feature	25 - 250	36.32026899	32.23863515	0101000020E61000008976BA988B1E40408AFC0293FE284240	14	2	ruined tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	431657.9194	4019740.909
440	#record-91-of-257	Tomb: Iotape-22	Feature	25 - 250	36.32145107	32.23677626	0101000020E6100000A8953AAF4E1E40400575044F25294240	14	1	temple tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	30	431492.0916	4019873.345
441	#record-92-of-257	Tomb: Iotape-23	Feature	25 - 250	36.31980843	32.23828574	0101000020E61000009B33AA25801E4040E5EA8D7BEF284240	14	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	40	431626.1524	4019690.069
442	#record-93-of-257	Tomb: Iotape-24	Feature	25 - 250	36.32045248	32.23961961	0101000020E61000001337FADAAB1E4040D4C23C9604294240	14	2	temple tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	35	431746.448	4019760.567
443	#record-94-of-257	Tomb: Iotape-25	Feature	25 - 250	36.32050733	32.23938701	0101000020E6100000C484C93BA41E4040383D5A6206294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	40	431725.6172	4019766.815
444	#record-95-of-257	Tomb: Iotape-26	Feature	25 - 250	36.32059093	32.23943464	0101000020E61000002E2A56CBA51E404043DFA31F09294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	45	431729.9656	4019776.055
445	#record-96-of-257	Tomb: Iotape-27	Feature	25 - 250	36.32065405	32.2393432	0101000020E61000008F4248CCA21E40403C0A21310B294240	14	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	60	431721.8124	4019783.121
447	#record-98-of-257	Tomb: Iotape-29	Feature	25 - 250	36.32174318	32.23796739	0101000020E610000041C826B7751E4040D0E769E12E294240	14	1	temple tomb	"late Hellenistic style"	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	65	431599.2668	4019904.903
448	#record-99-of-257	Tomb: Iotape-30	Feature	25 - 250	36.32212385	32.2379315	0101000020E61000001898158A741E40407C81B45A3B294240	14	2	vault tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	70	431596.3779	4019947.154
449	#record-100-of-257	Tomb: Iotape-31	Feature	25 - 250	36.32216353	32.23802173	0101000020E61000002E0BFD7E771E40402EA890A73C294240	14	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	70	431604.5111	4019951.492
450	#record-101-of-257	Tomb: Iotape-32	Feature	25 - 250	36.32215915	32.2381003	0101000020E61000007AD514127A1E4040B7ADD2823C294240	14	2	vaulted tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	80	431611.5599	4019950.95
451	#record-102-of-257	Tomb: Iotape-33	Feature	25 - 250	36.32224356	32.23830486	0101000020E6100000C4160EC6801E4040F7C5E7463F294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	60	431629.9953	4019960.168
452	#record-103-of-257	Tomb: Iotape-34	Feature	25 - 250	36.32199754	32.23805354	0101000020E61000009F7FD489781E4040A2D8233737294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	60	431607.2222	4019933.057
453	#record-104-of-257	Tomb: Iotape-35	Feature	25 - 250	36.32197857	32.23814434	0101000020E6100000850384837B1E4040D814029836294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	60	431615.3554	4019930.888
454	#record-105-of-257	Tomb: Iotape-36	Feature	25 - 250	36.32193084	32.23832602	0101000020E6100000CAD78E77811E4040D9AF9E0735294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	65	431631.6219	4019925.466
455	#record-106-of-257	Tomb: Iotape-37	Feature	25 - 250	36.32188782	32.23847745	0101000020E6100000AF4AD86D861E4040BCF0BD9E33294240	14	1	Grabhaus	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	70	431645.1773	4019920.586
456	#record-107-of-257	Tomb: Iotape-38	Feature	25 - 250	36.3218106	32.23863526	0101000020E6100000ADAFA6998B1E4040C940F91631294240	14	2	chamber tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	75	431659.2749	4019911.91
457	#record-108-of-257	Tomb: Karasin necropolis-1	Feature	25 - 250	36.18111337	32.51690041	0101000020E6100000971EEACA29424040598210B92E174240	15	2	vaulted tomb	\N	vaulted brick	mortar rubbl	\N	vaulted ceiling; mortar construction; rear wall is bed rock; stones roughly worked;	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	227	130	\N	1148	456559	4004145
458	#record-109-of-257	Tomb: Karasin necropolis-2	Feature	25 - 250	36.18108606	32.51683385	0101000020E61000009E9B919C2742404012BBF8D32D174240	15	2	vaulted tomb	\N	vaulted brick	mortar rubbl	4 niches	1/3 of back wall covered w/ mortar; smaller rocks than adjacent tomb (Feature 1) 26 cm x 11 cm; (see Feature Form for measurements)	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	269	1	\N	1145	456553	4004142
459	#record-110-of-257	Tomb: Karasin necropolis-3	Feature	25 - 250	36.18114024	32.51685576	0101000020E610000080F95C54284240401165779A2F174240	15	2	poss tomb frag	\N	vaulted brick	mortar rubbl	outer and inner rooms vis	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	4	\N	\N	1146	456555	4004148
460	#record-111-of-257	Tomb: Karasin necropolis-4	Feature	25 - 250	36.18114858	32.5166889	0101000020E610000065DAA3DC224240408E686DE02F174240	15	2	poss tomb frag	\N	vaulted brick	mortar rubbl	(see Feature Form for dimensions)	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	274	104	\N	1125	456540	4004149
461	#record-112-of-257	Tomb: Karasin necropolis-5	Feature	25 - 250	36.18116639	32.51663318	0101000020E610000072103A09214240409A17D47530174240	15	2	poss tomb frag	\N	vaulted brick	mortar rubbl	(see Feature Form for dimensions)	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	300	231	\N	1125	456535	4004151
462	#record-113-of-257	Tomb: Karasin necropolis-6	Feature	25 - 250	36.18108606	32.51683385	0101000020E61000009E9B919C2742404012BBF8D32D174240	15	2	necropolis	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	1147	456553	4004142
463	#record-114-of-257	Tomb: Kenetepe-10	Feature	25 - 250	36.38875509	32.37305243	0101000020E61000008C45992EC02F40400DDA0EBAC2314240	16	4	poss larnax	\N	molded block fragment	limestone	large recess visible	Recess for lid, possibly pedestal frag	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	88	35	35	787	443773	4027251
464	#record-115-of-257	Tomb: Kenetepe-11	Feature	25 - 250	36.38874596	32.37303021	0101000020E61000005D2F3474BF2F40407953786DC2314240	16	3	house tomb	\N	house tomb	limestone	door relief, recess on top	possibly related to neighboring frags	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	52	61	37	783	443771	4027250
465	#record-116-of-257	Tomb: Kenetepe-1	Feature	25 - 250	36.39066554	32.37634877	0101000020E610000019854D322C304040B2FC125401324240	16	4	poss larnax	\N	relief	limestone	possible dining relief	15 blocks nearby, poss all of feature	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	137	153	82	875	444070	4027461
466	#record-117-of-257	Tomb: Kenetepe-2	Feature	25 - 250	36.38893198	32.36898119	0101000020E6100000D0F18FC63A2F4040F93BEB85C8314240	16	3	poss rock tomb	\N	Luwian relief 2	\N	relief of family on rock ledge	Luwian relief like one in necropolis	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	814	443408	4027273
467	#record-118-of-257	Tomb: Kenetepe-3	Feature	25 - 250	36.38887193	32.37298459	0101000020E610000022FB83F5BD2F404059D72E8EC6314240	16	4	larnax	\N	inscribed larnax with reliefs	limestone	inscribed, head in intaglio	reclining figure on side	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	100	56	88	790	443767	4027264
511	#record-162-of-257	Tomb: Lamos-1	Feature	25 - 250	36.23862667	32.45429181	0101000020E61000003465E93B263A40403CCD97518B1E4240	19	1	temple tomb 1	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	850	450964.9916	4010554.221
468	#record-119-of-257	Tomb: Kenetepe-4	Feature	25 - 250	36.39065387	32.37411878	0101000020E6100000B075CA1FE32F404059DA2DF200324240	16	4	narrative relief	\N	large narrative relief	limestone	inscribed narrative relief	Tall Relief with inscription	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	520	260	330	795	443870	4027461
469	#record-120-of-257	Tomb: Kenetepe-5	Feature	25 - 250	36.38853001	32.37310999	0101000020E6100000326E7211C22F4040763BF359BB314240	16	4	inscribed altar	\N	inscribed altar	limestone	anima memnes charin	Lower length 67cm	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	80	74	26	777	443778	4027226
470	#record-121-of-257	Tomb: Kenetepe-6	Feature	25 - 250	36.38878225	32.37307451	0101000020E6100000EBB5D1E7C02F4040F581E49DC3314240	16	4	poss larnax	\N	fragment with relief	limestone	eagle/human head	Possible part of pedestal	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	91	46	26	778	443775	4027254
471	#record-122-of-257	Tomb: Kenetepe-7	Feature	25 - 250	36.38877324	32.37307459	0101000020E610000062827DE8C02F404013AE4F52C3314240	16	3	house tomb	\N	Pedestal	limestone	large rectangular block	human reliefs on 3 sides	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	95	60	56	781	443775	4027253
472	#record-123-of-257	Tomb: Kenetepe-8	Feature	25 - 250	36.38873718	32.37307488	0101000020E61000009147ECEAC02F40406D6BD123C2314240	16	4	larnax	\N	larnax	limestone	14cm recess on bottom	Busts on 3 sides	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	98	65	57	788	443775	4027249
473	#record-124-of-257	Tomb: Kenetepe-9	Feature	25 - 250	36.38873706	32.37305258	0101000020E6100000EB64DB2FC02F4040BAB8CF22C2314240	16	4	poss larnax	\N	molded block fragment	limestone	rectangular recess visible	Very irregular	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	50	38	44	792	443773	4027249
474	#record-125-of-257	Tomb: Kenetepe-12	Feature	25 - 250	36.38907049	32.3730276	0101000020E6100000B0404F5EBF2F4040C131D30FCD314240	16	4	larnax	\N	inscribed larnax with reliefs	limestone	equestrian and family reliefs	2 relief sides, 1 open end	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	108	110	76	788	443771	4027286
475	#record-126-of-257	Tomb: Kenetepe-13	Feature	25 - 250	36.38895254	32.37288359	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	16	3	fragment	\N	Broken block relief	Limestone?	\N	Found between items 16, 17	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	23	15	13	775	443758	4027273
476	#record-127-of-257	Tomb: Kenetepe-14	Feature	25 - 250	36.38895254	32.37288359	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	16	3	house tomb	\N	house tomb fragment	limestone	door relief fragment	Next to item 16	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	53	57	39	775	443758	4027273
477	#record-128-of-257	Tomb: Kenetepe-15	Feature	25 - 250	36.38895254	32.37288359	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	16	4	larnax	\N	reliefs of human figures	limestone	broken top	Relief-2 children, 2 adults	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	75	40	45	775	443758	4027273
478	#record-129-of-257	Tomb: Kenetepe-16	Feature	25 - 250	36.38895254	32.37288359	0101000020E6100000EE2144A6BA2F4040817F6332C9314240	16	3	house tomb	\N	Limestone block	limestone	3 possibly related	triangular roof lid fragment	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	103	41	35	777	443758	4027273
479	#record-130-of-257	Tomb: Kenetepe-17	Feature	25 - 250	36.38896155	32.37288352	0101000020E610000006CFADA5BA2F40406353F87DC9314240	16	3	fragment	\N	Limestone block	limestone	3 possibly related	large rectangular block	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	114	81	27	777	443758	4027274
480	#record-131-of-257	Tomb: Kenetepe-18	Feature	25 - 250	36.38895248	32.37287244	0101000020E61000009BB0BB48BA2F404028A6E231C9314240	16	3	fragment	\N	Limestone block	limestone	3 possibly related	molded fragment	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	60	40	38	777	443757	4027273
481	#record-132-of-257	Tomb: Kenetepe-19	Feature	25 - 250	36.38889839	32.37287288	0101000020E61000002A956C4CBA2F40402F42256CC7314240	16	3	house tomb	\N	pediment roof to house tomb	limestone	triangular roof fragment	between split rock, 5 m south of  13	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	44	49	\N	780	443757	4027267
482	#record-133-of-257	Tomb: Kenetepe-20	Feature	25 - 250	36.38890776	32.3729397	0101000020E6100000A670F37CBC2F4040292EBFBAC7314240	16	4	larnax/house tomb	\N	larnax fragment	limestone	door relief fragment	recess visible	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	59	34	47	778	443763	4027268
483	#record-134-of-257	Tomb: Kenetepe-21	Feature	25 - 250	36.38888106	32.37300682	0101000020E6100000E08AFEAFBE2F4040EE5DC5DAC6314240	16	3	house tomb	\N	decorated block	limestone	door relief fragment	buried in the ground	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	66	35	41	774	443769	4027265
484	#record-135-of-257	Tomb: Kenetepe-22	Feature	25 - 250	36.38909145	32.37358494	0101000020E610000000CA9DA1D12F40409D73A6BFCD314240	16	4	poss larnax	\N	equestrian relief	limestone	\N	equestrian relief	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	795	443821	4027288
485	#record-136-of-257	Tomb: Kenetepe-23	Feature	25 - 250	36.38820506	32.37131744	0101000020E6100000029E7254872F4040BD6B12B4B0314240	16	3	tomb frag	\N	stepped feature	limestone	\N	rock cut steps to possible tomb	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	848	443617	4027191
486	#record-137-of-257	Tomb: Kenetepe-24	Feature	25 - 250	36.38854163	32.36847144	0101000020E6100000AF2778122A2F404005FE6CBBBB314240	16	1	poss temple tomb	\N	possible temple tomb	limestone	steps on front	block and mortar construction	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	500	590	\N	798	443362	4027230
487	#record-138-of-257	Tomb: Kenetepe-25	Feature	25 - 250	36.3890733	32.37356279	0101000020E6100000B906CFE7D02F4040979F6527CD314240	16	4	poss larnax	\N	Limestone block	limestone	smooth face with semicircular depression	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	34	89	51	794	443819	4027286
488	#record-139-of-257	Tomb: Kenetepe-26	Feature	25 - 250	36.38938864	32.37352681	0101000020E61000008A90FCB9CF2F4040F11DA97CD7314240	16	4	poss larnax	\N	Limestone relief	limestone	possible lion or horse relief	legs and torso visible	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	50	30	24	800	443816	4027321
489	#record-140-of-257	Tomb: Kenetepe-27	Feature	25 - 250	36.3890822	32.37354041	0101000020E61000009B57122CD02F4040553A0E72CD314240	16	4	poss larnax	\N	relief	limestone	head in intaglio fragment	intaglio and molded edge	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	80	56	42	786	443817	4027287
490	#record-141-of-257	Tomb: Kenetepe-28	Feature	25 - 250	36.3891093	32.37355135	0101000020E610000036D0D787D02F4040E4086355CE314240	16	4	poss larnax	\N	relief	limestone	small fragment	possible woman with veil	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	66	50	20	785	443818	4027290
491	#record-142-of-257	Tomb: Kenetepe-29	Feature	25 - 250	36.38884535	32.37307401	0101000020E610000003F89FE3C02F4040D0B936AFC5314240	16	3	poss house tomb	\N	relief	limestone	very damaged, buried	door relief visible on side	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	115	87	52	783	443775	4027261
492	#record-143-of-257	Tomb: Kenetepe-30	Feature	25 - 250	36.3886472	32.37310905	0101000020E6100000BACB8F09C22F40404BD70231BF314240	16	4	poss larnax	\N	Buried relief	limestone	poss human figure on side	Just above ground level	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	60	31	16	783	443778	4027239
493	#record-144-of-257	Tomb: Kestros-1	Feature	25 - 250	36.2357932	32.33093821	0101000020E61000003079EA2E5C2A4040424FB9782E1E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	439878.655	4010309.403
494	#record-145-of-257	Tomb: Kestros-3	Feature	25 - 250	36.23591231	32.33084937	0101000020E6100000AF06AC45592A40404016E45F321E4240	17	3	panoply relief	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	439870.7636	4010322.67
495	#record-146-of-257	Tomb: Kestros-4	Feature	25 - 250	36.23577753	32.33101002	0101000020E61000002F464D895E2A4040A73D46F52D1E4240	17	3	tomb relief frag	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	240	439885.0961	4010307.621
496	#record-147-of-257	Tomb: Kestros-6	Feature	25 - 250	36.23562152	32.33113327	0101000020E61000003FA23293622A4040215191D8281E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	285	439896.0524	4010290.24
497	#record-148-of-257	Tomb: Kestros-7	Feature	25 - 250	36.2355645	32.33109728	0101000020E610000081B24A65612A40409FCC3FFA261E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	290	439892.7747	4010283.937
498	#record-149-of-257	Tomb: Kestros-8	Feature	25 - 250	36.23546442	32.33108691	0101000020E6100000B74A4D0E612A4040C4A2B7B2231E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	290	439891.7661	4010272.843
499	#record-150-of-257	Tomb: Kestros-9	Feature	25 - 250	36.23557182	32.33118701	0101000020E6100000AF670056642A40402D61A737271E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	285	439900.843	4010284.693
500	#record-151-of-257	Tomb: Kestros-10	Feature	25 - 250	36.23561524	32.33122873	0101000020E61000003D6CF9B3652A40409E1EE3A3281E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	280	439904.625	4010289.484
501	#record-152-of-257	Tomb: Kestros-11	Feature	25 - 250	36.23546555	32.33088208	0101000020E61000005B3710585A2A4040D64A32BC231E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	285	439873.3602	4010273.095
502	#record-153-of-257	Tomb: Kestros-12	Feature	25 - 250	36.23569552	32.33095026	0101000020E6100000BFA6FF935C2A40405B1B53452B1E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	290	439879.6636	4010298.561
503	#record-154-of-257	Tomb: Kestros-13	Feature	25 - 250	36.23586131	32.3309236	0101000020E6100000BFBC5BB45B2A4040BD6B12B4301E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	439877.3944	4010316.967
504	#record-155-of-257	Tomb: Kestros-14	Feature	25 - 250	36.23588259	32.33107213	0101000020E6100000C97B5192602A404076DF9466311E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	290	439890.7576	4010319.236
505	#record-156-of-257	Tomb: Kestros-15	Feature	25 - 250	36.23595349	32.33115009	0101000020E6100000094F4B20632A4040AA7655B9331E4240	17	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	439897.8174	4010327.052
506	#record-157-of-257	Tomb: Kir Ahmetler Mah.-1	Feature	25 - 250	36.17385488	32.39822511	0101000020E6100000B0F2570AF9324040CDEC6FE040164240	18	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	339	445882.4492	4003399.542
507	#record-158-of-257	Tomb: Kir Ahmetler Mah.-2	Feature	25 - 250	36.17470176	32.39908098	0101000020E61000001FC7E6151533404077E094A05C164240	18	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	323	445960	4003493
508	#record-159-of-257	Tomb: Kir Ahmetler Mah.-3	Feature	25 - 250	36.17292513	32.40001025	0101000020E61000004BE82E8933334040D700216922164240	18	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	326	446042.3508	4003295.42
509	#record-160-of-257	Tomb: Kir Ahmetler Mah.-4	Feature	25 - 250	36.17206632	32.40258044	0101000020E610000097E77FC1873340405092E84406164240	18	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	307	446272.9067	4003198.735
510	#record-161-of-257	Tomb: Kir Ahmetler Mah.-5	Feature	25 - 250	36.16944976	32.41537695	0101000020E610000091E167122B354040EDC19C87B0154240	18	2	3 ruined tombs	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	400	447421.9861	4002901.5
512	#record-163-of-257	Tomb: Lamos-2	Feature	25 - 250	36.23869323	32.4543168	0101000020E6100000FE028B0D273A40403550F07F8D1E4240	19	1	temple tomb 2	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	854	450967.2789	4010561.591
513	#record-164-of-257	Tomb: Lamos-3	Feature	25 - 250	36.24028746	32.45317858	0101000020E6100000822C76C1013A4040612B4FBDC11E4240	19	3	house tomb	oikos, oikias	house tomb with door and window	inscribed	gabled roof with lion acroteria	inscribed beside door	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	851	450866	4010739
514	#record-165-of-257	Tomb: Lamos-4	Feature	25 - 250	36.23885042	32.45451572	0101000020E61000007E7534922D3A404097448BA6921E4240	19	3	rock cut tombs	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	860	450985.2511	4010578.926
515	#record-166-of-257	Tomb: Lamos-5	Feature	25 - 250	36.23861567	32.45429198	0101000020E6100000B177563D263A4040487B51F58A1E4240	19	3	corporate tomb	\N	ruined limestone tomb	\N	\N	20m east of temple tomb	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	860	450965	4010553
516	#record-167-of-257	Tomb: Meraklar Mah-1	Feature	25 - 250	36.2996285	32.33115461	0101000020E610000050EF3546632A40408A39083A5A264240	20	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	97	439947	4017390
517	#record-168-of-257	Tomb: Meydancik Tepe-1	Feature	25 - 250	36.16382572	32.41664187	0101000020E6100000ABE552855435404063D2BE3DF8144240	21	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	231	447532	4002277
518	#record-169-of-257	Tomb: Nephelion-1	Feature	25 - 250	36.1771784	32.38208816	0101000020E6100000C5B1CB43E830404060C724C8AD164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	180	444433.5846	4003777.305
519	#record-170-of-257	Tomb: Nephelion-2	Feature	25 - 250	36.17703377	32.38191844	0101000020E610000009C514B4E23040400338E60AA9164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	185	444418.22	4003761.36
520	#record-171-of-257	Tomb: Nephelion-3	Feature	25 - 250	36.17693103	32.38176129	0101000020E6100000E2B6CF8DDD304040B1BF0DADA5164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	190	444404.0151	4003750.054
521	#record-172-of-257	Tomb: Nephelion-4	Feature	25 - 250	36.17682099	32.38170735	0101000020E6100000487254C9DB304040EFA5F811A2164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	200	444399.0868	4003737.879
522	#record-173-of-257	Tomb: Nephelion-5	Feature	25 - 250	36.17677115	32.38167228	0101000020E6100000E33124A3DA3040402B10E26FA0164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	210	444395.898	4003732.371
523	#record-174-of-257	Tomb: Nephelion-6	Feature	25 - 250	36.17676386	32.38177872	0101000020E6100000B85A0620DE30404049E8BA32A0164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	200	444405.4646	4003731.501
524	#record-175-of-257	Tomb: Nephelion-7	Feature	25 - 250	36.17675931	32.38191092	0101000020E610000051B1FF74E230404055DB8F0CA0164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	195	444417.3503	4003730.921
525	#record-176-of-257	Tomb: Nephelion-8	Feature	25 - 250	36.17654516	32.38194162	0101000020E6100000CD708776E3304040CA3B240899164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	185	444419.9594	4003707.15
526	#record-177-of-257	Tomb: Nephelion-9	Feature	25 - 250	36.17672343	32.3820466	0101000020E610000025462AE7E6304040BB2494DF9E164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	185	444429.526	4003726.863
527	#record-178-of-257	Tomb: Nephelion-10	Feature	25 - 250	36.17685429	32.38208426	0101000020E610000018821423E830404089DA4F29A3164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	190	444433.0048	4003741.357
528	#record-179-of-257	Tomb: Nephelion-11	Feature	25 - 250	36.17698021	32.38217353	0101000020E61000009A5FEE0FEB3040409FFE9A49A7164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	195	444441.1219	4003755.273
529	#record-180-of-257	Tomb: Nephelion-12	Feature	25 - 250	36.17698129	32.38238306	0101000020E6100000499F98EDF1304040E646AA52A7164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	200	444459.9652	4003755.273
530	#record-181-of-257	Tomb: Nephelion-13	Feature	25 - 250	36.17688426	32.38231935	0101000020E6100000627028D7EF30404047F0B724A4164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	205	444454.1672	4003744.546
531	#record-182-of-257	Tomb: Nephelion-14	Feature	25 - 250	36.17665362	32.38219544	0101000020E61000007BBDB9C7EB3040405D4FF8959C164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	205	444442.8613	4003719.035
532	#record-183-of-257	Tomb: Nephelion-15	Feature	25 - 250	36.17666539	32.38245001	0101000020E610000006A7361FF43040404A31B4F89C164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	190	444465.7631	4003720.195
533	#record-184-of-257	Tomb: Nephelion-16	Feature	25 - 250	36.17673073	32.3824495	0101000020E61000008F6FEF1AF43040402CC6D01C9F164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	190	444465.7631	4003727.442
534	#record-185-of-257	Tomb: Nephelion-17	Feature	25 - 250	36.17685655	32.38252266	0101000020E6100000E756A580F6304040AC2A453CA3164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	180	444472.4307	4003741.357
535	#record-186-of-257	Tomb: Nephelion-18	Feature	25 - 250	36.17668205	32.38264008	0101000020E610000092DEA259FA304040264575849D164240	22	2	ruined tomb	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	195	444482.867	4003721.934
536	#record-187-of-257	Tomb: Nergis Tepe-1	Feature	25 - 250	36.33895096	32.28214012	0101000020E61000000F25DE2A1D244040EB12BCBE622B4240	23	3	necropolis	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	460	435578.484	4021783.309
537	#record-188-of-257	Tomb: Selinus-1	Feature	25 - 250	36.2602597	32.28454953	0101000020E610000099B8761E6C244040BFFB993050214240	24	2	2 chamber tomb	\N	2 chamber tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	26	435730.1811	4013053.051
538	#record-189-of-257	Tomb: Selinus-10	Feature	25 - 250	36.25908034	32.28607831	0101000020E6100000C1C5CC369E24404014AB698B29214240	24	1	Grabhaus	\N	Grabhaus	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	26	435866.5518	4012921.221
539	#record-190-of-257	Tomb: Selinus-11	Feature	25 - 250	36.25900177	32.28617858	0101000020E610000036F5EC7FA1244040C8E051F826214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	26	435875.495	4012912.439
540	#record-191-of-257	Tomb: Selinus-2	Feature	25 - 250	36.25983722	32.28532498	0101000020E61000007AEA6887852440407F17955842214240	24	2	chamber tomb	tantum	Celer inscription	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	5	435799.496	4013005.675
541	#record-192-of-257	Tomb: Selinus-3	Feature	25 - 250	36.25965859	32.2856049	0101000020E6100000E7898CB38E2440407616207E3C214240	24	2	chamber tomb	heroion	grey limestone tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	11	435824.496	4012985.675
542	#record-193-of-257	Tomb: Selinus-4	Feature	25 - 250	36.25985479	32.2852469	0101000020E610000087646DF8822440402561F8EB42214240	24	2	chamber tomb	heroion	grey limestone tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	22	435792.496	4013007.675
543	#record-194-of-257	Tomb: Selinus-5	Feature	25 - 250	36.26047355	32.2846958	0101000020E61000007F2777E9702440408C5C813257214240	24	2	chamber tomb	heroion	grey limestone tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	19	435743.496	4013076.675
544	#record-195-of-257	Tomb: Selinus-6	Feature	25 - 250	36.26052817	32.28478436	0101000020E6100000604E5CD0732440401AEBB0FC58214240	24	2	chamber tomb	heroion	grey limestone tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	17	435751.496	4013082.675
545	#record-196-of-257	Tomb: Selinus-7	Feature	25 - 250	36.26042921	32.28481865	0101000020E61000003B8501F074244040C2EF8DBE55214240	24	2	chamber tomb	heroion	gry limestone tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	30	435754.496	4013071.675
546	#record-197-of-257	Tomb: Selinus-8	Feature	25 - 250	36.26035775	32.28493062	0101000020E6100000B643479B782440404CC11A6753214240	24	2	chamber tomb	\N	grey limestone tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	13	435764.496	4013063.675
547	#record-198-of-257	Tomb: Selinus-9	Feature	25 - 250	36.26031401	32.28515366	0101000020E6100000710446EA7F24404000D22FF851214240	24	2	chamber tomb	heroion	white limestone tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	18	435784.496	4013058.675
548	#record-199-of-257	Tomb: Selinus-12	Feature	25 - 250	36.25913168	32.28589452	0101000020E6100000B8C00E3198244040917A153A2B214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	28	435850.0826	4012927.037
549	#record-200-of-257	Tomb: Selinus-13	Feature	25 - 250	36.25916187	32.28584328	0101000020E6100000D1B0398396244040960256372C214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	28	435845.5044	4012930.42
550	#record-201-of-257	Tomb: Selinus-14	Feature	25 - 250	36.25922895	32.2856776	0101000020E6100000929966159124404095360B6A2E214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	30	435830.6757	4012937.97
551	#record-202-of-257	Tomb: Selinus-15	Feature	25 - 250	36.25928348	32.28564048	0101000020E6100000C20104DE8F2440401D7F793330214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	29	435827.3853	4012944.044
552	#record-203-of-257	Tomb: Selinus-16	Feature	25 - 250	36.25934252	32.28559204	0101000020E610000022E6AB478E2440405DEEBC2232214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	29	435823.0825	4012950.625
553	#record-204-of-257	Tomb: Selinus-17	Feature	25 - 250	36.25979803	32.28544702	0101000020E610000001D22787892440402635D50F41214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	22	435810.427	4013001.247
554	#record-205-of-257	Tomb: Selinus-18	Feature	25 - 250	36.25972791	32.28554909	0101000020E6100000EE7961DF8C2440407BA79FC33E214240	24	2	vaulted tomb	\N	vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	22	435819.5389	4012993.401
555	#record-206-of-257	Tomb: Selinus-19	Feature	25 - 250	36.25978397	32.28538516	0101000020E61000005B7B3C80872440406896E39940214240	24	2	2chamber tomb	\N	2chamber tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	23	435804.8586	4012999.728
556	#record-207-of-257	Tomb: Selinus-20	Feature	25 - 250	36.2598014	32.28524694	0101000020E6100000C34AC3F8822440403E3A1A2C41214240	24	2	2story vaulted tomb	\N	2story vaulted tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	25	435792.4563	4013001.753
557	#record-208-of-257	Tomb: Selinus-21	Feature	25 - 250	36.25988107	32.28508227	0101000020E6100000E32869937D244040EF3F6CC843214240	24	2	2 destroyed tombs	\N	2 destroyed tombs	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	25	435777.7291	4013010.7
558	#record-209-of-257	Tomb: Selinus-22	Feature	25 - 250	36.25989188	32.2849479	0101000020E61000002DC83B2C79244040488C1A2344214240	24	2	ruined tomb	\N	destroyed tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	27	435765.6664	4013011.988
559	#record-210-of-257	Tomb: Selinus-23	Feature	25 - 250	36.25993835	32.28488327	0101000020E6100000EDE9130E77244040F41CECA845214240	24	2	ruined tomb	\N	destroyed tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	27	435759.8986	4013017.185
560	#record-211-of-257	Tomb: Selinus-24	Feature	25 - 250	36.25995347	32.28476254	0101000020E61000008436521973244040DC10C22746214240	24	2	2 ruined tombS	\N	2 destroyed tombs	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	29	435749.0656	4013018.942
561	#record-212-of-257	Tomb: Selinus-25	Feature	25 - 250	36.26003342	32.28467055	0101000020E61000003231A715702440402E626DC648214240	24	2	ruined tomb	\N	destroyed tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	29	435740.8677	4013027.872
562	#record-213-of-257	Tomb: Selinus-26	Feature	25 - 250	36.26006158	32.28474526	0101000020E61000000DB25D8872244040E685A6B249214240	24	2	ruined tomb	\N	destroyed tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	27	435747.6017	4013030.946
563	#record-214-of-257	Tomb: Selinus-27	Feature	25 - 250	36.26020526	32.28471625	0101000020E6100000E4310395712440403DF9EC674E214240	24	2	2 chamber vaulted tomb	\N	mult chamb vault tom	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	24.6	435745.1131	4013046.902
564	#record-215-of-257	Tomb: Selinus-28	Feature	25 - 250	36.26015611	32.28466292	0101000020E610000056E4A5D56F244040FC26A0CB4C214240	24	2	2 chamber tomb	\N	2 chamber tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	26.7	435740.2821	4013041.486
565	#record-216-of-257	Tomb: Selinus-29	Feature	25 - 250	36.26021505	32.28458742	0101000020E610000063E04E5C6D244040A8D60CBA4E214240	24	2	4 chamber tomb	\N	4 chamber tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	26.7	435733.5481	4013048.074
566	#record-217-of-257	Tomb: Selinus-30	Feature	25 - 250	36.26020986	32.28438214	0101000020E6100000E96E4BA266244040FC65838E4E214240	24	2	mult chamb tomb	\N	mult chamb tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	29.5	435715.1028	4013047.634
567	#record-218-of-257	Tomb: Selinus-31	Feature	25 - 250	36.26041204	32.28510388	0101000020E61000000748B0487E2440406FA4852E55214240	24	2	large tomb	\N	large tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	12	435780.1043	4013069.582
568	#record-219-of-257	Tomb: Selinus-32	Feature	25 - 250	36.26030749	32.28505594	0101000020E61000004FEA89B67C244040183A7EC151214240	24	2	tomb	heroion	tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	16.8	435775.7125	4013058.017
569	#record-220-of-257	Tomb: Selinus-33	Feature	25 - 250	36.26029996	32.2847432	0101000020E610000013E1157772244040D0AC538251214240	24	2	ruined tomb	\N	ruined tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	22	435747.6122	4013057.389
570	#record-221-of-257	Tomb: Selinus-34	Feature	25 - 250	36.2603974	32.28465638	0101000020E61000005059C99E6F244040527BB6B354214240	24	2	ruined tomb	\N	ruined tomb	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	22	435739.8924	4013068.254
571	#record-222-of-257	Tomb: Sivaste-1	Feature	25 - 250	36.42745051	32.41067083	0101000020E6100000B6229CDC90344040E48DC4B2B6364240	25	4	poss larnax	\N	lion relief	limestone	used as tomb base	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	87	51	55	816	447173	4031522
572	#record-223-of-257	Tomb: Sivaste-2	Feature	25 - 250	36.42723283	32.41040474	0101000020E610000031367C24883440405350BC90AF364240	25	4	larnax	\N	2 human heads in relief	limestone	\N	2 human portraits	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	91	72	67	814	447149	4031498
579	#record-230-of-257	Tomb: Sivaste-3	Feature	25 - 250	36.42703445	32.41039508	0101000020E6100000088573D387344040F7819A10A9364240	25	4	poss larnax	\N	decorated block pedestal	limestone	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	144	51	46	823	447148	4031476
580	#record-231-of-257	Tomb: Sivaste-4	Feature	25 - 250	36.42750482	32.41071504	0101000020E61000003E63784F9234404025645A7AB8364240	25	4	larnax	\N	winged goddess relief	limestone	\N	possible wings or wreaths	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	86	58	64	816	447177	4031528
581	#record-232-of-257	Tomb: Sivaste-5	Feature	25 - 250	36.42745089	32.41074892	0101000020E61000003822AD6B933440401A99F4B5B6364240	25	4	larnax	\N	sheppard flock relief	limestone	sheperd, ram, sheep, dogs	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	87	89	71	815	447180	4031522
582	#record-233-of-257	Tomb: Sivaste-6	Feature	25 - 250	36.4273347	32.410586922	0101000020E6100000E113BD1C8E344040167948E7B2364240	25	4	larnax	\N	panoply	limestone	shield relief visible	broken at top	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	120	100	65	810	447212	4031477
583	#record-234-of-257	Tomb: Sunbuller-1	Feature	25 - 250	36.1969990378	32.4579956821	0101000020E6100000132A3E9A9F3A4040E458B44337194240	26	2	necropolis	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	477	451077	4006175
584	#record-235-of-257	Tomb: kestros-2	Feature	25 - 250	36.23610138	32.3307079	0101000020E6100000B183EFA2542A4040FBD1EC91381E4240	17	1	Grabhaus	\N	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	439858.1957	4010343.73
585	#record-236-of-257	Tomb: kestros-5	Feature	25 - 250	36.23319164	32.33110908	0101000020E61000001B0147C8612A404014C04139D91D4240	17	2	inscribed tomb	fragmentary	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	300	439892.0182	4010020.729
586	#record-237-of-257	Tomb: selinus-35	Feature	25 - 250	36.25922895	32.2856776	0101000020E6100000929966159124404095360B6A2E214240	24	2	inscribed tomb	heroion	\N	\N	\N	\N	This is a preliminary draft release of Roman-Era tombs documented in survey of Cilicia. Additional documentation is forthcoming.	\N	\N	\N	195	435830.6757	4012937.97
\.


--
-- TOC entry 4774 (class 0 OID 22865)
-- Dependencies: 247
-- Data for Name: sites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sites (id, subject_id, label, location_code, site_category, cultural_type, topography, geom) FROM stdin;
1	#record-224-of-257	Antioch	\N	\N	Mesogeia Semi-Acculturated	\N	0101000020E6100000C25A990600364040CF0AD555CF134240
2	#record-225-of-257	Asar Tepe	\N	\N	Coastal Hellenistic Acculturated	\N	0101000020E6100000FB1309643E3440400543EB1BF71C4240
3	#record-226-of-257	Corus	\N	\N	Unknown	\N	0101000020E6100000DF84EC036337404053482FF3682B4240
4	#record-227-of-257	Dede Tepe	\N	\N	Unknown	\N	0101000020E6100000E49C7D8A082E4040006C27E7171C4240
5	#record-228-of-257	Direvli	\N	\N	Mesogeia Semi-Acculturated	\N	0101000020E610000039B2A8ADED4440404AD114DC33214240
6	#record-229-of-257	Frengez Kale	\N	\N	Coastal Hellenistic Acculturated	\N	0101000020E61000001C6FA4CC0344404032FF09AA9D164240
7	#record-238-of-257	Gocuk Asari	\N	\N	Unknown	\N	0101000020E6100000C0F0E767AC3A40408D95309443184240
8	#record-239-of-257	Gokcebelen Kale	\N	\N	Mesogeia Semi-Acculturated	\N	0101000020E6100000B5C63DE9864240409FEFAC6FF2134240
9	#record-240-of-257	Goktas Tepe	\N	\N	Unknown	\N	0101000020E61000007B6DF439903B4040CB19E5F4501C4240
10	#record-241-of-257	Gozkaya Tepe	\N	\N	Unknown	\N	0101000020E6100000BA7E66B5E5334040406C86A7991D4240
11	#record-242-of-257	Gurcam Kale	\N	\N	Unknown	\N	0101000020E6100000063023C4AE3E40405DA2BC87F21A4240
12	#record-243-of-257	Hisar	\N	\N	Unknown	\N	0101000020E6100000B260A562DD4B404062F1DDDE1C184240
13	#record-244-of-257	IlIca Kale	\N	\N	Unknown	\N	0101000020E61000004A30C8A21830404095F4356D34364240
14	#record-245-of-257	Iotape	\N	\N	Coastal Hellenistic Acculturated	\N	0101000020E6100000C5FADC528D1E4040B28921611D294240
15	#record-246-of-257	Karasin necropolis	\N	\N	Unknown	\N	0101000020E6100000E1090C3526424040F4249F0D2F174240
16	#record-247-of-257	Kenetepe	\N	\N	Unknown	\N	0101000020E610000003B0DEF1BA2F40401067AE5ECA314240
17	#record-248-of-257	Kestros	\N	\N	Mesogeia Semi-Acculturated	\N	0101000020E610000014E086EB5E2A404030E8C6FC261E4240
18	#record-249-of-257	Kir Ahmetler Mah.	\N	\N	Unknown	\N	0101000020E6100000A748444C97334040123A22BE17164240
19	#record-250-of-257	Lamos	\N	\N	Mesogeia Semi-Acculturated	\N	0101000020E610000060801792203A404023688A08981E4240
20	#record-251-of-257	Meraklar Mah	\N	\N	Unknown	\N	0101000020E610000050EF3546632A40408A39083A5A264240
21	#record-252-of-257	Meydancik Tepe	\N	\N	Unknown	\N	0101000020E6100000ABE552855435404063D2BE3DF8144240
22	#record-253-of-257	Nephelion	\N	\N	Coastal Hellenistic Acculturated	\N	0101000020E61000006E247D18E9304040CEDA8623A2164240
23	#record-254-of-257	Nergis Tepe	\N	\N	Highland Low-Acculturated / Native	\N	0101000020E61000000F25DE2A1D244040EB12BCBE622B4240
24	#record-255-of-257	Selinus	\N	\N	Coastal Hellenistic Acculturated	\N	0101000020E6100000828355DC7F244040B49A882A44214240
25	#record-256-of-257	Sivaste	\N	\N	Highland Low-Acculturated / Native	\N	0101000020E6100000E113BD1C8E344040167948E7B2364240
26	#record-257-of-257	Sunbuller	\N	\N	Unknown	\N	0101000020E6100000132A3E9A9F3A4040E458B44337194240
\.


--
-- TOC entry 4525 (class 0 OID 21702)
-- Dependencies: 223
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- TOC entry 4527 (class 0 OID 22473)
-- Dependencies: 228
-- Data for Name: topology; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.topology (id, name, srid, "precision", hasz, useslargeids) FROM stdin;
\.


--
-- TOC entry 4528 (class 0 OID 22486)
-- Dependencies: 229
-- Data for Name: layer; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.layer (topology_id, layer_id, schema_name, table_name, feature_column, feature_type, level, child_id) FROM stdin;
\.


--
-- TOC entry 4788 (class 0 OID 0)
-- Dependencies: 238
-- Name: observations_id_seq; Type: SEQUENCE SET; Schema: cilicia; Owner: postgres
--

SELECT pg_catalog.setval('cilicia.observations_id_seq', 1, false);


--
-- TOC entry 4789 (class 0 OID 0)
-- Dependencies: 244
-- Name: finds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.finds_id_seq', 606, true);


--
-- TOC entry 4790 (class 0 OID 0)
-- Dependencies: 246
-- Name: sites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sites_id_seq', 26, true);


--
-- TOC entry 4791 (class 0 OID 0)
-- Dependencies: 227
-- Name: topology_id_seq; Type: SEQUENCE SET; Schema: topology; Owner: postgres
--

SELECT pg_catalog.setval('topology.topology_id_seq', 1, false);


--
-- TOC entry 4590 (class 2606 OID 22785)
-- Name: media media_oc_uri_key; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.media
    ADD CONSTRAINT media_oc_uri_key UNIQUE (oc_uri);


--
-- TOC entry 4592 (class 2606 OID 22783)
-- Name: media media_pkey; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (uuid);


--
-- TOC entry 4588 (class 2606 OID 22756)
-- Name: observations observations_pkey; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.observations
    ADD CONSTRAINT observations_pkey PRIMARY KEY (id);


--
-- TOC entry 4577 (class 2606 OID 22721)
-- Name: predicates predicates_oc_uri_key; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.predicates
    ADD CONSTRAINT predicates_oc_uri_key UNIQUE (oc_uri);


--
-- TOC entry 4579 (class 2606 OID 22719)
-- Name: predicates predicates_pkey; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.predicates
    ADD CONSTRAINT predicates_pkey PRIMARY KEY (uuid);


--
-- TOC entry 4558 (class 2606 OID 22665)
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (uuid);


--
-- TOC entry 4560 (class 2606 OID 22667)
-- Name: projects projects_slug_key; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.projects
    ADD CONSTRAINT projects_slug_key UNIQUE (slug);


--
-- TOC entry 4565 (class 2606 OID 22678)
-- Name: sites sites_oc_uri_key; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.sites
    ADD CONSTRAINT sites_oc_uri_key UNIQUE (oc_uri);


--
-- TOC entry 4567 (class 2606 OID 22676)
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (uuid);


--
-- TOC entry 4573 (class 2606 OID 22697)
-- Name: subjects subjects_oc_uri_key; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.subjects
    ADD CONSTRAINT subjects_oc_uri_key UNIQUE (oc_uri);


--
-- TOC entry 4575 (class 2606 OID 22695)
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (uuid);


--
-- TOC entry 4581 (class 2606 OID 22736)
-- Name: types types_oc_uri_key; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.types
    ADD CONSTRAINT types_oc_uri_key UNIQUE (oc_uri);


--
-- TOC entry 4583 (class 2606 OID 22734)
-- Name: types types_pkey; Type: CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.types
    ADD CONSTRAINT types_pkey PRIMARY KEY (uuid);


--
-- TOC entry 4595 (class 2606 OID 22823)
-- Name: finds finds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finds
    ADD CONSTRAINT finds_pkey PRIMARY KEY (id);


--
-- TOC entry 4597 (class 2606 OID 22872)
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- TOC entry 4584 (class 1259 OID 22773)
-- Name: idx_obs_predicate; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_obs_predicate ON cilicia.observations USING btree (predicate_uuid);


--
-- TOC entry 4585 (class 1259 OID 22772)
-- Name: idx_obs_subject; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_obs_subject ON cilicia.observations USING btree (subject_uuid);


--
-- TOC entry 4586 (class 1259 OID 22774)
-- Name: idx_obs_value_str; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_obs_value_str ON cilicia.observations USING btree (value_str);


--
-- TOC entry 4561 (class 1259 OID 22685)
-- Name: idx_sites_bbox; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_sites_bbox ON cilicia.sites USING gist (bbox);


--
-- TOC entry 4562 (class 1259 OID 22684)
-- Name: idx_sites_location; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_sites_location ON cilicia.sites USING gist (location);


--
-- TOC entry 4563 (class 1259 OID 22686)
-- Name: idx_sites_project; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_sites_project ON cilicia.sites USING btree (project_uuid);


--
-- TOC entry 4568 (class 1259 OID 22711)
-- Name: idx_subjects_class; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_subjects_class ON cilicia.subjects USING btree (class_uri);


--
-- TOC entry 4569 (class 1259 OID 22708)
-- Name: idx_subjects_location; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_subjects_location ON cilicia.subjects USING gist (location);


--
-- TOC entry 4570 (class 1259 OID 22709)
-- Name: idx_subjects_project; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_subjects_project ON cilicia.subjects USING btree (project_uuid);


--
-- TOC entry 4571 (class 1259 OID 22710)
-- Name: idx_subjects_site; Type: INDEX; Schema: cilicia; Owner: postgres
--

CREATE INDEX idx_subjects_site ON cilicia.subjects USING btree (site_uuid);


--
-- TOC entry 4593 (class 1259 OID 22824)
-- Name: finds_geom_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX finds_geom_idx ON public.finds USING gist (geom);


--
-- TOC entry 4607 (class 2606 OID 22786)
-- Name: media media_project_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.media
    ADD CONSTRAINT media_project_uuid_fkey FOREIGN KEY (project_uuid) REFERENCES cilicia.projects(uuid) ON DELETE CASCADE;


--
-- TOC entry 4608 (class 2606 OID 22791)
-- Name: media media_subject_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.media
    ADD CONSTRAINT media_subject_uuid_fkey FOREIGN KEY (subject_uuid) REFERENCES cilicia.subjects(uuid);


--
-- TOC entry 4604 (class 2606 OID 22762)
-- Name: observations observations_predicate_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.observations
    ADD CONSTRAINT observations_predicate_uuid_fkey FOREIGN KEY (predicate_uuid) REFERENCES cilicia.predicates(uuid);


--
-- TOC entry 4605 (class 2606 OID 22757)
-- Name: observations observations_subject_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.observations
    ADD CONSTRAINT observations_subject_uuid_fkey FOREIGN KEY (subject_uuid) REFERENCES cilicia.subjects(uuid) ON DELETE CASCADE;


--
-- TOC entry 4606 (class 2606 OID 22767)
-- Name: observations observations_type_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.observations
    ADD CONSTRAINT observations_type_uuid_fkey FOREIGN KEY (type_uuid) REFERENCES cilicia.types(uuid);


--
-- TOC entry 4601 (class 2606 OID 22722)
-- Name: predicates predicates_project_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.predicates
    ADD CONSTRAINT predicates_project_uuid_fkey FOREIGN KEY (project_uuid) REFERENCES cilicia.projects(uuid) ON DELETE CASCADE;


--
-- TOC entry 4598 (class 2606 OID 22679)
-- Name: sites sites_project_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.sites
    ADD CONSTRAINT sites_project_uuid_fkey FOREIGN KEY (project_uuid) REFERENCES cilicia.projects(uuid) ON DELETE CASCADE;


--
-- TOC entry 4599 (class 2606 OID 22698)
-- Name: subjects subjects_project_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.subjects
    ADD CONSTRAINT subjects_project_uuid_fkey FOREIGN KEY (project_uuid) REFERENCES cilicia.projects(uuid) ON DELETE CASCADE;


--
-- TOC entry 4600 (class 2606 OID 22703)
-- Name: subjects subjects_site_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.subjects
    ADD CONSTRAINT subjects_site_uuid_fkey FOREIGN KEY (site_uuid) REFERENCES cilicia.sites(uuid);


--
-- TOC entry 4602 (class 2606 OID 22742)
-- Name: types types_predicate_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.types
    ADD CONSTRAINT types_predicate_uuid_fkey FOREIGN KEY (predicate_uuid) REFERENCES cilicia.predicates(uuid);


--
-- TOC entry 4603 (class 2606 OID 22737)
-- Name: types types_project_uuid_fkey; Type: FK CONSTRAINT; Schema: cilicia; Owner: postgres
--

ALTER TABLE ONLY cilicia.types
    ADD CONSTRAINT types_project_uuid_fkey FOREIGN KEY (project_uuid) REFERENCES cilicia.projects(uuid) ON DELETE CASCADE;


--
-- TOC entry 4609 (class 2606 OID 22874)
-- Name: finds fk_site; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finds
    ADD CONSTRAINT fk_site FOREIGN KEY (site_id) REFERENCES public.sites(id);


-- Completed on 2026-07-20 15:47:36 +03

--
-- PostgreSQL database dump complete
--


