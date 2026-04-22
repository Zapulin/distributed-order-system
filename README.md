# Sistema de gestió de comandes distribuït

Prototip d'un sistema de gestió de comandes basat en microserveis, implementat com a part del Treball de Fi de Grau. El sistema utilitza el patró Saga per coordinar transaccions distribuïdes entre tres serveis independents que es comuniquen a través de Kafka.

## Serveis

| Servei | Responsabilitat | Port |
|---|---|---|
| `orders-service` | API HTTP d'entrada, orquestrador de la Saga | 3000 |
| `inventory-service` | Gestió d'estoc i reserves | — |
| `payments-service` | Processament de pagaments (simulat) | — |

La infraestructura inclou un broker Kafka (amb Zookeeper) i tres bases de dades PostgreSQL independents, una per servei.

## Requisits

- [Docker](https://docs.docker.com/get-docker/) >= 24
- [Docker Compose](https://docs.docker.com/compose/) >= 2.20

## Posada en marxa

```bash
# Clonar el repositori
git clone https://github.com/Zapulin/distributed-order-system.git
cd distributed-order-system

# Arrencar tots els contenidors
docker compose up -d
```

El primer arrencament triga uns 30-60 segons. Els serveis d'aplicació esperen que Kafka i les bases de dades estiguin disponibles abans d'iniciar-se. Les migracions i les dades inicials (seeds) s'apliquen automàticament.

Per aturar i netejar l'entorn completament (les dades no persisteixen entre arrencades):

```bash
docker compose down
```

## Provar el sistema

### Flux 1 — Comanda confirmada (happy path)

```bash
curl -X POST http://localhost:3000/orders \
  -H 'Content-Type: application/json' \
  -d '{"order": {"items": [{"product_id": "PROD-001", "quantity": 2, "unit_price": 29.99}]}}'
```

Guardar l'`id` de la resposta i consultar l'estat al cap d'uns segons:

```bash
curl http://localhost:3000/orders/<id>
```

**Resultat esperat:** `"status": "CONFIRMED"`

### Flux 2 — Cancel·lació per estoc insuficient

`PROD-OUT` té 0 unitats disponibles:

```bash
curl -X POST http://localhost:3000/orders \
  -H 'Content-Type: application/json' \
  -d '{"order": {"items": [{"product_id": "PROD-OUT", "quantity": 1, "unit_price": 5.00}]}}'
```

**Resultat esperat:** `"status": "CANCELLED"`

### Flux 3 — Cancel·lació per pagament fallat

El servei de pagaments simula un 20% de fallades. Per forçar-ho, es pot enviar diverses comandes fins obtenir una fallada, o temporalment canviar `SUCCESS_RATE = 0.0` a `payments-service/app/services/process_payment.rb` i recrear el contenidor:

```bash
docker compose up -d --force-recreate payments-worker
```

**Resultat esperat:** `"status": "CANCELLED"` + el stock retorna al valor anterior.

### Flux 4 — Esgotament dinàmic d'estoc

`PROD-003` té 10 unitats. Dues comandes consecutives, la segona superant el límit:

```bash
# Primera comanda: confirma
curl -X POST http://localhost:3000/orders \
  -H 'Content-Type: application/json' \
  -d '{"order": {"items": [{"product_id": "PROD-003", "quantity": 7, "unit_price": 9.99}]}}'

# Segona comanda: cancel·la (queden 3 unitats)
curl -X POST http://localhost:3000/orders \
  -H 'Content-Type: application/json' \
  -d '{"order": {"items": [{"product_id": "PROD-003", "quantity": 7, "unit_price": 9.99}]}}'
```

## Productes de prova disponibles

| `product_id` | Estoc inicial | Propòsit |
|---|---|---|
| `PROD-001` | 100 unitats | Happy path genèric |
| `PROD-002` | 50 unitats | Happy path / pagament fallat |
| `PROD-003` | 10 unitats | Esgotament dinàmic |
| `PROD-OUT` | 0 unitats | Cancel·lació immediata per falta d'estoc |

## Inspecció i monitoratge

### Logs en temps real

```bash
# Tots els serveis d'aplicació (Recomenat)
docker compose logs -f orders-api orders-worker inventory-worker payments-worker

# Un servei concret
docker logs -f orders-api
docker logs -f orders-worker
docker logs -f inventory-worker
docker logs -f payments-worker
```

Els logs mostren cada transició de la Saga amb el format `[Saga] Order <id>: CREATED -> RESERVED`.

### Consultar les bases de dades

**Comandes (orders-service):**
```bash
docker exec -it order-db psql -U postgres -d order_db -c "SELECT id, status, total_amount, created_at FROM orders;"
```

**Estoc i reserves (inventory-service):**
```bash
# Estoc actual per producte
docker exec -it inventory-db psql -U postgres -d inventory_db -c "SELECT product_id, quantity FROM product_stocks;"

# Reserves actives
docker exec -it inventory-db psql -U postgres -d inventory_db -c "SELECT order_id, product_id, quantity, status, expires_at FROM stock_reservations;"
```

**Pagaments (payments-service):**
```bash
docker exec -it payment-db psql -U postgres -d payments_db -c "SELECT order_id, status, amount, created_at FROM payments;"
```

### Estat dels contenidors

```bash
docker compose ps
```

## Estructura del projecte

```
distributed-order-system/
├── docker-compose.yml          # Infraestructura + serveis d'aplicació
├── orders-service/             # API HTTP + orquestrador Saga
├── inventory-service/          # Gestió d'estoc
├── payments-service/           # Processament de pagaments
└── docs/                       # Documentació tècnica
```

## Documentació addicional

- [`docs/architecture.md`](docs/architecture.md) — Arquitectura del sistema
- [`docs/message-contracts.md`](docs/message-contracts.md) — Tots els missatges Kafka amb el seu format JSON
- [`docs/implementation-notes.md`](docs/implementation-notes.md) — Decisions de disseny i limitacions