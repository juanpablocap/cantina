--
-- PostgreSQL database dump
--

\restrict H4Ocdvgy87BV6IoHIHHduD6tEdB7YB8jEUIp75W4cgib6sDibI6dZEPz5Wkzon7

-- Dumped from database version 18.3 (Ubuntu 18.3-1)
-- Dumped by pg_dump version 18.3 (Ubuntu 18.3-1)

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
    fecha timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
1	Platos	🍽️	#E07A5F	f	1
2	Bebidas	🍺	#6C9BCF	t	2
3	Cafetería	☕	#C4956A	f	3
4	Postres	🍰	#D4A5D0	f	4
\.


--
-- Data for Name: CierreCaja; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."CierreCaja" (id, efectivo, transferencia, fiado, "totalVentas", "cantPedidos", arqueo, diferencia, fecha) FROM stdin;
\.


--
-- Data for Name: Cliente; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Cliente" (id, nombre, apellido, apodo, division, whatsapp, saldo, activo) FROM stdin;
3	Roberto	Díaz	Beto	Depósito	3814009012	0	t
2	María	López	Mari	Oficina	3814005678	8000	t
5	Miguel	Fernández	Migue	Planta	3813431572	0	t
6	Laura	Martínez	Lau	Oficina	3816970039	0	t
7	Diego	Sánchez	Dieguito	Depósito	3815471165	0	t
8	Valentina	Romero	Vale	Ventas	3818526213	0	t
9	Martín	Herrera	Tín	Planta	3818735756	0	t
10	Camila	Torres	Cami	Oficina	3815302139	0	t
11	Facundo	Álvarez	Facu	Depósito	3813392709	0	t
12	Luciana	Acosta	Lu	Ventas	3817122219	0	t
13	Nicolás	Gutiérrez	Nico	Planta	3819565520	0	t
14	Florencia	Castro	Flor	Oficina	3817033917	0	t
15	Tomás	Morales	Tomy	Depósito	3819078442	0	t
16	Sofía	Jiménez	Sofi	Ventas	3812437895	0	t
17	Joaquín	Molina	Joaco	Planta	3812984711	0	t
18	Agustina	Medina	Agus	Oficina	3819100235	0	t
19	Matías	Suárez	Mati	Depósito	3816673870	0	t
20	Julieta	Pereyra	Juli	Ventas	3816704498	0	t
21	Ezequiel	García	Eze	Planta	3816940629	0	t
22	Milagros	Ruiz	Mili	Oficina	3817390563	0	t
23	Lautaro	Flores	Lauta	Depósito	3812429245	0	t
24	Candela	Benítez	Cande	Ventas	3817579202	0	t
25	Gonzalo	Cabrera	Gonza	Planta	3813388303	0	t
26	Rocío	Aguirre	Ro	Oficina	3817066494	0	t
27	Sebastián	Navarro	Seba	Depósito	3817370469	0	t
28	Aldana	Domínguez	Alda	Ventas	3819247111	0	t
29	Franco	Ortiz	Fran	Planta	3816496048	0	t
30	Brenda	Sosa	Bre	Oficina	3813065264	0	t
31	Ramiro	Paz	Rami	Depósito	3816178731	0	t
32	Daniela	Figueroa	Dani	Ventas	3814397600	0	t
33	Leandro	Córdoba	Lean	Planta	3817042509	0	t
34	Antonella	Vega	Anto	Oficina	3813157265	0	t
36	Carolina	Ríos	Caro	Ventas	3816510021	0	t
37	Iván	Rojas	Iva	Planta	3817628756	0	t
38	Micaela	Quiroga	Mica	Oficina	3817431936	0	t
39	Santiago	Villalba	Santi	Depósito	3811273517	0	t
40	Natalia	Ramírez	Nati	Ventas	3815702594	0	t
41	Pablo	Ojeda	Pablito	Planta	3816310955	0	t
35	Maximiliano	Luna	Maxi	Depósito	3814292110	8000	t
4	JUAN	pablo	jp	m6		11000	t
1	Carlos	González	Carlitos	Planta	3814001234	13000	t
\.


--
-- Data for Name: ClientePago; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."ClientePago" (id, cliente_id, monto, fecha) FROM stdin;
\.


