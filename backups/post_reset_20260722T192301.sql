--
-- PostgreSQL database dump
--

\restrict rlwHmESw9Y9I7dKe1gvjRoVhmH5XZGBfkc478oxAdz3lkocJoXKPuKb5AkBXjJM

-- Dumped from database version 18.4 (Ubuntu 18.4-0ubuntu0.26.04.1)
-- Dumped by pg_dump version 18.4 (Ubuntu 18.4-0ubuntu0.26.04.1)

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: cantina
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO cantina;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: cantina
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: CarouselImage; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."CarouselImage" (
    id integer NOT NULL,
    filename text NOT NULL,
    orden integer DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."CarouselImage" OWNER TO cantina;

--
-- Name: CarouselImage_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."CarouselImage_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CarouselImage_id_seq" OWNER TO cantina;

--
-- Name: CarouselImage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."CarouselImage_id_seq" OWNED BY public."CarouselImage".id;


--
-- Name: Categoria; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."Categoria" (
    id integer NOT NULL,
    nombre text NOT NULL,
    emoji text,
    color text,
    despacho_directo boolean DEFAULT false NOT NULL,
    orden integer DEFAULT 0 NOT NULL
);


ALTER TABLE public."Categoria" OWNER TO cantina;

--
-- Name: Categoria_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."Categoria_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Categoria_id_seq" OWNER TO cantina;

--
-- Name: Categoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."Categoria_id_seq" OWNED BY public."Categoria".id;


--
-- Name: CierreCaja; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."CierreCaja" (
    id integer NOT NULL,
    efectivo double precision NOT NULL,
    transferencia double precision NOT NULL,
    fiado double precision NOT NULL,
    "totalVentas" double precision NOT NULL,
    "cantPedidos" integer NOT NULL,
    arqueo double precision,
    diferencia double precision,
    fecha timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    details jsonb
);


ALTER TABLE public."CierreCaja" OWNER TO cantina;

--
-- Name: CierreCaja_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."CierreCaja_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CierreCaja_id_seq" OWNER TO cantina;

--
-- Name: CierreCaja_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."CierreCaja_id_seq" OWNED BY public."CierreCaja".id;


--
-- Name: Cliente; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."Cliente" (
    id integer NOT NULL,
    nombre text NOT NULL,
    apellido text,
    apodo text,
    division text,
    whatsapp text,
    saldo double precision DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public."Cliente" OWNER TO cantina;

--
-- Name: ClientePago; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."ClientePago" (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    monto double precision NOT NULL,
    fecha timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."ClientePago" OWNER TO cantina;

--
-- Name: ClientePago_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."ClientePago_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ClientePago_id_seq" OWNER TO cantina;

--
-- Name: ClientePago_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."ClientePago_id_seq" OWNED BY public."ClientePago".id;


--
-- Name: Cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."Cliente_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Cliente_id_seq" OWNER TO cantina;

--
-- Name: Cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."Cliente_id_seq" OWNED BY public."Cliente".id;


--
-- Name: Pedido; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."Pedido" (
    id integer NOT NULL,
    numero integer NOT NULL,
    tipo text NOT NULL,
    mesa_numero integer,
    nombre_cliente text,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    cobrado boolean DEFAULT false NOT NULL,
    total double precision NOT NULL,
    metodo_pago text,
    referencia text,
    descuento_pct double precision,
    cliente_id integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    mesa_liberada boolean DEFAULT false NOT NULL
);


ALTER TABLE public."Pedido" OWNER TO cantina;

--
-- Name: PedidoItem; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."PedidoItem" (
    id integer NOT NULL,
    pedido_id integer NOT NULL,
    producto_id integer NOT NULL,
    cantidad integer NOT NULL,
    precio double precision NOT NULL,
    observaciones text
);


ALTER TABLE public."PedidoItem" OWNER TO cantina;

--
-- Name: PedidoItem_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."PedidoItem_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PedidoItem_id_seq" OWNER TO cantina;

--
-- Name: PedidoItem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."PedidoItem_id_seq" OWNED BY public."PedidoItem".id;


--
-- Name: Pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."Pedido_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Pedido_id_seq" OWNER TO cantina;

--
-- Name: Pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."Pedido_id_seq" OWNED BY public."Pedido".id;


--
-- Name: Producto; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."Producto" (
    id integer NOT NULL,
    nombre text NOT NULL,
    precio double precision NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    stock_min integer DEFAULT 5 NOT NULL,
    codigo text,
    cocina boolean DEFAULT true NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    cat_id integer NOT NULL
);


ALTER TABLE public."Producto" OWNER TO cantina;

--
-- Name: Producto_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."Producto_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Producto_id_seq" OWNER TO cantina;

--
-- Name: Producto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."Producto_id_seq" OWNED BY public."Producto".id;


--
-- Name: Usuario; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public."Usuario" (
    id integer NOT NULL,
    nombre text NOT NULL,
    rol text NOT NULL,
    pin text NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."Usuario" OWNER TO cantina;

--
-- Name: Usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: cantina
--

CREATE SEQUENCE public."Usuario_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Usuario_id_seq" OWNER TO cantina;

--
-- Name: Usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cantina
--

ALTER SEQUENCE public."Usuario_id_seq" OWNED BY public."Usuario".id;


--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: cantina
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public._prisma_migrations OWNER TO cantina;

--
-- Name: CarouselImage id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."CarouselImage" ALTER COLUMN id SET DEFAULT nextval('public."CarouselImage_id_seq"'::regclass);


--
-- Name: Categoria id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Categoria" ALTER COLUMN id SET DEFAULT nextval('public."Categoria_id_seq"'::regclass);


--
-- Name: CierreCaja id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."CierreCaja" ALTER COLUMN id SET DEFAULT nextval('public."CierreCaja_id_seq"'::regclass);


--
-- Name: Cliente id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Cliente" ALTER COLUMN id SET DEFAULT nextval('public."Cliente_id_seq"'::regclass);


--
-- Name: ClientePago id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."ClientePago" ALTER COLUMN id SET DEFAULT nextval('public."ClientePago_id_seq"'::regclass);


--
-- Name: Pedido id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Pedido" ALTER COLUMN id SET DEFAULT nextval('public."Pedido_id_seq"'::regclass);


--
-- Name: PedidoItem id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."PedidoItem" ALTER COLUMN id SET DEFAULT nextval('public."PedidoItem_id_seq"'::regclass);


--
-- Name: Producto id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Producto" ALTER COLUMN id SET DEFAULT nextval('public."Producto_id_seq"'::regclass);


--
-- Name: Usuario id; Type: DEFAULT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Usuario" ALTER COLUMN id SET DEFAULT nextval('public."Usuario_id_seq"'::regclass);


--
-- Data for Name: CarouselImage; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."CarouselImage" (id, filename, orden, activo, "createdAt") FROM stdin;
\.


--
-- Data for Name: Categoria; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Categoria" (id, nombre, emoji, color, despacho_directo, orden) FROM stdin;
\.


--
-- Data for Name: CierreCaja; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."CierreCaja" (id, efectivo, transferencia, fiado, "totalVentas", "cantPedidos", arqueo, diferencia, fecha, details) FROM stdin;
\.


--
-- Data for Name: Cliente; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Cliente" (id, nombre, apellido, apodo, division, whatsapp, saldo, activo) FROM stdin;
\.


--
-- Data for Name: ClientePago; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."ClientePago" (id, cliente_id, monto, fecha) FROM stdin;
\.


--
-- Data for Name: Pedido; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Pedido" (id, numero, tipo, mesa_numero, nombre_cliente, estado, cobrado, total, metodo_pago, referencia, descuento_pct, cliente_id, "createdAt", mesa_liberada) FROM stdin;
\.


--
-- Data for Name: PedidoItem; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."PedidoItem" (id, pedido_id, producto_id, cantidad, precio, observaciones) FROM stdin;
\.


--
-- Data for Name: Producto; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Producto" (id, nombre, precio, stock, stock_min, codigo, cocina, activo, cat_id) FROM stdin;
\.


--
-- Data for Name: Usuario; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Usuario" (id, nombre, rol, pin, activo, "createdAt") FROM stdin;
1	Admin	admin	0000	t	2026-05-21 23:46:37.17
2	Cajero	cajero	1234	t	2026-05-21 23:46:37.17
3	Cocina	cocina	5678	t	2026-05-21 23:46:37.17
4	Mozo A	mozo	1111	t	2026-07-22 17:55:55.994
5	Mozo B	mozo	2222	t	2026-07-22 17:55:55.994
6	Mozo C	mozo	3333	t	2026-07-22 17:55:55.994
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
a902fa2d-7587-46c9-b8a9-7f9f0f65cc5a	99c67fcc079126f96ad6a6a48308574c33404ddf5f6a965b95ccee7c5843c260	2026-05-21 22:44:28.49136+00	20260521224428_init	\N	\N	2026-05-21 22:44:28.444374+00	1
b41aa190-6e30-45fe-8f64-19cfa648a73c	558fb26dcfd0d5f9d08c604ff196ff12e85217331448ac1a6344a77111f82b10	2026-05-22 19:25:42.928804+00	20260522192542_add_fk_indexes	\N	\N	2026-05-22 19:25:42.912299+00	1
\.


--
-- Name: CarouselImage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."CarouselImage_id_seq"', 12, true);


--
-- Name: Categoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Categoria_id_seq"', 5, true);


--
-- Name: CierreCaja_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."CierreCaja_id_seq"', 9, true);


--
-- Name: ClientePago_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."ClientePago_id_seq"', 5, true);


--
-- Name: Cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Cliente_id_seq"', 46, true);


--
-- Name: PedidoItem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."PedidoItem_id_seq"', 509, true);


--
-- Name: Pedido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Pedido_id_seq"', 288, true);


--
-- Name: Producto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Producto_id_seq"', 18, true);


--
-- Name: Usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Usuario_id_seq"', 6, true);


--
-- Name: CarouselImage CarouselImage_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."CarouselImage"
    ADD CONSTRAINT "CarouselImage_pkey" PRIMARY KEY (id);


--
-- Name: Categoria Categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Categoria"
    ADD CONSTRAINT "Categoria_pkey" PRIMARY KEY (id);


--
-- Name: CierreCaja CierreCaja_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."CierreCaja"
    ADD CONSTRAINT "CierreCaja_pkey" PRIMARY KEY (id);


--
-- Name: ClientePago ClientePago_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."ClientePago"
    ADD CONSTRAINT "ClientePago_pkey" PRIMARY KEY (id);


--
-- Name: Cliente Cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Cliente"
    ADD CONSTRAINT "Cliente_pkey" PRIMARY KEY (id);


--
-- Name: PedidoItem PedidoItem_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."PedidoItem"
    ADD CONSTRAINT "PedidoItem_pkey" PRIMARY KEY (id);


--
-- Name: Pedido Pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Pedido"
    ADD CONSTRAINT "Pedido_pkey" PRIMARY KEY (id);


--
-- Name: Producto Producto_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Producto"
    ADD CONSTRAINT "Producto_pkey" PRIMARY KEY (id);


--
-- Name: Usuario Usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Usuario"
    ADD CONSTRAINT "Usuario_pkey" PRIMARY KEY (id);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: ClientePago_cliente_id_idx; Type: INDEX; Schema: public; Owner: cantina
--

CREATE INDEX "ClientePago_cliente_id_idx" ON public."ClientePago" USING btree (cliente_id);


--
-- Name: PedidoItem_pedido_id_idx; Type: INDEX; Schema: public; Owner: cantina
--

CREATE INDEX "PedidoItem_pedido_id_idx" ON public."PedidoItem" USING btree (pedido_id);


--
-- Name: PedidoItem_producto_id_idx; Type: INDEX; Schema: public; Owner: cantina
--

CREATE INDEX "PedidoItem_producto_id_idx" ON public."PedidoItem" USING btree (producto_id);


--
-- Name: Pedido_cliente_id_idx; Type: INDEX; Schema: public; Owner: cantina
--

CREATE INDEX "Pedido_cliente_id_idx" ON public."Pedido" USING btree (cliente_id);


--
-- Name: Pedido_createdAt_idx; Type: INDEX; Schema: public; Owner: cantina
--

CREATE INDEX "Pedido_createdAt_idx" ON public."Pedido" USING btree ("createdAt");


--
-- Name: Producto_cat_id_idx; Type: INDEX; Schema: public; Owner: cantina
--

CREATE INDEX "Producto_cat_id_idx" ON public."Producto" USING btree (cat_id);


--
-- Name: Producto_codigo_key; Type: INDEX; Schema: public; Owner: cantina
--

CREATE UNIQUE INDEX "Producto_codigo_key" ON public."Producto" USING btree (codigo);


--
-- Name: Usuario_pin_key; Type: INDEX; Schema: public; Owner: cantina
--

CREATE UNIQUE INDEX "Usuario_pin_key" ON public."Usuario" USING btree (pin);


--
-- Name: ClientePago ClientePago_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."ClientePago"
    ADD CONSTRAINT "ClientePago_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES public."Cliente"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PedidoItem PedidoItem_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."PedidoItem"
    ADD CONSTRAINT "PedidoItem_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES public."Pedido"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PedidoItem PedidoItem_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."PedidoItem"
    ADD CONSTRAINT "PedidoItem_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES public."Producto"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Pedido Pedido_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Pedido"
    ADD CONSTRAINT "Pedido_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES public."Cliente"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Producto Producto_cat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cantina
--

ALTER TABLE ONLY public."Producto"
    ADD CONSTRAINT "Producto_cat_id_fkey" FOREIGN KEY (cat_id) REFERENCES public."Categoria"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: cantina
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict rlwHmESw9Y9I7dKe1gvjRoVhmH5XZGBfkc478oxAdz3lkocJoXKPuKb5AkBXjJM

