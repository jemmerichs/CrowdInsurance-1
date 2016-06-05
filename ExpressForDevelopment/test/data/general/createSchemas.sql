--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: smartbackend; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA smartbackend;


--
-- Name: smartinsurance; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA smartinsurance;


SET search_path = smartbackend, pg_catalog;

--
-- Name: messagetype; Type: TYPE; Schema: smartbackend; Owner: -
--

CREATE TYPE messagetype AS ENUM (
    'textmessage',
    'imagemessage',
    'filemessage'
);


SET search_path = smartinsurance, pg_catalog;

--
-- Name: auszahlungsstatus; Type: TYPE; Schema: smartinsurance; Owner: -
--

CREATE TYPE auszahlungsstatus AS ENUM (
    'ausgezahlt',
    'angezweifelt',
    'ausstehend'
);


--
-- Name: bewertung; Type: TYPE; Schema: smartinsurance; Owner: -
--

CREATE TYPE bewertung AS ENUM (
    'keine',
    'daumenHoch',
    'daumenRunter'
);


--
-- Name: kategorie; Type: TYPE; Schema: smartinsurance; Owner: -
--

CREATE TYPE kategorie AS ENUM (
    'Auto',
    'Schiff',
    'Flugzeug',
    'Haus',
    'Küchengeräte',
    'Möbel',
    'Maschinen',
    'Uhr'
);


SET search_path = smartbackend, pg_catalog;

--
-- Name: insert_smartbackend_user(text, text, text); Type: FUNCTION; Schema: smartbackend; Owner: -
--