--
-- Data for Name: Pedido; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Pedido" (id, numero, tipo, mesa_numero, nombre_cliente, estado, cobrado, total, metodo_pago, referencia, descuento_pct, cliente_id, "createdAt") FROM stdin;
1	1	mesa	2	\N	pendiente	f	24500	\N	\N	\N	\N	2026-05-21 23:52:09.44
2	2	mesa	3	\N	entregado	f	8500	\N	\N	\N	\N	2026-05-21 23:53:11.965
3	3	mesa	3	\N	entregado	f	3500	\N	\N	\N	\N	2026-05-21 23:56:05.802
4	4	mesa	4	\N	entregado	f	9500	\N	\N	\N	\N	2026-05-21 23:58:29.519
5	5	mesa	5	\N	entregado	t	8500	efectivo	\N	\N	\N	2026-05-22 00:01:42.436
38	38	barra	\N	GG	entregado	f	2000	\N	\N	\N	\N	2026-05-22 13:39:37.463
7	7	mesa	3	\N	entregado	t	2500	efectivo	\N	\N	\N	2026-05-22 00:08:47.544
6	6	mesa	1	\N	entregado	t	7000	transferencia	\N	\N	\N	2026-05-22 00:04:56.438
19	19	mesa	2	\N	entregado	t	5000	efectivo	\N	\N	\N	2026-05-22 00:48:19.515
18	18	barra	\N	\N	entregado	t	2500	efectivo	\N	\N	\N	2026-05-22 00:39:27.064
21	21	barra	\N	\N	entregado	t	22000	efectivo	\N	\N	\N	2026-05-22 01:18:00.388
8	8	mesa	5	\N	entregado	t	9000	efectivo	\N	\N	\N	2026-05-22 00:13:11.968
10	10	barra	\N	\N	entregado	t	10500	efectivo	\N	\N	\N	2026-05-22 00:14:17.946
9	9	barra	\N	GABY	entregado	t	7500	efectivo	\N	\N	\N	2026-05-22 00:13:33.016
11	11	mesa	3	\N	entregado	t	16500	cuenta_corriente	\N	\N	1	2026-05-22 00:15:38.182
22	22	barra	\N	\N	entregado	t	3500	efectivo	\N	\N	\N	2026-05-22 01:18:03.986
23	23	barra	\N	\N	entregado	t	6500	efectivo	\N	\N	\N	2026-05-22 01:18:09.05
24	24	barra	\N	\N	entregado	t	3000	efectivo	\N	\N	\N	2026-05-22 01:18:16.386
25	25	barra	\N	\N	entregado	t	4000	efectivo	\N	\N	\N	2026-05-22 01:18:31.626
39	39	barra	\N	YYYYY	entregado	f	4500	\N	\N	\N	\N	2026-05-22 13:41:23.255
15	15	mesa	2	\N	entregado	t	6000	efectivo	\N	\N	\N	2026-05-22 00:31:21.314
40	40	barra	\N	TEST_CANCELAR	cancelado	f	100	\N	\N	\N	\N	2026-05-22 18:12:56.455
33	33	barra	\N	O	entregado	t	8000	efectivo	\N	\N	\N	2026-05-22 12:45:13.856
29	29	mesa	3	\N	entregado	t	7000	transferencia	\N	\N	\N	2026-05-22 05:01:46.953
13	13	mesa	6	\N	entregado	t	20500	efectivo	\N	\N	\N	2026-05-22 00:30:06.715
17	17	mesa	4	\N	entregado	t	3500	efectivo	\N	\N	\N	2026-05-22 00:31:30.746
16	16	mesa	3	\N	entregado	t	16500	cuenta_corriente	\N	\N	3	2026-05-22 00:31:26.681
12	12	mesa	2	\N	entregado	t	14500	cuenta_corriente	\N	\N	2	2026-05-22 00:29:47.83
14	14	mesa	2	\N	entregado	t	5000	transferencia	\N	\N	\N	2026-05-22 00:30:16.259
27	27	barra	\N	\N	entregado	t	10500	transferencia	\N	\N	2	2026-05-22 05:01:23.869
28	28	mesa	1	\N	entregado	t	8000	cuenta_corriente	\N	\N	2	2026-05-22 05:01:37.959
20	20	mesa	2	\N	entregado	t	10000	efectivo	\N	\N	\N	2026-05-22 01:05:30.691
30	30	mesa	6	\N	entregado	t	8500	cuenta_corriente	\N	\N	4	2026-05-22 12:24:17.01
31	31	barra	\N	JP	entregado	t	8000	cuenta_corriente	\N	\N	35	2026-05-22 12:32:50.408
26	26	mesa	3	\N	entregado	t	12500	efectivo	\N	\N	\N	2026-05-22 01:29:59.772
32	32	barra	\N	J	entregado	f	11000	\N	\N	\N	\N	2026-05-22 12:33:28.116
34	34	barra	\N	U	entregado	f	5500	\N	\N	\N	\N	2026-05-22 13:18:04.217
35	35	mesa	2	\N	entregado	t	23500	transferencia	2222	\N	\N	2026-05-22 13:18:54.838
37	37	barra	\N	JULI	entregado	t	2500	cuenta_corriente	\N	\N	4	2026-05-22 13:26:18.331
36	36	barra	\N	JP	entregado	t	13000	cuenta_corriente	\N	\N	1	2026-05-22 13:26:10.897
\.


