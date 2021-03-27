--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Ubuntu 13.2-1.pgdg18.04+1)
-- Dumped by pg_dump version 13.2 (Ubuntu 13.2-1.pgdg18.04+1)

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

--
-- Name: eth_tx_attempts_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.eth_tx_attempts_state AS ENUM (
    'in_progress',
    'insufficient_eth',
    'broadcast'
);


--
-- Name: eth_txes_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.eth_txes_state AS ENUM (
    'unstarted',
    'in_progress',
    'fatal_error',
    'unconfirmed',
    'confirmed_missing_receipt',
    'confirmed'
);


--
-- Name: run_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.run_status AS ENUM (
    'unstarted',
    'in_progress',
    'pending_incoming_confirmations',
    'pending_outgoing_confirmations',
    'pending_connection',
    'pending_bridge',
    'pending_sleep',
    'errored',
    'completed',
    'cancelled'
);


--
-- Name: notifyethtxinsertion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifyethtxinsertion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
		PERFORM pg_notify('insert_on_eth_txes'::text, NOW()::text);
		RETURN NULL;
        END
        $$;


--
-- Name: notifyjobcreated(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifyjobcreated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            PERFORM pg_notify('insert_on_jobs', NEW.id::text);
            RETURN NEW;
        END
        $$;


--
-- Name: notifyjobdeleted(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifyjobdeleted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		PERFORM pg_notify('delete_from_jobs', OLD.id::text);
		RETURN OLD;
	END
	$$;


--
-- Name: notifypipelinerunstarted(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifypipelinerunstarted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		IF NEW.finished_at IS NULL THEN
			PERFORM pg_notify('pipeline_run_started', NEW.id::text);
		END IF;
		RETURN NEW;
	END
	$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bridge_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bridge_types (
    name text NOT NULL,
    url text NOT NULL,
    confirmations bigint DEFAULT 0 NOT NULL,
    incoming_token_hash text NOT NULL,
    salt text NOT NULL,
    outgoing_token text NOT NULL,
    minimum_contract_payment character varying(255),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configurations (
    id bigint NOT NULL,
    name text NOT NULL,
    value text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configurations_id_seq OWNED BY public.configurations.id;


--
-- Name: cursors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cursors (
    id text NOT NULL,
    cursor character varying(1000) NOT NULL
);


--
-- Name: direct_request_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.direct_request_specs (
    id integer NOT NULL,
    contract_address bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    on_chain_job_spec_id bytea NOT NULL,
    CONSTRAINT direct_request_specs_on_chain_job_spec_id_check CHECK ((octet_length(on_chain_job_spec_id) = 32)),
    CONSTRAINT eth_request_event_specs_contract_address_check CHECK ((octet_length(contract_address) = 20))
);


--
-- Name: encrypted_ocr_key_bundles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encrypted_ocr_key_bundles (
    id bytea NOT NULL,
    on_chain_signing_address bytea NOT NULL,
    off_chain_public_key bytea NOT NULL,
    encrypted_private_keys jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    config_public_key bytea NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: encrypted_p2p_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encrypted_p2p_keys (
    id integer NOT NULL,
    peer_id text NOT NULL,
    pub_key bytea NOT NULL,
    encrypted_priv_key jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT chk_pub_key_length CHECK ((octet_length(pub_key) = 32))
);


--
-- Name: encrypted_p2p_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.encrypted_p2p_keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encrypted_p2p_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.encrypted_p2p_keys_id_seq OWNED BY public.encrypted_p2p_keys.id;


--
-- Name: encrypted_vrf_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encrypted_vrf_keys (
    public_key character varying(68) NOT NULL,
    vrf_key text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: encumbrances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encumbrances (
    id bigint NOT NULL,
    payment numeric(78,0),
    expiration bigint,
    end_at timestamp with time zone,
    oracles text,
    aggregator bytea NOT NULL,
    agg_initiate_job_selector bytea NOT NULL,
    agg_fulfill_selector bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: encumbrances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.encumbrances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encumbrances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.encumbrances_id_seq OWNED BY public.encumbrances.id;


--
-- Name: eth_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eth_receipts (
    id bigint NOT NULL,
    tx_hash bytea NOT NULL,
    block_hash bytea NOT NULL,
    block_number bigint NOT NULL,
    transaction_index bigint NOT NULL,
    receipt jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_hash_length CHECK (((octet_length(tx_hash) = 32) AND (octet_length(block_hash) = 32)))
);


--
-- Name: eth_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eth_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eth_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eth_receipts_id_seq OWNED BY public.eth_receipts.id;


--
-- Name: eth_request_event_specs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eth_request_event_specs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eth_request_event_specs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eth_request_event_specs_id_seq OWNED BY public.direct_request_specs.id;


--
-- Name: eth_task_run_txes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eth_task_run_txes (
    task_run_id uuid NOT NULL,
    eth_tx_id bigint NOT NULL
);


--
-- Name: eth_tx_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eth_tx_attempts (
    id bigint NOT NULL,
    eth_tx_id bigint NOT NULL,
    gas_price numeric(78,0) NOT NULL,
    signed_raw_tx bytea NOT NULL,
    hash bytea NOT NULL,
    broadcast_before_block_num bigint,
    state public.eth_tx_attempts_state NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_cannot_broadcast_before_block_zero CHECK (((broadcast_before_block_num IS NULL) OR (broadcast_before_block_num > 0))),
    CONSTRAINT chk_eth_tx_attempts_fsm CHECK ((((state = ANY (ARRAY['in_progress'::public.eth_tx_attempts_state, 'insufficient_eth'::public.eth_tx_attempts_state])) AND (broadcast_before_block_num IS NULL)) OR (state = 'broadcast'::public.eth_tx_attempts_state))),
    CONSTRAINT chk_hash_length CHECK ((octet_length(hash) = 32)),
    CONSTRAINT chk_signed_raw_tx_present CHECK ((octet_length(signed_raw_tx) > 0))
);


--
-- Name: eth_tx_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eth_tx_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eth_tx_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eth_tx_attempts_id_seq OWNED BY public.eth_tx_attempts.id;


--
-- Name: eth_txes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eth_txes (
    id bigint NOT NULL,
    nonce bigint,
    from_address bytea NOT NULL,
    to_address bytea NOT NULL,
    encoded_payload bytea NOT NULL,
    value numeric(78,0) NOT NULL,
    gas_limit bigint NOT NULL,
    error text,
    broadcast_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    state public.eth_txes_state DEFAULT 'unstarted'::public.eth_txes_state NOT NULL,
    CONSTRAINT chk_broadcast_at_is_sane CHECK ((broadcast_at > '2018-12-31 18:00:00-06'::timestamp with time zone)),
    CONSTRAINT chk_error_cannot_be_empty CHECK (((error IS NULL) OR (length(error) > 0))),
    CONSTRAINT chk_eth_txes_fsm CHECK ((((state = 'unstarted'::public.eth_txes_state) AND (nonce IS NULL) AND (error IS NULL) AND (broadcast_at IS NULL)) OR ((state = 'in_progress'::public.eth_txes_state) AND (nonce IS NOT NULL) AND (error IS NULL) AND (broadcast_at IS NULL)) OR ((state = 'fatal_error'::public.eth_txes_state) AND (nonce IS NULL) AND (error IS NOT NULL) AND (broadcast_at IS NULL)) OR ((state = 'unconfirmed'::public.eth_txes_state) AND (nonce IS NOT NULL) AND (error IS NULL) AND (broadcast_at IS NOT NULL)) OR ((state = 'confirmed'::public.eth_txes_state) AND (nonce IS NOT NULL) AND (error IS NULL) AND (broadcast_at IS NOT NULL)) OR ((state = 'confirmed_missing_receipt'::public.eth_txes_state) AND (nonce IS NOT NULL) AND (error IS NULL) AND (broadcast_at IS NOT NULL)))),
    CONSTRAINT chk_from_address_length CHECK ((octet_length(from_address) = 20)),
    CONSTRAINT chk_to_address_length CHECK ((octet_length(to_address) = 20))
);


--
-- Name: eth_txes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eth_txes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eth_txes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eth_txes_id_seq OWNED BY public.eth_txes.id;


--
-- Name: external_initiators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_initiators (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    name text NOT NULL,
    url text,
    access_key text NOT NULL,
    salt text NOT NULL,
    hashed_secret text NOT NULL,
    outgoing_secret text NOT NULL,
    outgoing_token text NOT NULL
);


--
-- Name: external_initiators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_initiators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_initiators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_initiators_id_seq OWNED BY public.external_initiators.id;


--
-- Name: flux_monitor_round_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flux_monitor_round_stats (
    id bigint NOT NULL,
    aggregator bytea NOT NULL,
    round_id integer NOT NULL,
    num_new_round_logs integer DEFAULT 0 NOT NULL,
    num_submissions integer DEFAULT 0 NOT NULL,
    job_run_id uuid
);


--
-- Name: flux_monitor_round_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flux_monitor_round_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flux_monitor_round_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flux_monitor_round_stats_id_seq OWNED BY public.flux_monitor_round_stats.id;


--
-- Name: flux_monitor_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flux_monitor_specs (
    id integer NOT NULL,
    contract_address bytea NOT NULL,
    "precision" integer,
    threshold real,
    absolute_threshold real,
    poll_timer_period bigint,
    poll_timer_disabled boolean,
    idle_timer_period bigint,
    idle_timer_disabled boolean,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT flux_monitor_specs_check CHECK ((poll_timer_disabled OR (poll_timer_period > 0))),
    CONSTRAINT flux_monitor_specs_check1 CHECK ((idle_timer_disabled OR (idle_timer_period > 0))),
    CONSTRAINT flux_monitor_specs_contract_address_check CHECK ((octet_length(contract_address) = 20))
);


--
-- Name: flux_monitor_specs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flux_monitor_specs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flux_monitor_specs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flux_monitor_specs_id_seq OWNED BY public.flux_monitor_specs.id;


--
-- Name: heads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.heads (
    id bigint NOT NULL,
    hash bytea NOT NULL,
    number bigint NOT NULL,
    parent_hash bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    CONSTRAINT chk_hash_size CHECK ((octet_length(hash) = 32)),
    CONSTRAINT chk_parent_hash_size CHECK ((octet_length(parent_hash) = 32))
);


--
-- Name: heads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.heads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: heads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.heads_id_seq OWNED BY public.heads.id;


--
-- Name: initiators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiators (
    id bigint NOT NULL,
    job_spec_id uuid NOT NULL,
    type text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    schedule text,
    "time" timestamp with time zone,
    ran boolean,
    address bytea,
    requesters text,
    name character varying(255),
    params jsonb,
    from_block numeric(78,0),
    to_block numeric(78,0),
    topics jsonb,
    request_data text,
    feeds text,
    threshold double precision,
    "precision" smallint,
    polling_interval bigint,
    absolute_threshold double precision,
    updated_at timestamp with time zone NOT NULL,
    poll_timer jsonb,
    idle_timer jsonb
);


--
-- Name: initiators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.initiators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: initiators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.initiators_id_seq OWNED BY public.initiators.id;


--
-- Name: job_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_runs (
    result_id bigint,
    run_request_id bigint,
    status public.run_status DEFAULT 'unstarted'::public.run_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    updated_at timestamp with time zone NOT NULL,
    initiator_id bigint NOT NULL,
    deleted_at timestamp with time zone,
    creation_height numeric(78,0),
    observed_height numeric(78,0),
    payment numeric(78,0),
    job_spec_id uuid NOT NULL,
    id uuid NOT NULL
);


--
-- Name: job_spec_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_spec_errors (
    id bigint NOT NULL,
    job_spec_id uuid NOT NULL,
    description text NOT NULL,
    occurrences integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: job_spec_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_spec_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_spec_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_spec_errors_id_seq OWNED BY public.job_spec_errors.id;


--
-- Name: job_spec_errors_v2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_spec_errors_v2 (
    id bigint NOT NULL,
    job_id integer,
    description text NOT NULL,
    occurrences integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: job_spec_errors_v2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_spec_errors_v2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_spec_errors_v2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_spec_errors_v2_id_seq OWNED BY public.job_spec_errors_v2.id;


--
-- Name: job_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_specs (
    created_at timestamp with time zone NOT NULL,
    start_at timestamp with time zone,
    end_at timestamp with time zone,
    deleted_at timestamp with time zone,
    min_payment character varying(255),
    id uuid NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(255)
);


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs (
    id integer NOT NULL,
    pipeline_spec_id integer,
    offchainreporting_oracle_spec_id integer,
    name character varying(255),
    schema_version integer NOT NULL,
    type character varying(255) NOT NULL,
    max_task_duration bigint,
    direct_request_spec_id integer,
    flux_monitor_spec_id integer,
    CONSTRAINT chk_only_one_spec CHECK ((num_nonnulls(offchainreporting_oracle_spec_id, direct_request_spec_id, flux_monitor_spec_id) = 1)),
    CONSTRAINT chk_schema_version CHECK ((schema_version > 0)),
    CONSTRAINT chk_type CHECK (((type)::text <> ''::text))
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.keys (
    address bytea NOT NULL,
    json jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    next_nonce bigint,
    id integer NOT NULL,
    last_used timestamp with time zone,
    is_funding boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT chk_address_length CHECK ((octet_length(address) = 20))
);


--
-- Name: keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.keys_id_seq OWNED BY public.keys.id;


--
-- Name: log_consumptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_consumptions (
    id bigint NOT NULL,
    block_hash bytea NOT NULL,
    log_index bigint NOT NULL,
    job_id uuid,
    created_at timestamp without time zone NOT NULL,
    block_number bigint,
    job_id_v2 integer,
    CONSTRAINT chk_log_consumptions_exactly_one_job_id CHECK ((((job_id IS NOT NULL) AND (job_id_v2 IS NULL)) OR ((job_id_v2 IS NOT NULL) AND (job_id IS NULL))))
);


--
-- Name: log_consumptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_consumptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_consumptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_consumptions_id_seq OWNED BY public.log_consumptions.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations (
    id character varying(255) NOT NULL
);


--
-- Name: offchainreporting_contract_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offchainreporting_contract_configs (
    offchainreporting_oracle_spec_id integer NOT NULL,
    config_digest bytea NOT NULL,
    signers bytea[],
    transmitters bytea[],
    threshold integer,
    encoded_config_version bigint,
    encoded bytea,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT offchainreporting_contract_configs_config_digest_check CHECK ((octet_length(config_digest) = 16))
);


--
-- Name: offchainreporting_oracle_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offchainreporting_oracle_specs (
    id integer NOT NULL,
    contract_address bytea NOT NULL,
    p2p_peer_id text,
    p2p_bootstrap_peers text[],
    is_bootstrap_peer boolean NOT NULL,
    encrypted_ocr_key_bundle_id bytea,
    monitoring_endpoint text,
    transmitter_address bytea,
    observation_timeout bigint,
    blockchain_timeout bigint,
    contract_config_tracker_subscribe_interval bigint,
    contract_config_tracker_poll_interval bigint,
    contract_config_confirmations integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_contract_address_length CHECK ((octet_length(contract_address) = 20))
);


--
-- Name: offchainreporting_oracle_specs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offchainreporting_oracle_specs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offchainreporting_oracle_specs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offchainreporting_oracle_specs_id_seq OWNED BY public.offchainreporting_oracle_specs.id;


--
-- Name: offchainreporting_pending_transmissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offchainreporting_pending_transmissions (
    offchainreporting_oracle_spec_id integer NOT NULL,
    config_digest bytea NOT NULL,
    epoch bigint NOT NULL,
    round bigint NOT NULL,
    "time" timestamp with time zone NOT NULL,
    median numeric(78,0) NOT NULL,
    serialized_report bytea NOT NULL,
    rs bytea[] NOT NULL,
    ss bytea[] NOT NULL,
    vs bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT offchainreporting_pending_transmissions_config_digest_check CHECK ((octet_length(config_digest) = 16))
);


--
-- Name: offchainreporting_persistent_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offchainreporting_persistent_states (
    offchainreporting_oracle_spec_id integer NOT NULL,
    config_digest bytea NOT NULL,
    epoch bigint NOT NULL,
    highest_sent_epoch bigint NOT NULL,
    highest_received_epoch bigint[] NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT offchainreporting_persistent_states_config_digest_check CHECK ((octet_length(config_digest) = 16))
);


--
-- Name: p2p_peers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.p2p_peers (
    id text NOT NULL,
    addr text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    peer_id text NOT NULL
);


--
-- Name: pipeline_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pipeline_runs (
    id bigint NOT NULL,
    pipeline_spec_id integer NOT NULL,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    errors jsonb,
    outputs jsonb,
    CONSTRAINT pipeline_runs_check CHECK ((((outputs IS NULL) AND (errors IS NULL) AND (finished_at IS NULL)) OR ((outputs IS NOT NULL) AND (errors IS NOT NULL) AND (finished_at IS NOT NULL))))
);


--
-- Name: pipeline_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pipeline_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pipeline_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pipeline_runs_id_seq OWNED BY public.pipeline_runs.id;


--
-- Name: pipeline_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pipeline_specs (
    id integer NOT NULL,
    dot_dag_source text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    max_task_duration bigint
);


--
-- Name: pipeline_specs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pipeline_specs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pipeline_specs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pipeline_specs_id_seq OWNED BY public.pipeline_specs.id;


--
-- Name: pipeline_task_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pipeline_task_runs (
    id bigint NOT NULL,
    pipeline_run_id bigint NOT NULL,
    type text NOT NULL,
    index integer DEFAULT 0 NOT NULL,
    output jsonb,
    error text,
    pipeline_task_spec_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    CONSTRAINT chk_pipeline_task_run_fsm CHECK ((((type <> 'result'::text) AND (((finished_at IS NULL) AND (error IS NULL) AND (output IS NULL)) OR ((finished_at IS NOT NULL) AND (NOT ((error IS NOT NULL) AND (output IS NOT NULL)))))) OR ((type = 'result'::text) AND (((output IS NULL) AND (error IS NULL) AND (finished_at IS NULL)) OR ((output IS NOT NULL) AND (error IS NOT NULL) AND (finished_at IS NOT NULL))))))
);


--
-- Name: pipeline_task_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pipeline_task_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pipeline_task_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pipeline_task_runs_id_seq OWNED BY public.pipeline_task_runs.id;


--
-- Name: pipeline_task_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pipeline_task_specs (
    id integer NOT NULL,
    dot_id text NOT NULL,
    pipeline_spec_id integer NOT NULL,
    type text NOT NULL,
    json jsonb NOT NULL,
    index integer DEFAULT 0 NOT NULL,
    successor_id integer,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: COLUMN pipeline_task_specs.dot_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pipeline_task_specs.dot_id IS 'Dot ID is included to help in debugging';


--
-- Name: pipeline_task_specs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pipeline_task_specs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pipeline_task_specs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pipeline_task_specs_id_seq OWNED BY public.pipeline_task_specs.id;


--
-- Name: run_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.run_requests (
    id bigint NOT NULL,
    request_id bytea,
    tx_hash bytea,
    requester bytea,
    created_at timestamp with time zone NOT NULL,
    block_hash bytea,
    payment numeric(78,0),
    request_params jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: run_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.run_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: run_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.run_requests_id_seq OWNED BY public.run_requests.id;


--
-- Name: run_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.run_results (
    id bigint NOT NULL,
    data jsonb,
    error_message text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: run_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.run_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: run_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.run_results_id_seq OWNED BY public.run_results.id;


--
-- Name: service_agreements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_agreements (
    id text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    encumbrance_id bigint,
    request_body text,
    signature character varying(255),
    job_spec_id uuid,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id text NOT NULL,
    last_used timestamp with time zone,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: sync_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_events (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    body text NOT NULL
);


--
-- Name: sync_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sync_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sync_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sync_events_id_seq OWNED BY public.sync_events.id;


--
-- Name: task_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_runs (
    result_id bigint,
    status public.run_status DEFAULT 'unstarted'::public.run_status NOT NULL,
    task_spec_id bigint NOT NULL,
    minimum_confirmations bigint,
    created_at timestamp with time zone NOT NULL,
    confirmations bigint,
    job_run_id uuid NOT NULL,
    id uuid NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: task_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_specs (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    type text NOT NULL,
    confirmations bigint,
    params jsonb,
    job_spec_id uuid NOT NULL
);


--
-- Name: task_specs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.task_specs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: task_specs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.task_specs_id_seq OWNED BY public.task_specs.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    email text NOT NULL,
    hashed_password text,
    created_at timestamp with time zone NOT NULL,
    token_key text,
    token_salt text,
    token_hashed_secret text,
    updated_at timestamp with time zone NOT NULL,
    token_secret text
);


--
-- Name: vrf_request_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vrf_request_jobs (
    id bigint NOT NULL,
    vrf_request_id bigint,
    start_at timestamp with time zone,
    end_at timestamp with time zone,
    status character varying(20),
    retries integer
);


--
-- Name: vrf_request_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vrf_request_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vrf_request_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vrf_request_jobs_id_seq OWNED BY public.vrf_request_jobs.id;


--
-- Name: vrf_request_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vrf_request_runs (
    id bigint NOT NULL,
    vrf_request_job_id bigint,
    start_at timestamp with time zone,
    end_at timestamp with time zone,
    status character varying(20),
    status_msg text
);


--
-- Name: vrf_request_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vrf_request_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vrf_request_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vrf_request_runs_id_seq OWNED BY public.vrf_request_runs.id;


--
-- Name: vrf_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vrf_requests (
    id bigint NOT NULL,
    assoc_id numeric(20,0) NOT NULL,
    block_num numeric(20,0) NOT NULL,
    block_hash character varying(70) NOT NULL,
    seeds character varying(70)[] NOT NULL,
    frequency character varying(25) NOT NULL,
    count integer NOT NULL,
    caller character varying(15) NOT NULL,
    type character varying(15) NOT NULL,
    status character varying(20),
    start_at timestamp with time zone,
    end_at timestamp with time zone,
    cron_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


--
-- Name: vrf_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vrf_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vrf_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vrf_requests_id_seq OWNED BY public.vrf_requests.id;


--
-- Name: configurations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations ALTER COLUMN id SET DEFAULT nextval('public.configurations_id_seq'::regclass);


--
-- Name: direct_request_specs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_request_specs ALTER COLUMN id SET DEFAULT nextval('public.eth_request_event_specs_id_seq'::regclass);


--
-- Name: encrypted_p2p_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encrypted_p2p_keys ALTER COLUMN id SET DEFAULT nextval('public.encrypted_p2p_keys_id_seq'::regclass);


--
-- Name: encumbrances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encumbrances ALTER COLUMN id SET DEFAULT nextval('public.encumbrances_id_seq'::regclass);


--
-- Name: eth_receipts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_receipts ALTER COLUMN id SET DEFAULT nextval('public.eth_receipts_id_seq'::regclass);


--
-- Name: eth_tx_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_tx_attempts ALTER COLUMN id SET DEFAULT nextval('public.eth_tx_attempts_id_seq'::regclass);


--
-- Name: eth_txes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_txes ALTER COLUMN id SET DEFAULT nextval('public.eth_txes_id_seq'::regclass);


--
-- Name: external_initiators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_initiators ALTER COLUMN id SET DEFAULT nextval('public.external_initiators_id_seq'::regclass);


--
-- Name: flux_monitor_round_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flux_monitor_round_stats ALTER COLUMN id SET DEFAULT nextval('public.flux_monitor_round_stats_id_seq'::regclass);


--
-- Name: flux_monitor_specs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flux_monitor_specs ALTER COLUMN id SET DEFAULT nextval('public.flux_monitor_specs_id_seq'::regclass);


--
-- Name: heads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.heads ALTER COLUMN id SET DEFAULT nextval('public.heads_id_seq'::regclass);


--
-- Name: initiators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiators ALTER COLUMN id SET DEFAULT nextval('public.initiators_id_seq'::regclass);


--
-- Name: job_spec_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_spec_errors ALTER COLUMN id SET DEFAULT nextval('public.job_spec_errors_id_seq'::regclass);


--
-- Name: job_spec_errors_v2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_spec_errors_v2 ALTER COLUMN id SET DEFAULT nextval('public.job_spec_errors_v2_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.keys ALTER COLUMN id SET DEFAULT nextval('public.keys_id_seq'::regclass);


--
-- Name: log_consumptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_consumptions ALTER COLUMN id SET DEFAULT nextval('public.log_consumptions_id_seq'::regclass);


--
-- Name: offchainreporting_oracle_specs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_oracle_specs ALTER COLUMN id SET DEFAULT nextval('public.offchainreporting_oracle_specs_id_seq'::regclass);


--
-- Name: pipeline_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_runs ALTER COLUMN id SET DEFAULT nextval('public.pipeline_runs_id_seq'::regclass);


--
-- Name: pipeline_specs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_specs ALTER COLUMN id SET DEFAULT nextval('public.pipeline_specs_id_seq'::regclass);


--
-- Name: pipeline_task_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_runs ALTER COLUMN id SET DEFAULT nextval('public.pipeline_task_runs_id_seq'::regclass);


--
-- Name: pipeline_task_specs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_specs ALTER COLUMN id SET DEFAULT nextval('public.pipeline_task_specs_id_seq'::regclass);


--
-- Name: run_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.run_requests ALTER COLUMN id SET DEFAULT nextval('public.run_requests_id_seq'::regclass);


--
-- Name: run_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.run_results ALTER COLUMN id SET DEFAULT nextval('public.run_results_id_seq'::regclass);


--
-- Name: sync_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events ALTER COLUMN id SET DEFAULT nextval('public.sync_events_id_seq'::regclass);


--
-- Name: task_specs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_specs ALTER COLUMN id SET DEFAULT nextval('public.task_specs_id_seq'::regclass);


--
-- Name: vrf_request_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_request_jobs ALTER COLUMN id SET DEFAULT nextval('public.vrf_request_jobs_id_seq'::regclass);


--
-- Name: vrf_request_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_request_runs ALTER COLUMN id SET DEFAULT nextval('public.vrf_request_runs_id_seq'::regclass);


--
-- Name: vrf_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_requests ALTER COLUMN id SET DEFAULT nextval('public.vrf_requests_id_seq'::regclass);


--
-- Data for Name: bridge_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bridge_types (name, url, confirmations, incoming_token_hash, salt, outgoing_token, minimum_contract_payment, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: configurations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configurations (id, name, value, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: cursors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cursors (id, cursor) FROM stdin;
\.


--
-- Data for Name: direct_request_specs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.direct_request_specs (id, contract_address, created_at, updated_at, on_chain_job_spec_id) FROM stdin;
\.


--
-- Data for Name: encrypted_ocr_key_bundles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.encrypted_ocr_key_bundles (id, on_chain_signing_address, off_chain_public_key, encrypted_private_keys, created_at, updated_at, config_public_key, deleted_at) FROM stdin;
\\x54f02f2756952ee42874182c8a03d51f048b7fc245c05196af50f9266f8e444a	\\xc135508f4c9ada03e56bb6ad98d724e7f4c93323	\\xa91e8a88584c18ad895a259800fa768a63be8760dcc2924ffd6311833aefb8c5	{"kdf": "scrypt", "mac": "acbd1623b39799eedb1fc75698d8e2986599922930032c15a5a3721247c9b748", "cipher": "aes-128-ctr", "kdfparams": {"n": 2, "p": 1, "r": 8, "salt": "ea4f33d745169327d2cdf9f70945af1b67822282c9c01fc2278fa80d6d8e7795", "dklen": 32}, "ciphertext": "e92467755b4abadf162d5d450d963daebe5d2bed6450a77d7c22b705e4f01300a30714a5b4da9686255f569469dc0ed15b4a4fa0acc5439d4257315d7ba033e8c85b6d1a73e1cfc8d0e668e230d9a17117030851794e549dda99bdae7b06501d3d21762ff7b1f7fa494187effdb43cf611fd619d740bc310bb84ccaa449d65f23f1f264491a72b312d9061cea3d3de87168d835339621b38dbb3723b96a694fd86324d319948b4e061ceacb54ce44421f5bf914c158f4e95bf3da039bd0d257241c738488532d4b7fa5cd23d84a8e41ac6653e4b823a3f3f0eb37896d2efebcc3d6061e42a50703621130077e99b96186029661765c8baad9a1bab646a0a10331cc1caf3b9ab926bd39233f06677249bb7d5f5b0a8cb337a2bdce61f2a666128d7b310659e6b8d7dc3039fb876badc3fe961d46778ab905fed2134876cf82bde966b8fabebbc9629c23812b6c80952c06b032af6", "cipherparams": {"iv": "863123caab3f0ae5b3bff6a113a80095"}}	2020-10-29 04:34:25.960967-06	2020-10-29 04:34:25.960967-06	\\x69a2b241acdeee304040940c458f315e911a63d4d6ec16337b123326a00b951f	\N
\.


--
-- Data for Name: encrypted_p2p_keys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.encrypted_p2p_keys (id, peer_id, pub_key, encrypted_priv_key, created_at, updated_at, deleted_at) FROM stdin;
1	12D3KooWCJUPKsYAnCRTQ7SUNULt4Z9qF8Uk1xadhCs7e9M711Lp	\\x24eaaa7f7f8cd6d91bc4a83becedf2bd3650c050d5b680683ae26f0f1e209fdd	{"kdf": "scrypt", "mac": "41957a416ab525a3d1409b0dc7ec2fdd4f14fed9082245c05ae42b71cb2d438b", "cipher": "aes-128-ctr", "kdfparams": {"n": 2, "p": 1, "r": 8, "salt": "032413f1267991b5f2b7d01d5bb912aa9bdf07e1b9b109c45bafb0caa75672bc", "dklen": 32}, "ciphertext": "724604086076ec161831f580a0fbd1c435cddc5a908f37a641c76f401c75f33cc09acefb579d03ca47874645c868515aa044de63e43cbbb19f13273490a7dea46fa421a5", "cipherparams": {"iv": "faed66382c086036966a80ed62cffb77"}}	2020-10-29 04:33:50.854527-06	2020-10-29 04:33:50.854527-06	\N
\.


--
-- Data for Name: encrypted_vrf_keys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.encrypted_vrf_keys (public_key, vrf_key, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: encumbrances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.encumbrances (id, payment, expiration, end_at, oracles, aggregator, agg_initiate_job_selector, agg_fulfill_selector, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: eth_receipts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.eth_receipts (id, tx_hash, block_hash, block_number, transaction_index, receipt, created_at) FROM stdin;
\.


--
-- Data for Name: eth_task_run_txes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.eth_task_run_txes (task_run_id, eth_tx_id) FROM stdin;
\.


--
-- Data for Name: eth_tx_attempts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.eth_tx_attempts (id, eth_tx_id, gas_price, signed_raw_tx, hash, broadcast_before_block_num, state, created_at) FROM stdin;
\.


--
-- Data for Name: eth_txes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.eth_txes (id, nonce, from_address, to_address, encoded_payload, value, gas_limit, error, broadcast_at, created_at, state) FROM stdin;
\.


--
-- Data for Name: external_initiators; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.external_initiators (id, created_at, updated_at, deleted_at, name, url, access_key, salt, hashed_secret, outgoing_secret, outgoing_token) FROM stdin;
\.


--
-- Data for Name: flux_monitor_round_stats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flux_monitor_round_stats (id, aggregator, round_id, num_new_round_logs, num_submissions, job_run_id) FROM stdin;
\.


--
-- Data for Name: flux_monitor_specs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flux_monitor_specs (id, contract_address, "precision", threshold, absolute_threshold, poll_timer_period, poll_timer_disabled, idle_timer_period, idle_timer_disabled, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: heads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.heads (id, hash, number, parent_hash, created_at, "timestamp") FROM stdin;
\.


--
-- Data for Name: initiators; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.initiators (id, job_spec_id, type, created_at, deleted_at, schedule, "time", ran, address, requesters, name, params, from_block, to_block, topics, request_data, feeds, threshold, "precision", polling_interval, absolute_threshold, updated_at, poll_timer, idle_timer) FROM stdin;
\.


--
-- Data for Name: job_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_runs (result_id, run_request_id, status, created_at, finished_at, updated_at, initiator_id, deleted_at, creation_height, observed_height, payment, job_spec_id, id) FROM stdin;
\.


--
-- Data for Name: job_spec_errors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_spec_errors (id, job_spec_id, description, occurrences, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: job_spec_errors_v2; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_spec_errors_v2 (id, job_id, description, occurrences, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: job_specs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_specs (created_at, start_at, end_at, deleted_at, min_payment, id, updated_at, name) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.jobs (id, pipeline_spec_id, offchainreporting_oracle_spec_id, name, schema_version, type, max_task_duration, direct_request_spec_id, flux_monitor_spec_id) FROM stdin;
\.


--
-- Data for Name: keys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.keys (address, json, created_at, updated_at, next_nonce, id, last_used, is_funding, deleted_at) FROM stdin;
\.


--
-- Data for Name: log_consumptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.log_consumptions (id, block_hash, log_index, job_id, created_at, block_number, job_id_v2) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.migrations (id) FROM stdin;
0
1559081901
1559767166
1560433987
1560791143
1560881846
1560886530
1560924400
1560881855
1565139192
1564007745
1565210496
1566498796
1565877314
1566915476
1567029116
1568280052
1565291711
1568390387
1568833756
1570087128
1570675883
1573667511
1573812490
1575036327
1574659987
1576022702
1579700934
1580904019
1581240419
1584377646
1585908150
1585918589
1586163842
1586342453
1586369235
1586939705
1587027516
1587580235
1587591248
1587975059
1586956053
1588293486
1586949323
1588088353
1588757164
1588853064
1589470036
1586871710
1590226486
1591141873
1589206996
1589462363
1591603775
1592355365
1594393769
1594642891
1594306515
1596021087
1596485729
1598521075
1598972982
1599062163
1600504870
1599691818
1600765286
1600881493
1601459029
1601294261
1602180905
1597695690
1603116182
1603724707
1603816329
1604003825
1604437959
1604674426
1604576004
1604707007
migration1605213161
migration1605218542
1605186531
migration1605630295
migration1605816413
migration1606303568
migration1606320711
migration1606910307
migration1606141477
1606749860
1607113528
1607954593
1608289371
1608217193
1609963213
1610630629
1611388693
1611847145
\.


--
-- Data for Name: offchainreporting_contract_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.offchainreporting_contract_configs (offchainreporting_oracle_spec_id, config_digest, signers, transmitters, threshold, encoded_config_version, encoded, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offchainreporting_oracle_specs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.offchainreporting_oracle_specs (id, contract_address, p2p_peer_id, p2p_bootstrap_peers, is_bootstrap_peer, encrypted_ocr_key_bundle_id, monitoring_endpoint, transmitter_address, observation_timeout, blockchain_timeout, contract_config_tracker_subscribe_interval, contract_config_tracker_poll_interval, contract_config_confirmations, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offchainreporting_pending_transmissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.offchainreporting_pending_transmissions (offchainreporting_oracle_spec_id, config_digest, epoch, round, "time", median, serialized_report, rs, ss, vs, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offchainreporting_persistent_states; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.offchainreporting_persistent_states (offchainreporting_oracle_spec_id, config_digest, epoch, highest_sent_epoch, highest_received_epoch, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: p2p_peers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.p2p_peers (id, addr, created_at, updated_at, peer_id) FROM stdin;
\.


--
-- Data for Name: pipeline_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pipeline_runs (id, pipeline_spec_id, meta, created_at, finished_at, errors, outputs) FROM stdin;
\.


--
-- Data for Name: pipeline_specs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pipeline_specs (id, dot_dag_source, created_at, max_task_duration) FROM stdin;
\.


--
-- Data for Name: pipeline_task_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pipeline_task_runs (id, pipeline_run_id, type, index, output, error, pipeline_task_spec_id, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: pipeline_task_specs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pipeline_task_specs (id, dot_id, pipeline_spec_id, type, json, index, successor_id, created_at) FROM stdin;
\.


--
-- Data for Name: run_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.run_requests (id, request_id, tx_hash, requester, created_at, block_hash, payment, request_params) FROM stdin;
\.


--
-- Data for Name: run_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.run_results (id, data, error_message, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: service_agreements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.service_agreements (id, created_at, encumbrance_id, request_body, signature, job_spec_id, updated_at) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sessions (id, last_used, created_at) FROM stdin;
\.


--
-- Data for Name: sync_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sync_events (id, created_at, updated_at, body) FROM stdin;
\.


--
-- Data for Name: task_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.task_runs (result_id, status, task_spec_id, minimum_confirmations, created_at, confirmations, job_run_id, id, updated_at) FROM stdin;
\.


--
-- Data for Name: task_specs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.task_specs (id, created_at, updated_at, deleted_at, type, confirmations, params, job_spec_id) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (email, hashed_password, created_at, token_key, token_salt, token_hashed_secret, updated_at, token_secret) FROM stdin;
apiuser@chainlink.test	$2a$10$bbwErtZcZ6qQvRsfBiY2POvuY6D4lwj/Vxq/PcVAL6o64nRaPgaEa	2019-01-01 00:00:00-06	\N	\N	\N	2019-01-01 00:00:00-06	1eCP/w0llVkchejFaoBpfIGaLRxZK54lTXBCT22YLW+pdzE4Fafy/XO5LoJ2uwHi
\.


--
-- Data for Name: vrf_request_jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vrf_request_jobs (id, vrf_request_id, start_at, end_at, status, retries) FROM stdin;
\.


--
-- Data for Name: vrf_request_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vrf_request_runs (id, vrf_request_job_id, start_at, end_at, status, status_msg) FROM stdin;
\.


--
-- Data for Name: vrf_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vrf_requests (id, assoc_id, block_num, block_hash, seeds, frequency, count, caller, type, status, start_at, end_at, cron_id, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Name: configurations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.configurations_id_seq', 1, false);


--
-- Name: encrypted_p2p_keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.encrypted_p2p_keys_id_seq', 1, true);


--
-- Name: encumbrances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.encumbrances_id_seq', 1, false);


--
-- Name: eth_receipts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.eth_receipts_id_seq', 1, false);


--
-- Name: eth_request_event_specs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.eth_request_event_specs_id_seq', 1, false);


--
-- Name: eth_tx_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.eth_tx_attempts_id_seq', 1, false);


--
-- Name: eth_txes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.eth_txes_id_seq', 1, false);


--
-- Name: external_initiators_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.external_initiators_id_seq', 1, false);


--
-- Name: flux_monitor_round_stats_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.flux_monitor_round_stats_id_seq', 1, false);


--
-- Name: flux_monitor_specs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.flux_monitor_specs_id_seq', 1, false);


--
-- Name: heads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.heads_id_seq', 1, false);


--
-- Name: initiators_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.initiators_id_seq', 1, false);


--
-- Name: job_spec_errors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.job_spec_errors_id_seq', 1, false);


--
-- Name: job_spec_errors_v2_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.job_spec_errors_v2_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.keys_id_seq', 1, false);


--
-- Name: log_consumptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.log_consumptions_id_seq', 1, false);


--
-- Name: offchainreporting_oracle_specs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.offchainreporting_oracle_specs_id_seq', 1, false);


--
-- Name: pipeline_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pipeline_runs_id_seq', 1, false);


--
-- Name: pipeline_specs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pipeline_specs_id_seq', 1, false);


--
-- Name: pipeline_task_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pipeline_task_runs_id_seq', 1, false);


--
-- Name: pipeline_task_specs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pipeline_task_specs_id_seq', 1, false);


--
-- Name: run_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.run_requests_id_seq', 1, false);


--
-- Name: run_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.run_results_id_seq', 1, false);


--
-- Name: sync_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sync_events_id_seq', 1, false);


--
-- Name: task_specs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.task_specs_id_seq', 1, false);


--
-- Name: vrf_request_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vrf_request_jobs_id_seq', 1, false);


--
-- Name: vrf_request_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vrf_request_runs_id_seq', 1, false);


--
-- Name: vrf_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vrf_requests_id_seq', 1, false);


--
-- Name: bridge_types bridge_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bridge_types
    ADD CONSTRAINT bridge_types_pkey PRIMARY KEY (name);


--
-- Name: configurations configurations_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_name_key UNIQUE (name);


--
-- Name: configurations configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);


--
-- Name: cursors cursors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cursors
    ADD CONSTRAINT cursors_pkey PRIMARY KEY (id);


--
-- Name: direct_request_specs direct_request_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_request_specs
    ADD CONSTRAINT direct_request_specs_pkey PRIMARY KEY (id);


--
-- Name: encrypted_ocr_key_bundles encrypted_ocr_key_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encrypted_ocr_key_bundles
    ADD CONSTRAINT encrypted_ocr_key_bundles_pkey PRIMARY KEY (id);


--
-- Name: encrypted_p2p_keys encrypted_p2p_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encrypted_p2p_keys
    ADD CONSTRAINT encrypted_p2p_keys_pkey PRIMARY KEY (id);


--
-- Name: encrypted_vrf_keys encrypted_secret_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encrypted_vrf_keys
    ADD CONSTRAINT encrypted_secret_keys_pkey PRIMARY KEY (public_key);


--
-- Name: encumbrances encumbrances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encumbrances
    ADD CONSTRAINT encumbrances_pkey PRIMARY KEY (id);


--
-- Name: eth_receipts eth_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_receipts
    ADD CONSTRAINT eth_receipts_pkey PRIMARY KEY (id);


--
-- Name: eth_tx_attempts eth_tx_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_tx_attempts
    ADD CONSTRAINT eth_tx_attempts_pkey PRIMARY KEY (id);


--
-- Name: eth_txes eth_txes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_txes
    ADD CONSTRAINT eth_txes_pkey PRIMARY KEY (id);


--
-- Name: external_initiators external_initiators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_initiators
    ADD CONSTRAINT external_initiators_pkey PRIMARY KEY (id);


--
-- Name: flux_monitor_round_stats flux_monitor_round_stats_aggregator_round_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flux_monitor_round_stats
    ADD CONSTRAINT flux_monitor_round_stats_aggregator_round_id_key UNIQUE (aggregator, round_id);


--
-- Name: flux_monitor_round_stats flux_monitor_round_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flux_monitor_round_stats
    ADD CONSTRAINT flux_monitor_round_stats_pkey PRIMARY KEY (id);


--
-- Name: flux_monitor_specs flux_monitor_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flux_monitor_specs
    ADD CONSTRAINT flux_monitor_specs_pkey PRIMARY KEY (id);


--
-- Name: heads heads_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.heads
    ADD CONSTRAINT heads_pkey1 PRIMARY KEY (id);


--
-- Name: initiators initiators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiators
    ADD CONSTRAINT initiators_pkey PRIMARY KEY (id);


--
-- Name: job_runs job_run_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT job_run_pkey PRIMARY KEY (id);


--
-- Name: job_spec_errors job_spec_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_spec_errors
    ADD CONSTRAINT job_spec_errors_pkey PRIMARY KEY (id);


--
-- Name: job_spec_errors_v2 job_spec_errors_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_spec_errors_v2
    ADD CONSTRAINT job_spec_errors_v2_pkey PRIMARY KEY (id);


--
-- Name: job_specs job_spec_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_specs
    ADD CONSTRAINT job_spec_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: keys keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_pkey PRIMARY KEY (id);


--
-- Name: log_consumptions log_consumptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_consumptions
    ADD CONSTRAINT log_consumptions_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: offchainreporting_contract_configs offchainreporting_contract_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_contract_configs
    ADD CONSTRAINT offchainreporting_contract_configs_pkey PRIMARY KEY (offchainreporting_oracle_spec_id);


--
-- Name: offchainreporting_oracle_specs offchainreporting_oracle_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_oracle_specs
    ADD CONSTRAINT offchainreporting_oracle_specs_pkey PRIMARY KEY (id);


--
-- Name: offchainreporting_pending_transmissions offchainreporting_pending_transmissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_pending_transmissions
    ADD CONSTRAINT offchainreporting_pending_transmissions_pkey PRIMARY KEY (offchainreporting_oracle_spec_id, config_digest, epoch, round);


--
-- Name: offchainreporting_persistent_states offchainreporting_persistent_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_persistent_states
    ADD CONSTRAINT offchainreporting_persistent_states_pkey PRIMARY KEY (offchainreporting_oracle_spec_id, config_digest);


--
-- Name: pipeline_runs pipeline_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_runs
    ADD CONSTRAINT pipeline_runs_pkey PRIMARY KEY (id);


--
-- Name: pipeline_specs pipeline_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_specs
    ADD CONSTRAINT pipeline_specs_pkey PRIMARY KEY (id);


--
-- Name: pipeline_task_runs pipeline_task_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_runs
    ADD CONSTRAINT pipeline_task_runs_pkey PRIMARY KEY (id);


--
-- Name: pipeline_task_specs pipeline_task_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_specs
    ADD CONSTRAINT pipeline_task_specs_pkey PRIMARY KEY (id);


--
-- Name: run_requests run_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.run_requests
    ADD CONSTRAINT run_requests_pkey PRIMARY KEY (id);


--
-- Name: run_results run_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.run_results
    ADD CONSTRAINT run_results_pkey PRIMARY KEY (id);


--
-- Name: service_agreements service_agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_agreements
    ADD CONSTRAINT service_agreements_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sync_events sync_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events
    ADD CONSTRAINT sync_events_pkey PRIMARY KEY (id);


--
-- Name: task_runs task_run_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_runs
    ADD CONSTRAINT task_run_pkey PRIMARY KEY (id);


--
-- Name: task_specs task_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_specs
    ADD CONSTRAINT task_specs_pkey PRIMARY KEY (id);


--
-- Name: offchainreporting_oracle_specs unique_contract_addr; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_oracle_specs
    ADD CONSTRAINT unique_contract_addr UNIQUE (contract_address);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (email);


--
-- Name: vrf_request_jobs vrf_request_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_request_jobs
    ADD CONSTRAINT vrf_request_jobs_pkey PRIMARY KEY (id);


--
-- Name: vrf_request_runs vrf_request_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_request_runs
    ADD CONSTRAINT vrf_request_runs_pkey PRIMARY KEY (id);


--
-- Name: vrf_requests vrf_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_requests
    ADD CONSTRAINT vrf_requests_pkey PRIMARY KEY (id);


--
-- Name: external_initiators_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX external_initiators_name_key ON public.external_initiators USING btree (lower(name));


--
-- Name: idx_bridge_types_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bridge_types_created_at ON public.bridge_types USING brin (created_at);


--
-- Name: idx_bridge_types_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bridge_types_updated_at ON public.bridge_types USING brin (updated_at);


--
-- Name: idx_configurations_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_configurations_name ON public.configurations USING btree (name);


--
-- Name: idx_direct_request_specs_unique_job_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_direct_request_specs_unique_job_spec_id ON public.direct_request_specs USING btree (on_chain_job_spec_id);


--
-- Name: idx_encumbrances_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_encumbrances_created_at ON public.encumbrances USING brin (created_at);


--
-- Name: idx_encumbrances_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_encumbrances_updated_at ON public.encumbrances USING brin (updated_at);


--
-- Name: idx_eth_receipts_block_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_receipts_block_number ON public.eth_receipts USING btree (block_number);


--
-- Name: idx_eth_receipts_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_receipts_created_at ON public.eth_receipts USING brin (created_at);


--
-- Name: idx_eth_receipts_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_eth_receipts_unique ON public.eth_receipts USING btree (tx_hash, block_hash);


--
-- Name: idx_eth_task_run_txes_eth_tx_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_eth_task_run_txes_eth_tx_id ON public.eth_task_run_txes USING btree (eth_tx_id);


--
-- Name: idx_eth_task_run_txes_task_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_eth_task_run_txes_task_run_id ON public.eth_task_run_txes USING btree (task_run_id);


--
-- Name: idx_eth_tx_attempts_broadcast_before_block_num; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_tx_attempts_broadcast_before_block_num ON public.eth_tx_attempts USING btree (broadcast_before_block_num);


--
-- Name: idx_eth_tx_attempts_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_tx_attempts_created_at ON public.eth_tx_attempts USING brin (created_at);


--
-- Name: idx_eth_tx_attempts_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_eth_tx_attempts_hash ON public.eth_tx_attempts USING btree (hash);


--
-- Name: idx_eth_tx_attempts_in_progress; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_tx_attempts_in_progress ON public.eth_tx_attempts USING btree (state) WHERE (state = 'in_progress'::public.eth_tx_attempts_state);


--
-- Name: idx_eth_tx_attempts_unique_gas_prices; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_eth_tx_attempts_unique_gas_prices ON public.eth_tx_attempts USING btree (eth_tx_id, gas_price);


--
-- Name: idx_eth_txes_broadcast_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_txes_broadcast_at ON public.eth_txes USING brin (broadcast_at);


--
-- Name: idx_eth_txes_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_txes_created_at ON public.eth_txes USING brin (created_at);


--
-- Name: idx_eth_txes_min_unconfirmed_nonce_for_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_txes_min_unconfirmed_nonce_for_key ON public.eth_txes USING btree (nonce, from_address) WHERE (state = 'unconfirmed'::public.eth_txes_state);


--
-- Name: idx_eth_txes_nonce_from_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_eth_txes_nonce_from_address ON public.eth_txes USING btree (nonce, from_address);


--
-- Name: idx_eth_txes_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_eth_txes_state ON public.eth_txes USING btree (state) WHERE (state <> 'confirmed'::public.eth_txes_state);


--
-- Name: idx_external_initiators_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_initiators_deleted_at ON public.external_initiators USING btree (deleted_at);


--
-- Name: idx_heads_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_heads_hash ON public.heads USING btree (hash);


--
-- Name: idx_heads_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_heads_number ON public.heads USING btree (number);


--
-- Name: idx_initiators_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiators_address ON public.initiators USING btree (address);


--
-- Name: idx_initiators_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiators_created_at ON public.initiators USING btree (created_at);


--
-- Name: idx_initiators_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiators_deleted_at ON public.initiators USING btree (deleted_at);


--
-- Name: idx_initiators_job_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiators_job_spec_id ON public.initiators USING btree (job_spec_id);


--
-- Name: idx_initiators_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiators_type ON public.initiators USING btree (type);


--
-- Name: idx_initiators_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiators_updated_at ON public.initiators USING brin (updated_at);


--
-- Name: idx_job_runs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_created_at ON public.job_runs USING brin (created_at);


--
-- Name: idx_job_runs_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_deleted_at ON public.job_runs USING btree (deleted_at);


--
-- Name: idx_job_runs_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_finished_at ON public.job_runs USING brin (finished_at);


--
-- Name: idx_job_runs_initiator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_initiator_id ON public.job_runs USING btree (initiator_id);


--
-- Name: idx_job_runs_job_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_job_spec_id ON public.job_runs USING btree (job_spec_id);


--
-- Name: idx_job_runs_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_result_id ON public.job_runs USING btree (result_id);


--
-- Name: idx_job_runs_run_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_run_request_id ON public.job_runs USING btree (run_request_id);


--
-- Name: idx_job_runs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_status ON public.job_runs USING btree (status) WHERE (status <> 'completed'::public.run_status);


--
-- Name: idx_job_runs_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_runs_updated_at ON public.job_runs USING brin (updated_at);


--
-- Name: idx_job_spec_errors_v2_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_spec_errors_v2_created_at ON public.job_spec_errors_v2 USING brin (created_at);


--
-- Name: idx_job_spec_errors_v2_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_spec_errors_v2_finished_at ON public.job_spec_errors_v2 USING brin (updated_at);


--
-- Name: idx_job_specs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_specs_created_at ON public.job_specs USING btree (created_at);


--
-- Name: idx_job_specs_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_specs_deleted_at ON public.job_specs USING btree (deleted_at);


--
-- Name: idx_job_specs_end_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_specs_end_at ON public.job_specs USING btree (end_at);


--
-- Name: idx_job_specs_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_specs_start_at ON public.job_specs USING btree (start_at);


--
-- Name: idx_job_specs_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_specs_updated_at ON public.job_specs USING brin (updated_at);


--
-- Name: idx_jobs_unique_direct_request_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_jobs_unique_direct_request_spec_id ON public.jobs USING btree (direct_request_spec_id);


--
-- Name: idx_jobs_unique_offchain_reporting_oracle_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_jobs_unique_offchain_reporting_oracle_spec_id ON public.jobs USING btree (offchainreporting_oracle_spec_id);


--
-- Name: idx_jobs_unique_pipeline_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_jobs_unique_pipeline_spec_id ON public.jobs USING btree (pipeline_spec_id);


--
-- Name: idx_keys_only_one_funding; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_keys_only_one_funding ON public.keys USING btree (is_funding) WHERE (is_funding = true);


--
-- Name: idx_offchainreporting_oracle_specs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_offchainreporting_oracle_specs_created_at ON public.offchainreporting_oracle_specs USING brin (created_at);


--
-- Name: idx_offchainreporting_oracle_specs_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_offchainreporting_oracle_specs_updated_at ON public.offchainreporting_oracle_specs USING brin (updated_at);


--
-- Name: idx_offchainreporting_pending_transmissions_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_offchainreporting_pending_transmissions_time ON public.offchainreporting_pending_transmissions USING btree ("time");


--
-- Name: idx_only_one_in_progress_attempt_per_eth_tx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_only_one_in_progress_attempt_per_eth_tx ON public.eth_tx_attempts USING btree (eth_tx_id) WHERE (state = 'in_progress'::public.eth_tx_attempts_state);


--
-- Name: idx_only_one_in_progress_tx_per_account; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_only_one_in_progress_tx_per_account ON public.eth_txes USING btree (from_address) WHERE (state = 'in_progress'::public.eth_txes_state);


--
-- Name: idx_pipeline_runs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_runs_created_at ON public.pipeline_runs USING brin (created_at);


--
-- Name: idx_pipeline_runs_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_runs_finished_at ON public.pipeline_runs USING brin (finished_at);


--
-- Name: idx_pipeline_runs_pipeline_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_runs_pipeline_spec_id ON public.pipeline_runs USING btree (pipeline_spec_id);


--
-- Name: idx_pipeline_runs_unfinished_runs; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_runs_unfinished_runs ON public.pipeline_runs USING btree (id) WHERE (finished_at IS NULL);


--
-- Name: idx_pipeline_specs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_specs_created_at ON public.pipeline_specs USING brin (created_at);


--
-- Name: idx_pipeline_task_runs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_task_runs_created_at ON public.pipeline_task_runs USING brin (created_at);


--
-- Name: idx_pipeline_task_runs_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_task_runs_finished_at ON public.pipeline_task_runs USING brin (finished_at);


--
-- Name: idx_pipeline_task_runs_optimise_find_results; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_task_runs_optimise_find_results ON public.pipeline_task_runs USING btree (pipeline_run_id);


--
-- Name: idx_pipeline_task_specs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_task_specs_created_at ON public.pipeline_task_specs USING brin (created_at);


--
-- Name: idx_pipeline_task_specs_pipeline_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_task_specs_pipeline_spec_id ON public.pipeline_task_specs USING btree (pipeline_spec_id);


--
-- Name: idx_pipeline_task_specs_single_output; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_pipeline_task_specs_single_output ON public.pipeline_task_specs USING btree (pipeline_spec_id) WHERE (successor_id IS NULL);


--
-- Name: idx_pipeline_task_specs_successor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_task_specs_successor_id ON public.pipeline_task_specs USING btree (successor_id);


--
-- Name: idx_run_requests_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_run_requests_created_at ON public.run_requests USING brin (created_at);


--
-- Name: idx_run_results_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_run_results_created_at ON public.run_results USING brin (created_at);


--
-- Name: idx_run_results_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_run_results_updated_at ON public.run_results USING brin (updated_at);


--
-- Name: idx_service_agreements_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_agreements_created_at ON public.service_agreements USING btree (created_at);


--
-- Name: idx_service_agreements_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_agreements_updated_at ON public.service_agreements USING brin (updated_at);


--
-- Name: idx_sessions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_created_at ON public.sessions USING brin (created_at);


--
-- Name: idx_sessions_last_used; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_last_used ON public.sessions USING brin (last_used);


--
-- Name: idx_task_runs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_runs_created_at ON public.task_runs USING brin (created_at);


--
-- Name: idx_task_runs_job_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_runs_job_run_id ON public.task_runs USING btree (job_run_id);


--
-- Name: idx_task_runs_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_runs_result_id ON public.task_runs USING btree (result_id);


--
-- Name: idx_task_runs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_runs_status ON public.task_runs USING btree (status) WHERE (status <> 'completed'::public.run_status);


--
-- Name: idx_task_runs_task_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_runs_task_spec_id ON public.task_runs USING btree (task_spec_id);


--
-- Name: idx_task_runs_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_runs_updated_at ON public.task_runs USING brin (updated_at);


--
-- Name: idx_task_specs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_specs_created_at ON public.task_specs USING brin (created_at);


--
-- Name: idx_task_specs_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_specs_deleted_at ON public.task_specs USING btree (deleted_at);


--
-- Name: idx_task_specs_job_spec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_specs_job_spec_id ON public.task_specs USING btree (job_spec_id);


--
-- Name: idx_task_specs_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_specs_type ON public.task_specs USING btree (type);


--
-- Name: idx_task_specs_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_specs_updated_at ON public.task_specs USING brin (updated_at);


--
-- Name: idx_unique_keys_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_unique_keys_address ON public.keys USING btree (address);


--
-- Name: idx_unique_peer_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_unique_peer_ids ON public.encrypted_p2p_keys USING btree (peer_id);


--
-- Name: idx_unique_pub_keys; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_unique_pub_keys ON public.encrypted_p2p_keys USING btree (pub_key);


--
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- Name: idx_users_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_updated_at ON public.users USING brin (updated_at);


--
-- Name: idx_vrf_request_jobs_end_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_request_jobs_end_at ON public.vrf_request_jobs USING btree (end_at);


--
-- Name: idx_vrf_request_jobs_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_request_jobs_start_at ON public.vrf_request_jobs USING btree (start_at);


--
-- Name: idx_vrf_request_jobs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_request_jobs_status ON public.vrf_request_jobs USING btree (status);


--
-- Name: idx_vrf_request_runs_end_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_request_runs_end_at ON public.vrf_request_runs USING btree (end_at);


--
-- Name: idx_vrf_request_runs_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_request_runs_start_at ON public.vrf_request_runs USING btree (start_at);


--
-- Name: idx_vrf_request_runs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_request_runs_status ON public.vrf_request_runs USING btree (status);


--
-- Name: idx_vrf_request_runs_status_msg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_request_runs_status_msg ON public.vrf_request_runs USING btree (status_msg);


--
-- Name: idx_vrf_requests_assoc_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_assoc_id ON public.vrf_requests USING btree (assoc_id);


--
-- Name: idx_vrf_requests_caller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_caller ON public.vrf_requests USING btree (caller);


--
-- Name: idx_vrf_requests_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_deleted_at ON public.vrf_requests USING btree (deleted_at);


--
-- Name: idx_vrf_requests_end_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_end_at ON public.vrf_requests USING btree (end_at);


--
-- Name: idx_vrf_requests_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_start_at ON public.vrf_requests USING btree (start_at);


--
-- Name: idx_vrf_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_status ON public.vrf_requests USING btree (status);


--
-- Name: idx_vrf_requests_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_type ON public.vrf_requests USING btree (type);


--
-- Name: idx_vrf_requests_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vrf_requests_updated_at ON public.vrf_requests USING btree (updated_at);


--
-- Name: job_spec_errors_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX job_spec_errors_created_at_idx ON public.job_spec_errors USING brin (created_at);


--
-- Name: job_spec_errors_occurrences_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX job_spec_errors_occurrences_idx ON public.job_spec_errors USING btree (occurrences);


--
-- Name: job_spec_errors_unique_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX job_spec_errors_unique_idx ON public.job_spec_errors USING btree (job_spec_id, description);


--
-- Name: job_spec_errors_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX job_spec_errors_updated_at_idx ON public.job_spec_errors USING brin (updated_at);


--
-- Name: job_spec_errors_v2_unique_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX job_spec_errors_v2_unique_idx ON public.job_spec_errors_v2 USING btree (job_id, description);


--
-- Name: log_consumptions_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX log_consumptions_created_at_idx ON public.log_consumptions USING brin (created_at);


--
-- Name: log_consumptions_unique_v1_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX log_consumptions_unique_v1_idx ON public.log_consumptions USING btree (job_id, block_hash, log_index);


--
-- Name: log_consumptions_unique_v2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX log_consumptions_unique_v2_idx ON public.log_consumptions USING btree (job_id_v2, block_hash, log_index);


--
-- Name: p2p_peers_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX p2p_peers_id ON public.p2p_peers USING btree (id);


--
-- Name: p2p_peers_peer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX p2p_peers_peer_id ON public.p2p_peers USING btree (peer_id);


--
-- Name: sync_events_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sync_events_id_created_at_idx ON public.sync_events USING btree (id, created_at);


--
-- Name: eth_txes notify_eth_tx_insertion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notify_eth_tx_insertion AFTER INSERT ON public.eth_txes FOR EACH STATEMENT EXECUTE FUNCTION public.notifyethtxinsertion();


--
-- Name: jobs notify_job_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notify_job_created AFTER INSERT ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.notifyjobcreated();


--
-- Name: jobs notify_job_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notify_job_deleted AFTER DELETE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.notifyjobdeleted();


--
-- Name: pipeline_runs notify_pipeline_run_started; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notify_pipeline_run_started AFTER INSERT ON public.pipeline_runs FOR EACH ROW EXECUTE FUNCTION public.notifypipelinerunstarted();


--
-- Name: eth_receipts eth_receipts_tx_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_receipts
    ADD CONSTRAINT eth_receipts_tx_hash_fkey FOREIGN KEY (tx_hash) REFERENCES public.eth_tx_attempts(hash) ON DELETE CASCADE;


--
-- Name: eth_task_run_txes eth_task_run_txes_eth_tx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_task_run_txes
    ADD CONSTRAINT eth_task_run_txes_eth_tx_id_fkey FOREIGN KEY (eth_tx_id) REFERENCES public.eth_txes(id) ON DELETE CASCADE;


--
-- Name: eth_task_run_txes eth_task_run_txes_task_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_task_run_txes
    ADD CONSTRAINT eth_task_run_txes_task_run_id_fkey FOREIGN KEY (task_run_id) REFERENCES public.task_runs(id) ON DELETE CASCADE;


--
-- Name: eth_tx_attempts eth_tx_attempts_eth_tx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_tx_attempts
    ADD CONSTRAINT eth_tx_attempts_eth_tx_id_fkey FOREIGN KEY (eth_tx_id) REFERENCES public.eth_txes(id) ON DELETE CASCADE;


--
-- Name: eth_txes eth_txes_from_address_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eth_txes
    ADD CONSTRAINT eth_txes_from_address_fkey FOREIGN KEY (from_address) REFERENCES public.keys(address);


--
-- Name: initiators fk_initiators_job_spec_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiators
    ADD CONSTRAINT fk_initiators_job_spec_id FOREIGN KEY (job_spec_id) REFERENCES public.job_specs(id) ON DELETE RESTRICT;


--
-- Name: job_runs fk_job_runs_initiator_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT fk_job_runs_initiator_id FOREIGN KEY (initiator_id) REFERENCES public.initiators(id) ON DELETE CASCADE;


--
-- Name: job_runs fk_job_runs_result_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT fk_job_runs_result_id FOREIGN KEY (result_id) REFERENCES public.run_results(id) ON DELETE CASCADE;


--
-- Name: job_runs fk_job_runs_run_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT fk_job_runs_run_request_id FOREIGN KEY (run_request_id) REFERENCES public.run_requests(id) ON DELETE CASCADE;


--
-- Name: service_agreements fk_service_agreements_encumbrance_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_agreements
    ADD CONSTRAINT fk_service_agreements_encumbrance_id FOREIGN KEY (encumbrance_id) REFERENCES public.encumbrances(id) ON DELETE RESTRICT;


--
-- Name: task_runs fk_task_runs_result_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_runs
    ADD CONSTRAINT fk_task_runs_result_id FOREIGN KEY (result_id) REFERENCES public.run_results(id) ON DELETE CASCADE;


--
-- Name: task_runs fk_task_runs_task_spec_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_runs
    ADD CONSTRAINT fk_task_runs_task_spec_id FOREIGN KEY (task_spec_id) REFERENCES public.task_specs(id) ON DELETE CASCADE;


--
-- Name: flux_monitor_round_stats flux_monitor_round_stats_job_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flux_monitor_round_stats
    ADD CONSTRAINT flux_monitor_round_stats_job_run_id_fkey FOREIGN KEY (job_run_id) REFERENCES public.job_runs(id) ON DELETE CASCADE;


--
-- Name: job_runs job_runs_job_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT job_runs_job_spec_id_fkey FOREIGN KEY (job_spec_id) REFERENCES public.job_specs(id) ON DELETE CASCADE;


--
-- Name: job_spec_errors job_spec_errors_job_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_spec_errors
    ADD CONSTRAINT job_spec_errors_job_spec_id_fkey FOREIGN KEY (job_spec_id) REFERENCES public.job_specs(id) ON DELETE CASCADE;


--
-- Name: job_spec_errors_v2 job_spec_errors_v2_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_spec_errors_v2
    ADD CONSTRAINT job_spec_errors_v2_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: jobs jobs_direct_request_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_direct_request_spec_id_fkey FOREIGN KEY (direct_request_spec_id) REFERENCES public.direct_request_specs(id);


--
-- Name: jobs jobs_flux_monitor_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_flux_monitor_spec_id_fkey FOREIGN KEY (flux_monitor_spec_id) REFERENCES public.flux_monitor_specs(id);


--
-- Name: jobs jobs_offchainreporting_oracle_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_offchainreporting_oracle_spec_id_fkey FOREIGN KEY (offchainreporting_oracle_spec_id) REFERENCES public.offchainreporting_oracle_specs(id) ON DELETE CASCADE;


--
-- Name: jobs jobs_pipeline_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pipeline_spec_id_fkey FOREIGN KEY (pipeline_spec_id) REFERENCES public.pipeline_specs(id) ON DELETE CASCADE;


--
-- Name: log_consumptions log_consumptions_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_consumptions
    ADD CONSTRAINT log_consumptions_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.job_specs(id) ON DELETE CASCADE;


--
-- Name: log_consumptions log_consumptions_job_id_v2_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_consumptions
    ADD CONSTRAINT log_consumptions_job_id_v2_fkey FOREIGN KEY (job_id_v2) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: offchainreporting_contract_configs offchainreporting_contract_co_offchainreporting_oracle_spe_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_contract_configs
    ADD CONSTRAINT offchainreporting_contract_co_offchainreporting_oracle_spe_fkey FOREIGN KEY (offchainreporting_oracle_spec_id) REFERENCES public.offchainreporting_oracle_specs(id) ON DELETE CASCADE;


--
-- Name: offchainreporting_oracle_specs offchainreporting_oracle_specs_encrypted_ocr_key_bundle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_oracle_specs
    ADD CONSTRAINT offchainreporting_oracle_specs_encrypted_ocr_key_bundle_id_fkey FOREIGN KEY (encrypted_ocr_key_bundle_id) REFERENCES public.encrypted_ocr_key_bundles(id);


--
-- Name: offchainreporting_oracle_specs offchainreporting_oracle_specs_p2p_peer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_oracle_specs
    ADD CONSTRAINT offchainreporting_oracle_specs_p2p_peer_id_fkey FOREIGN KEY (p2p_peer_id) REFERENCES public.encrypted_p2p_keys(peer_id);


--
-- Name: offchainreporting_oracle_specs offchainreporting_oracle_specs_transmitter_address_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_oracle_specs
    ADD CONSTRAINT offchainreporting_oracle_specs_transmitter_address_fkey FOREIGN KEY (transmitter_address) REFERENCES public.keys(address);


--
-- Name: offchainreporting_pending_transmissions offchainreporting_pending_tra_offchainreporting_oracle_spe_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_pending_transmissions
    ADD CONSTRAINT offchainreporting_pending_tra_offchainreporting_oracle_spe_fkey FOREIGN KEY (offchainreporting_oracle_spec_id) REFERENCES public.offchainreporting_oracle_specs(id) ON DELETE CASCADE;


--
-- Name: offchainreporting_persistent_states offchainreporting_persistent__offchainreporting_oracle_spe_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offchainreporting_persistent_states
    ADD CONSTRAINT offchainreporting_persistent__offchainreporting_oracle_spe_fkey FOREIGN KEY (offchainreporting_oracle_spec_id) REFERENCES public.offchainreporting_oracle_specs(id) ON DELETE CASCADE;


--
-- Name: p2p_peers p2p_peers_peer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.p2p_peers
    ADD CONSTRAINT p2p_peers_peer_id_fkey FOREIGN KEY (peer_id) REFERENCES public.encrypted_p2p_keys(peer_id) DEFERRABLE;


--
-- Name: pipeline_runs pipeline_runs_pipeline_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_runs
    ADD CONSTRAINT pipeline_runs_pipeline_spec_id_fkey FOREIGN KEY (pipeline_spec_id) REFERENCES public.pipeline_specs(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: pipeline_task_runs pipeline_task_runs_pipeline_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_runs
    ADD CONSTRAINT pipeline_task_runs_pipeline_run_id_fkey FOREIGN KEY (pipeline_run_id) REFERENCES public.pipeline_runs(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: pipeline_task_runs pipeline_task_runs_pipeline_task_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_runs
    ADD CONSTRAINT pipeline_task_runs_pipeline_task_spec_id_fkey FOREIGN KEY (pipeline_task_spec_id) REFERENCES public.pipeline_task_specs(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: pipeline_task_specs pipeline_task_specs_pipeline_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_specs
    ADD CONSTRAINT pipeline_task_specs_pipeline_spec_id_fkey FOREIGN KEY (pipeline_spec_id) REFERENCES public.pipeline_specs(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: pipeline_task_specs pipeline_task_specs_successor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_task_specs
    ADD CONSTRAINT pipeline_task_specs_successor_id_fkey FOREIGN KEY (successor_id) REFERENCES public.pipeline_task_specs(id) DEFERRABLE;


--
-- Name: service_agreements service_agreements_job_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_agreements
    ADD CONSTRAINT service_agreements_job_spec_id_fkey FOREIGN KEY (job_spec_id) REFERENCES public.job_specs(id) ON DELETE CASCADE;


--
-- Name: task_runs task_runs_job_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_runs
    ADD CONSTRAINT task_runs_job_run_id_fkey FOREIGN KEY (job_run_id) REFERENCES public.job_runs(id) ON DELETE CASCADE;


--
-- Name: task_specs task_specs_job_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_specs
    ADD CONSTRAINT task_specs_job_spec_id_fkey FOREIGN KEY (job_spec_id) REFERENCES public.job_specs(id) ON DELETE CASCADE;


--
-- Name: vrf_request_jobs vrf_request_jobs_vrf_request_id_vrf_requests_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_request_jobs
    ADD CONSTRAINT vrf_request_jobs_vrf_request_id_vrf_requests_id_foreign FOREIGN KEY (vrf_request_id) REFERENCES public.vrf_requests(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: vrf_request_runs vrf_request_runs_vrf_request_job_id_vrf_request_jobs_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vrf_request_runs
    ADD CONSTRAINT vrf_request_runs_vrf_request_job_id_vrf_request_jobs_id_foreign FOREIGN KEY (vrf_request_job_id) REFERENCES public.vrf_request_jobs(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

