# Contractes de missatges Kafka

Tots els missatges s'envien en format JSON. Cada missatge inclou sempre els camps `event_type` i `timestamp` (ISO 8601), a més dels camps específics de l'esdeveniment. La clau de partició és sempre l'`order_id`, cosa que garanteix l'ordre dels missatges per a una mateixa comanda.

---

## Comandes publicades per orders-service

### `reserve-stock-requested`
Sol·licita la reserva d'estoc a inventory-service per iniciar la Saga.

```json
{
  "event_type": "ReserveStockRequested",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "items": [
    { "product_id": "PROD-001", "quantity": 2 }
  ],
  "timestamp": "2026-04-13T10:00:00Z"
}
```

### `process-payment-requested`
Sol·licita el processament del pagament a payments-service un cop l'estoc ha estat reservat.

```json
{
  "event_type": "ProcessPaymentRequested",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "amount": 59.98,
  "timestamp": "2026-04-13T10:00:01Z"
}
```

### `release-reservation-requested`
Sol·licita l'alliberament de la reserva d'estoc quan el pagament falla (acció compensatòria).

```json
{
  "event_type": "ReleaseReservationRequested",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-13T10:00:03Z"
}
```

### `order-confirmed`
Notifica que la comanda ha estat confirmada completament.

```json
{
  "event_type": "OrderConfirmed",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-13T10:00:02Z"
}
```

### `order-cancelled`
Notifica que la comanda ha estat cancel·lada.

```json
{
  "event_type": "OrderCancelled",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-13T10:00:03Z"
}
```

---

## Esdeveniments publicats per inventory-service

### `stock-reserved`
Confirma que l'estoc ha estat reservat correctament.

```json
{
  "event_type": "StockReserved",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-13T10:00:01Z"
}
```

### `stock-reservation-failed`
Informa que no s'ha pogut reservar l'estoc (estoc insuficient).

```json
{
  "event_type": "StockReservationFailed",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "reason": "Not enough stock for PROD-OUT (requested: 1, available: 0)",
  "timestamp": "2026-04-13T10:00:01Z"
}
```

### `reservation-released`
Confirma que la reserva ha estat alliberada i l'estoc restaurat.

```json
{
  "event_type": "ReservationReleased",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-13T10:00:04Z"
}
```

### `reservation-expired`
Informa que una reserva ha expirat sense ser resolta (publicat pel rake task).

```json
{
  "event_type": "ReservationExpired",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-13T10:15:00Z"
}
```

---

## Esdeveniments publicats per payments-service

### `payment-succeeded`
Confirma que el pagament s'ha processat correctament.

```json
{
  "event_type": "PaymentSucceeded",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "amount": 59.98,
  "timestamp": "2026-04-13T10:00:02Z"
}
```

### `payment-failed`
Informa que el pagament ha fallat.

```json
{
  "event_type": "PaymentFailed",
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-13T10:00:02Z"
}
```

---

## Resum de tòpics i flux

```
orders-service
  └─► reserve-stock-requested ──► inventory-service
                                       ├─► stock-reserved ──► orders-service
                                       │       └─► process-payment-requested ──► payments-service
                                       │                   ├─► payment-succeeded ──► orders-service (CONFIRMED)
                                       │                   └─► payment-failed ──► orders-service
                                       │                           └─► release-reservation-requested ──► inventory-service (CANCELLED)
                                       └─► stock-reservation-failed ──► orders-service (CANCELLED)
```
