# orders-service

Servei central del sistema. Exposa l'API HTTP per crear i consultar comandes, i actua com a orquestrador de la Saga coordinant els altres serveis a través de Kafka.

## Responsabilitats

- Rebre peticions HTTP de creació de comandes
- Iniciar el flux de la Saga publicant `ReserveStockRequested`
- Gestionar totes les transicions d'estat de la comanda en funció dels esdeveniments rebuts
- Publicar comandes de compensació quan cal (`ReleaseReservationRequested`)

## Models

- **Order** — Comanda amb estats: `CREATED`, `RESERVED`, `CONFIRMED`, `CANCELLED`
- **OrderItem** — Línia de comanda (producte, quantitat, preu unitari)

## API

| Mètode | Ruta | Descripció |
|---|---|---|
| `POST` | `/orders` | Crear una nova comanda |
| `GET` | `/orders/:id` | Consultar l'estat d'una comanda |

**Exemple de creació:**
```json
POST /orders
{
  "order": {
    "items": [
      { "product_id": "PROD-001", "quantity": 2, "unit_price": 29.99 }
    ]
  }
}
```

## Tòpics Kafka

**Publica:**
- `reserve-stock-requested`
- `process-payment-requested`
- `release-reservation-requested`
- `order-confirmed`
- `order-cancelled`

**Consumeix:**
- `stock-reserved`, `stock-reservation-failed`, `reservation-released`, `reservation-expired`
- `payment-succeeded`, `payment-failed`

## Tecnologies

- Ruby 3.4.8 / Rails 8.1 (API mode)
- PostgreSQL 16
- Karafka 2.5 (client Kafka)