CREATE FUNCTION insert_smartbackend_user(email text, prename text, name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOOP
        -- first try to update the key
        -- note that "a" must be unique
        UPDATE smartbackend.user SET email = email WHERE email = email;
        IF found THEN
            RETURN;
        END IF;
        -- not there, so try to insert the key
        -- if someone else inserts the same key concurrently,
        -- we could get a unique-key failure
        BEGIN
            INSERT INTO smartbackend.user(email,prename,name) VALUES (email,prename,name);
            RETURN;
        EXCEPTION WHEN unique_violation THEN
            -- do nothing, and loop to try the UPDATE again
        END;
    END LOOP;
END;
$$;


--
-- Name: uuid_generate_v1mc(); Type: FUNCTION; Schema: smartbackend; Owner: -
--

CREATE FUNCTION uuid_generate_v1mc() RETURNS uuid
    LANGUAGE c STRICT
    AS '$libdir/uuid-ossp', 'uuid_generate_v1mc';


SET search_path = smartinsurance, pg_catalog;

--
-- Name: createinvestition(integer, uuid, money); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION createinvestition(integer, uuid, money) RETURNS integer
    LANGUAGE sql
    AS $_$
    INSERT INTO smartinsurance."Zahlungsstrom"
       ("versicherungID", "personID", betrag)
       VALUES ($1, $2, $3);
    INSERT INTO smartinsurance."Investition"
       (id, "versicherungID", "personID", investitionshoehe) 
       VALUES (DEFAULT, $1, $2, $3) RETURNING id;
$_$;


--
-- Name: createversicherung(uuid, text, money, money, text, kategorie); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION createversicherung(uuid, text, money, money, text, kategorie) RETURNS integer
    LANGUAGE sql
    AS $_$
    INSERT INTO smartinsurance."Versicherung"
    (id, "personID", name, versicherungshoehe, beitrag, beschreibung, kategorie)
    VALUES ( DEFAULT, $1, $2, $3, $4, $5, $6) RETURNING id;
$_$;


--
-- Name: finalizeinvestitionskuendigung(); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION finalizeinvestitionskuendigung() RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO smartinsurance."Zahlungsstrom"("versicherungID", "personID", betrag)
      SELECT "versicherungID", "personID", investitionshoehe * (-1) 
      FROM smartinsurance."Investition" 
      WHERE smartinsurance."Investition"."wirdGekuendigt"=true;
    UPDATE smartinsurance."Investition"
      SET "istGekuendigt"=true, "wirdGekuendigt"=false, "kuendigungsZeitpunkt"=now() 
      WHERE "wirdGekuendigt"=true;
$$;


--
-- Name: finalizeversicherungskuendigung(); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION finalizeversicherungskuendigung() RETURNS void
    LANGUAGE sql
    AS $$
    UPDATE smartinsurance."Versicherung"
    SET "istGekuendigt"=true, "wirdGekuendigt"=false, "kuendigungsZeitpunkt"=now() 
    WHERE "wirdGekuendigt"=true;
$$;


SET search_path = smartbackend, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: user; Type: TABLE; Schema: smartbackend; Owner: -
--

CREATE TABLE "user" (
    id uuid DEFAULT uuid_generate_v1mc() NOT NULL,
    name text,
    prename text,
    email text
);


SET search_path = smartinsurance, pg_catalog;

--
-- Name: Investition; Type: TABLE; Schema: smartinsurance; Owner: -
--

CREATE TABLE "Investition" (
    id integer NOT NULL,
    "versicherungID" integer NOT NULL,
    investitionshoehe money,
    bewertung bewertung DEFAULT 'keine'::bewertung NOT NULL,
    "abschlussZeitpunkt" timestamp without time zone DEFAULT now(),
    "kuendigungsZeitpunkt" timestamp without time zone,
    "istGekuendigt" boolean DEFAULT false NOT NULL,
    "wirdGekuendigt" boolean DEFAULT false NOT NULL,
    "personID" uuid NOT NULL
);


--
-- Name: InvestitionPerson; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "InvestitionPerson" AS
 SELECT i.id,
    i."versicherungID",
    i."personID",
    p.name AS "personName",
    p.prename AS "personPrename",
    i.investitionshoehe,
    i.bewertung,
    i."abschlussZeitpunkt",
    i."kuendigungsZeitpunkt",
    i."istGekuendigt",
    i."wirdGekuendigt"
   FROM ("Investition" i
     JOIN smartbackend."user" p ON ((i."personID" = p.id)));


--
-- Name: Versicherung; Type: TABLE; Schema: smartinsurance; Owner: -
--

CREATE TABLE "Versicherung" (
    id integer NOT NULL,
    name text NOT NULL,
    versicherungshoehe money NOT NULL,
    beitrag money NOT NULL,
    beschreibung text,
    "abschlussZeitpunkt" timestamp without time zone DEFAULT now(),
    "kuendigungsZeitpunkt" timestamp without time zone,
    "istGekuendigt" boolean DEFAULT false,
    "wirdGekuendigt" boolean DEFAULT false,
    "personID" uuid NOT NULL,
    kategorie kategorie
);


--
-- Name: VersicherungPerson; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "VersicherungPerson" AS
 SELECT v.id,
    v.name,
    v.versicherungshoehe,
    v.beitrag,
    v.beschreibung,
    v."abschlussZeitpunkt",
    v."kuendigungsZeitpunkt",
    v."istGekuendigt",
    v."wirdGekuendigt",
    v."personID",
    v.kategorie,
    p.name AS "personName",
    p.prename AS "personPrename"
   FROM ("Versicherung" v
     JOIN smartbackend."user" p ON ((v."personID" = p.id)));


--
-- Name: InvestitionKomplett; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "InvestitionKomplett" AS
 SELECT i.id,
    i."versicherungID",
    i."personID" AS "ipersonID",
    i."personName" AS "ipersonName",
    i."personPrename" AS "ipersonPrename",
    i.investitionshoehe,
    i.bewertung,
    i."abschlussZeitpunkt" AS "iabschlussZeitpunkt",
    i."kuendigungsZeitpunkt" AS "ikuendigungsZeitpunkt",
    i."istGekuendigt" AS "iistGekuendigt",
    i."wirdGekuendigt" AS "iwirdGekuendigt",
    v."personID" AS "vpersonID",
    v."personName" AS "vpersonName",
    v."personPrename" AS "vpersonPrename",
    v.name,
    v.versicherungshoehe,
    v.beitrag,
    v.beschreibung,
    v."abschlussZeitpunkt" AS "vabschlussZeitpunkt",
    v."kuendigungsZeitpunkt" AS "vkuendigungsZeitpunkt",
    v."istGekuendigt" AS "vistGekuendigt",
    v."wirdGekuendigt" AS "vwirdGekuendigt",
    v.kategorie
   FROM ("VersicherungPerson" v
     JOIN "InvestitionPerson" i ON ((i."versicherungID" = v.id)));


--
-- Name: getinvestitionkomplettbyiid(integer); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getinvestitionkomplettbyiid(integer) RETURNS "InvestitionKomplett"
    LANGUAGE sql
    AS $_$
    SELECT * FROM "InvestitionKomplett" as ik WHERE ik.id = $1;
$_$;


--
-- Name: getinvestitionkomplettbyuid(uuid); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getinvestitionkomplettbyuid(uuid) RETURNS SETOF "InvestitionKomplett"
    LANGUAGE sql
    AS $_$
    SELECT * FROM "InvestitionKomplett" as ik WHERE ik."ipersonID" = $1;
$_$;


--
-- Name: getinvestitionkomplettbyvid(integer); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getinvestitionkomplettbyvid(integer) RETURNS SETOF "InvestitionKomplett"
    LANGUAGE sql
    AS $_$
    SELECT * FROM "InvestitionKomplett" as ik WHERE ik."versicherungID" = $1;
$_$;


--
-- Name: getinvestitionssummebyvid(integer); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getinvestitionssummebyvid(integer) RETURNS money
    LANGUAGE sql
    AS $_$
    SELECT sum(smartinsurance."Investition"."investitionshoehe") as suminvestition
     FROM smartinsurance."Versicherung" INNER JOIN smartinsurance."Investition"
     ON smartinsurance."Versicherung".id=smartinsurance."Investition"."versicherungID" 
     WHERE smartinsurance."Versicherung".id=$1
     AND smartinsurance."Investition"."istGekuendigt"=false;
$_$;


--
-- Name: getkategorien(); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getkategorien() RETURNS kategorie[]
    LANGUAGE sql
    AS $$
    SELECT enum_range(NULL::kategorie);
$$;


--
-- Name: getversicherungpersonbyuid(uuid); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getversicherungpersonbyuid(uuid) RETURNS SETOF "VersicherungPerson"
    LANGUAGE sql
    AS $_$
    SELECT * FROM "VersicherungPerson" as vp WHERE vp."personID" = $1;
$_$;


--
-- Name: getversicherungpersonbyvid(integer); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getversicherungpersonbyvid(integer) RETURNS "VersicherungPerson"
    LANGUAGE sql
    AS $_$
    SELECT * FROM "VersicherungPerson" as vp WHERE vp.id = $1;
$_$;


--
-- Name: Versicherungsbewertungen; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "Versicherungsbewertungen" AS
 SELECT "Investition"."versicherungID",
    "Investition".bewertung,
    count("Investition".bewertung) AS count
   FROM "Investition"
  GROUP BY "Investition"."versicherungID", "Investition".bewertung
  ORDER BY "Investition"."versicherungID", "Investition".bewertung;


--
-- Name: getversicherungsbewertungenbyvid(integer); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION getversicherungsbewertungenbyvid(integer) RETURNS SETOF "Versicherungsbewertungen"
    LANGUAGE sql
    AS $_$
    SELECT * FROM "Versicherungsbewertungen" as vb WHERE vb."versicherungID" = $1;
$_$;


--
-- Name: test_matthias(integer); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION test_matthias(param_id integer) RETURNS SETOF "Versicherung"
    LANGUAGE plpgsql
    AS $$
BEGIN
   RETURN QUERY
   SELECT *
   FROM "smartinsurance"."Versicherung"
   WHERE id = param_id;
END
$$;


--
-- Name: uuid_generate_v1mc(); Type: FUNCTION; Schema: smartinsurance; Owner: -
--

CREATE FUNCTION uuid_generate_v1mc() RETURNS uuid
    LANGUAGE c STRICT
    AS '$libdir/uuid-ossp', 'uuid_generate_v1mc';


SET search_path = smartbackend, pg_catalog;

--
-- Name: address; Type: TABLE; Schema: smartbackend; Owner: -
--

CREATE TABLE address (
    id uuid DEFAULT uuid_generate_v1mc() NOT NULL,
    address_json jsonb,
    fk_user uuid
);


--
-- Name: chat_message; Type: TABLE; Schema: smartbackend; Owner: -
--

CREATE TABLE chat_message (
    id uuid DEFAULT uuid_generate_v1mc() NOT NULL,
    roomid uuid NOT NULL,
    senderid uuid NOT NULL,
    "timestamp" timestamp without time zone DEFAULT now(),
    messagetype messagetype NOT NULL,
    text text
);


--
-- Name: chat_room; Type: TABLE; Schema: smartbackend; Owner: -
--

CREATE TABLE chat_room (
    id uuid DEFAULT uuid_generate_v1mc() NOT NULL,
    "isGeneric" boolean DEFAULT false NOT NULL,
    title text
);


--
-- Name: chat_room_user; Type: TABLE; Schema: smartbackend; Owner: -
--

CREATE TABLE chat_room_user (
    roomid uuid DEFAULT uuid_generate_v1mc() NOT NULL,
    user_id uuid NOT NULL,
    isadmin boolean DEFAULT false NOT NULL
);


SET search_path = smartinsurance, pg_catalog;

--
-- Name: Investition_id_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Investition_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Investition_id_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Investition_id_seq" OWNED BY "Investition".id;


--
-- Name: Investition_versicherungID_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Investition_versicherungID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Investition_versicherungID_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Investition_versicherungID_seq" OWNED BY "Investition"."versicherungID";


--
-- Name: Kommentar; Type: TABLE; Schema: smartinsurance; Owner: -
--

CREATE TABLE "Kommentar" (
    id integer NOT NULL,
    "versicherungID" integer NOT NULL,
    text text,
    zeitpunkt timestamp without time zone,
    "personID" uuid NOT NULL
);


--
-- Name: Kommentar_id_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Kommentar_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Kommentar_id_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Kommentar_id_seq" OWNED BY "Kommentar".id;


--
-- Name: Kommentar_versicherungID_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Kommentar_versicherungID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Kommentar_versicherungID_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Kommentar_versicherungID_seq" OWNED BY "Kommentar"."versicherungID";


--
-- Name: Schadensfall; Type: TABLE; Schema: smartinsurance; Owner: -
--

CREATE TABLE "Schadensfall" (
    id integer NOT NULL,
    "versicherungID" integer NOT NULL,
    beschreibung text,
    schadenshoehe money NOT NULL,
    zeitpunkt timestamp without time zone DEFAULT now(),
    "auszahlungsZeitpunkt" timestamp without time zone,
    "istAusgezahlt" boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN "Schadensfall".zeitpunkt; Type: COMMENT; Schema: smartinsurance; Owner: -
--

COMMENT ON COLUMN "Schadensfall".zeitpunkt IS 'Zeitpunkt der Meldung des Schadensfalls durch den Versicherungsnehmer';


--
-- Name: Schadensfall_Bild; Type: TABLE; Schema: smartinsurance; Owner: -
--

CREATE TABLE "Schadensfall_Bild" (
    id integer NOT NULL,
    "schadensfallID" integer NOT NULL,
    "bildUrl" text
);


--
-- Name: Schadensfall_Bild_ID_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Schadensfall_Bild_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Schadensfall_Bild_ID_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Schadensfall_Bild_ID_seq" OWNED BY "Schadensfall_Bild".id;


--
-- Name: Schadensfall_Bild_schadensfallID_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Schadensfall_Bild_schadensfallID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Schadensfall_Bild_schadensfallID_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Schadensfall_Bild_schadensfallID_seq" OWNED BY "Schadensfall_Bild"."schadensfallID";


--
-- Name: Schadensfall_id_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Schadensfall_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Schadensfall_id_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Schadensfall_id_seq" OWNED BY "Schadensfall".id;


--
-- Name: Schadensfall_versicherungID_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Schadensfall_versicherungID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Schadensfall_versicherungID_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Schadensfall_versicherungID_seq" OWNED BY "Schadensfall"."versicherungID";


--
-- Name: UserDaumen; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "UserDaumen" AS
 SELECT v.versicherter,
    (sum(i.daumenhoch) - sum(i.daumenrunter)) AS bewertung
   FROM (( SELECT "Investition"."versicherungID" AS vid,
            count(
                CASE
                    WHEN ("Investition".bewertung = 'daumenHoch'::bewertung) THEN 1
                    ELSE NULL::integer
                END) AS daumenhoch,
            count(
                CASE
                    WHEN ("Investition".bewertung = 'daumenRunter'::bewertung) THEN 1
                    ELSE NULL::integer
                END) AS daumenrunter
           FROM "Investition"
          GROUP BY "Investition"."versicherungID") i
     JOIN ( SELECT "Versicherung".id,
            "Versicherung"."personID" AS versicherter
           FROM "Versicherung") v ON ((i.vid = v.id)))
  GROUP BY v.versicherter;


--
-- Name: VersicherungAnzahlInvestoren; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "VersicherungAnzahlInvestoren" AS
 SELECT "Investition"."versicherungID" AS id,
    count("Investition"."personID") AS anzahl_investoren
   FROM "Investition"
  WHERE ("Investition"."istGekuendigt" = false)
  GROUP BY "Investition"."versicherungID";


--
-- Name: VersicherungDaumen; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "VersicherungDaumen" AS
 SELECT i.vid AS id,
    (sum(i.daumenhoch) - sum(i.daumenrunter)) AS bewertung
   FROM (( SELECT "Investition"."versicherungID" AS vid,
            count(
                CASE
                    WHEN ("Investition".bewertung = 'daumenHoch'::bewertung) THEN 1
                    ELSE NULL::integer
                END) AS daumenhoch,
            count(
                CASE
                    WHEN ("Investition".bewertung = 'daumenRunter'::bewertung) THEN 1
                    ELSE NULL::integer
                END) AS daumenrunter
           FROM "Investition"
          GROUP BY "Investition"."versicherungID") i
     JOIN ( SELECT "Versicherung".id,
            "Versicherung"."personID" AS versicherter
           FROM "Versicherung") v ON ((i.vid = v.id)))
  GROUP BY i.vid;


--
-- Name: VersicherungRendite; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "VersicherungRendite" AS
 SELECT "Versicherung".id,
    (("Versicherung".beitrag / "Versicherung".versicherungshoehe) * (100)::double precision) AS rendite
   FROM "Versicherung"
  WHERE ("Versicherung"."istGekuendigt" = false);


--
-- Name: VersicherungFilter; Type: VIEW; Schema: smartinsurance; Owner: -
--

CREATE VIEW "VersicherungFilter" AS
 SELECT v.id,
    v.name,
    v.versicherungshoehe,
    v.beitrag,
    v.beschreibung,
    v."abschlussZeitpunkt",
    v."kuendigungsZeitpunkt",
    v."istGekuendigt",
    v."wirdGekuendigt",
    v."personID",
    v.kategorie,
    a.anzahl_investoren,
    b.bewertung,
    r.rendite
   FROM (((( SELECT "Versicherung".id,
            "Versicherung".name,
            "Versicherung".versicherungshoehe,
            "Versicherung".beitrag,
            "Versicherung".beschreibung,
            "Versicherung"."abschlussZeitpunkt",
            "Versicherung"."kuendigungsZeitpunkt",
            "Versicherung"."istGekuendigt",
            "Versicherung"."wirdGekuendigt",
            "Versicherung"."personID",
            "Versicherung".kategorie
           FROM "Versicherung") v
     JOIN ( SELECT "VersicherungAnzahlInvestoren".id,
            "VersicherungAnzahlInvestoren".anzahl_investoren
           FROM "VersicherungAnzahlInvestoren") a ON ((v.id = a.id)))
     LEFT JOIN ( SELECT "VersicherungDaumen".id,
            "VersicherungDaumen".bewertung
           FROM "VersicherungDaumen") b ON ((a.id = b.id)))
     LEFT JOIN ( SELECT "VersicherungRendite".id,
            "VersicherungRendite".rendite
           FROM "VersicherungRendite") r ON ((a.id = r.id)));


--
-- Name: Versicherung_id_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Versicherung_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Versicherung_id_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Versicherung_id_seq" OWNED BY "Versicherung".id;


--
-- Name: Zahlungsstrom; Type: TABLE; Schema: smartinsurance; Owner: -
--

CREATE TABLE "Zahlungsstrom" (
    id integer NOT NULL,
    "versicherungID" integer NOT NULL,
    zeitpunkt timestamp without time zone DEFAULT now(),
    betrag money NOT NULL,
    "personID" uuid NOT NULL
);


--
-- Name: Zahlungsstrom_id_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Zahlungsstrom_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Zahlungsstrom_id_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Zahlungsstrom_id_seq" OWNED BY "Zahlungsstrom".id;


--
-- Name: Zahlungsstrom_versicherungID_seq; Type: SEQUENCE; Schema: smartinsurance; Owner: -
--

CREATE SEQUENCE "Zahlungsstrom_versicherungID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Zahlungsstrom_versicherungID_seq; Type: SEQUENCE OWNED BY; Schema: smartinsurance; Owner: -
--

ALTER SEQUENCE "Zahlungsstrom_versicherungID_seq" OWNED BY "Zahlungsstrom"."versicherungID";


--
-- Name: id; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Investition" ALTER COLUMN id SET DEFAULT nextval('"Investition_id_seq"'::regclass);


--
-- Name: versicherungID; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Investition" ALTER COLUMN "versicherungID" SET DEFAULT nextval('"Investition_versicherungID_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Kommentar" ALTER COLUMN id SET DEFAULT nextval('"Kommentar_id_seq"'::regclass);


--
-- Name: versicherungID; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Kommentar" ALTER COLUMN "versicherungID" SET DEFAULT nextval('"Kommentar_versicherungID_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall" ALTER COLUMN id SET DEFAULT nextval('"Schadensfall_id_seq"'::regclass);


--
-- Name: versicherungID; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall" ALTER COLUMN "versicherungID" SET DEFAULT nextval('"Schadensfall_versicherungID_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall_Bild" ALTER COLUMN id SET DEFAULT nextval('"Schadensfall_Bild_ID_seq"'::regclass);


--
-- Name: schadensfallID; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall_Bild" ALTER COLUMN "schadensfallID" SET DEFAULT nextval('"Schadensfall_Bild_schadensfallID_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Versicherung" ALTER COLUMN id SET DEFAULT nextval('"Versicherung_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Zahlungsstrom" ALTER COLUMN id SET DEFAULT nextval('"Zahlungsstrom_id_seq"'::regclass);


--
-- Name: versicherungID; Type: DEFAULT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Zahlungsstrom" ALTER COLUMN "versicherungID" SET DEFAULT nextval('"Zahlungsstrom_versicherungID_seq"'::regclass);


SET search_path = smartbackend, pg_catalog;

--
-- Name: address_pkey; Type: CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_pkey PRIMARY KEY (id);


--
-- Name: chat_message_pkey; Type: CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);


--
-- Name: chat_room_pkey; Type: CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY chat_room
    ADD CONSTRAINT chat_room_pkey PRIMARY KEY (id);


--
-- Name: chat_room_user_pkey; Type: CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY chat_room_user
    ADD CONSTRAINT chat_room_user_pkey PRIMARY KEY (roomid, user_id);


--
-- Name: user_email_key; Type: CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_email_key UNIQUE (email);


--
-- Name: user_pkey; Type: CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


SET search_path = smartinsurance, pg_catalog;

--
-- Name: Investition_pkey; Type: CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Investition"
    ADD CONSTRAINT "Investition_pkey" PRIMARY KEY (id);


--
-- Name: Kommentar_pkey; Type: CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Kommentar"
    ADD CONSTRAINT "Kommentar_pkey" PRIMARY KEY (id);


--
-- Name: Schadensfall_Bild_pkey; Type: CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall_Bild"
    ADD CONSTRAINT "Schadensfall_Bild_pkey" PRIMARY KEY (id);


--
-- Name: Schadensfall_pkey; Type: CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall"
    ADD CONSTRAINT "Schadensfall_pkey" PRIMARY KEY (id);


--
-- Name: Versicherung_pkey; Type: CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Versicherung"
    ADD CONSTRAINT "Versicherung_pkey" PRIMARY KEY (id);


--
-- Name: Zahlungsstrom_pkey; Type: CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Zahlungsstrom"
    ADD CONSTRAINT "Zahlungsstrom_pkey" PRIMARY KEY (id);


SET search_path = smartbackend, pg_catalog;

--
-- Name: address_fk_user_fkey; Type: FK CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_fk_user_fkey FOREIGN KEY (fk_user) REFERENCES "user"(id);


--
-- Name: chat_message_roomid_fkey; Type: FK CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY chat_message
    ADD CONSTRAINT chat_message_roomid_fkey FOREIGN KEY (roomid) REFERENCES chat_room(id);


--
-- Name: chat_message_senderid_fkey; Type: FK CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY chat_message
    ADD CONSTRAINT chat_message_senderid_fkey FOREIGN KEY (senderid) REFERENCES "user"(id);


--
-- Name: chat_room_user_user_id_fkey; Type: FK CONSTRAINT; Schema: smartbackend; Owner: -
--

ALTER TABLE ONLY chat_room_user
    ADD CONSTRAINT chat_room_user_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user"(id);


SET search_path = smartinsurance, pg_catalog;

--
-- Name: Investition_personID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Investition"
    ADD CONSTRAINT "Investition_personID_fkey" FOREIGN KEY ("personID") REFERENCES smartbackend."user"(id);


--
-- Name: Investition_versicherungID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Investition"
    ADD CONSTRAINT "Investition_versicherungID_fkey" FOREIGN KEY ("versicherungID") REFERENCES "Versicherung"(id);


--
-- Name: Kommentar_personID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Kommentar"
    ADD CONSTRAINT "Kommentar_personID_fkey" FOREIGN KEY ("personID") REFERENCES smartbackend."user"(id);


--
-- Name: Kommentar_versicherungID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Kommentar"
    ADD CONSTRAINT "Kommentar_versicherungID_fkey" FOREIGN KEY ("versicherungID") REFERENCES "Versicherung"(id);


--
-- Name: Schadensfall_Bild_schadensfallID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall_Bild"
    ADD CONSTRAINT "Schadensfall_Bild_schadensfallID_fkey" FOREIGN KEY ("schadensfallID") REFERENCES "Schadensfall"(id);


--
-- Name: Schadensfall_versicherungID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Schadensfall"
    ADD CONSTRAINT "Schadensfall_versicherungID_fkey" FOREIGN KEY ("versicherungID") REFERENCES "Versicherung"(id);


--
-- Name: Versicherung_personID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Versicherung"
    ADD CONSTRAINT "Versicherung_personID_fkey" FOREIGN KEY ("personID") REFERENCES smartbackend."user"(id);


--
-- Name: Zahlungsstrom_personID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Zahlungsstrom"
    ADD CONSTRAINT "Zahlungsstrom_personID_fkey" FOREIGN KEY ("personID") REFERENCES smartbackend."user"(id);


--
-- Name: Zahlungsstrom_versicherungID_fkey; Type: FK CONSTRAINT; Schema: smartinsurance; Owner: -
--

ALTER TABLE ONLY "Zahlungsstrom"
    ADD CONSTRAINT "Zahlungsstrom_versicherungID_fkey" FOREIGN KEY ("versicherungID") REFERENCES "Versicherung"(id);


--
-- PostgreSQL database dump complete
--

