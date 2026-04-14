# inventory-service

Servei encarregat de la gestió de l'estoc i les reserves de productes. Respon a comandes de l'orders-service a través de Kafka, sense exposar cap API HTTP.

## Responsabilitats

- Reservar estoc per a una comanda (amb bloqueig a nivell de fila per evitar condicions de carrera)
- Alliberar reserves quan una comanda és cancel·lada
- Gestionar l'expiració de reserves no resoltes
- Garantir idempotència: una reserva per `order_id` és única

## Models

- **ProductStock** — Estoc disponible per producte (`product_id`, `quantity`)
- **StockReservation** — Reserva associada a una comanda, amb temps d'expiració de 15 minuts. Estats: `pending`, `released`, `expired`

## Dades inicials (seeds)

| `product_id` | Quantitat |
|---|---|
| PROD-001 | 100 |
| PROD-002 | 50 |
| PROD-003 | 10 |
| PROD-OUT | 0 |

## Tòpics Kafka

**Consumeix:**
- `reserve-stock-requested`
- `release-reservation-requested`

**Publica:**
- `stock-reserved`
- `stock-reservation-failed`
- `reservation-released`
- `reservation-expired`

## Tasques de manteniment

Expiració manual de reserves (per executar periòdicament via cron):

```bash
bundle exec rake reservations:expire
```

## Tecnologies

- Ruby 3.4.8 / Rails 8.1 (API mode)
- PostgreSQL 16
- Karafka 2.5 (client Kafka)