--
-- Data for Name: PedidoItem; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."PedidoItem" (id, pedido_id, producto_id, cantidad, precio, observaciones) FROM stdin;
1	1	2	1	7000	\N
2	1	3	1	9500	\N
3	1	4	1	8000	\N
4	2	1	1	8500	\N
5	3	7	1	3500	\N
6	4	8	1	2000	\N
7	4	6	1	7500	Sin cebolla
8	5	1	1	8500	\N
9	6	11	1	4500	\N
10	6	10	1	2500	\N
11	7	13	1	2500	\N
12	8	8	1	2000	\N
13	8	7	1	3500	\N
14	8	16	1	3500	\N
15	9	6	1	7500	\N
16	10	14	1	3000	\N
17	10	8	1	2000	\N
18	10	5	1	5500	\N
19	11	3	1	9500	\N
20	11	2	1	7000	\N
21	12	1	1	8500	\N
22	12	13	1	2500	\N
23	12	16	1	3500	\N
24	13	11	1	4500	\N
25	13	1	1	8500	\N
26	13	6	1	7500	\N
27	14	10	1	2500	\N
28	14	13	1	2500	\N
29	15	15	1	4000	\N
30	15	12	1	2000	\N
31	16	4	1	8000	\N
32	16	1	1	8500	\N
33	17	7	1	3500	\N
34	18	17	1	2500	\N
35	19	10	1	2500	\N
36	19	13	1	2500	\N
37	20	4	1	8000	\N
38	20	8	1	2000	\N
39	21	2	1	7000	\N
40	21	3	1	9500	\N
41	21	5	1	5500	\N
42	22	16	1	3500	\N
43	23	10	1	2500	\N
44	23	15	1	4000	\N
45	24	14	1	3000	\N
46	25	12	2	2000	\N
47	26	4	1	8000	\N
48	26	11	1	4500	\N
49	27	17	1	2500	\N
50	27	5	1	5500	\N
51	27	10	1	2500	\N
52	28	4	1	8000	\N
53	29	2	1	7000	\N
54	30	1	1	8500	\N
55	31	4	1	8000	\N
56	32	10	1	2500	\N
57	32	1	1	8500	\N
58	33	4	1	8000	\N
59	34	5	1	5500	\N
60	35	11	1	4500	\N
61	35	17	1	2500	\N
62	35	5	3	5500	\N
63	36	7	1	3500	\N
64	36	2	1	7000	\N
65	36	10	1	2500	\N
66	37	13	1	2500	\N
67	38	12	1	2000	\N
68	39	11	1	4500	\N
69	40	9	1	100	\N
\.


--
-- Data for Name: Producto; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Producto" (id, nombre, precio, stock, stock_min, codigo, cocina, activo, cat_id) FROM stdin;
4	Suprema a caballo	8000	8	5	\N	t	t	1
1	Milanesa napolitanaY	8500	13	5	\N	t	t	1
17	GAS	2500	17	5	\N	f	t	2
5	Empanadas x6	5500	23	10	\N	t	t	1
7	Papas fritas	3500	26	5	\N	t	t	1
2	Hamburguesa completa	7000	15	5	\N	t	t	1
10	Cerveza Quilmes	2500	23	8	\N	t	t	2
13	Café doble	2500	94	10	\N	t	t	3
12	Café cortado	2000	95	10	\N	t	t	3
11	Fernet con Coca	4500	15	5	\N	t	t	2
9	Agua mineral	1500	50	10	\N	t	t	2
6	Pizza muzzarella	7500	7	3	\N	t	t	1
8	Coca Cola 500ml	2000	46	10	\N	t	t	2
3	Lomo completo	9500	12	3	\N	t	t	1
16	Brownie	3500	12	3	\N	t	t	4
15	Flan con dulce	4000	13	5	\N	t	t	4
14	Submarino	3000	28	5	\N	t	t	3
\.


--
-- Data for Name: Usuario; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public."Usuario" (id, nombre, rol, pin, activo, "createdAt") FROM stdin;
1	Admin	admin	0000	t	2026-05-21 23:46:37.17
2	Cajero	cajero	1234	t	2026-05-21 23:46:37.17
3	Cocina	cocina	5678	t	2026-05-21 23:46:37.17
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: cantina
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
a902fa2d-7587-46c9-b8a9-7f9f0f65cc5a	99c67fcc079126f96ad6a6a48308574c33404ddf5f6a965b95ccee7c5843c260	2026-05-21 22:44:28.49136+00	20260521224428_init	\N	\N	2026-05-21 22:44:28.444374+00	1
\.


--
-- Name: CarouselImage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."CarouselImage_id_seq"', 1, false);


--
-- Name: Categoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Categoria_id_seq"', 4, true);


--
-- Name: CierreCaja_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."CierreCaja_id_seq"', 1, false);


--
-- Name: ClientePago_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."ClientePago_id_seq"', 1, false);


--
-- Name: Cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Cliente_id_seq"', 41, true);


--
-- Name: PedidoItem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."PedidoItem_id_seq"', 69, true);


--
-- Name: Pedido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Pedido_id_seq"', 40, true);


--
-- Name: Producto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Producto_id_seq"', 17, true);


--
-- Name: Usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cantina
--

SELECT pg_catalog.setval('public."Usuario_id_seq"', 3, true);


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
-- PostgreSQL database dump complete
--

\unrestrict H4Ocdvgy87BV6IoHIHHduD6tEdB7YB8jEUIp75W4cgib6sDibI6dZEPz5Wkzon7

