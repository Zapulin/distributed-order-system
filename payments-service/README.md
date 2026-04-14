# payments-service

Servei encarregat del processament de pagaments. Respon a comandes de l'orders-service a través de Kafka. Els pagaments estan simulats per al prototip.

## Responsabilitats

- Processar la sol·licitud de pagament d'una comanda
- Publicar el resultat (`PaymentSucceeded` o `PaymentFailed`)
- Garantir idempotència: un pagament per `order_id` és únic

## Models

- **Payment** — Registre d'un pagament amb estats: `pending`, `succeeded`, `failed`

## Simulació

El servei simula un 80% de pagaments exitosos (`SUCCESS_RATE = 0.8` a `app/services/process_payment.rb`). Per forçar fallades en proves, es pot canviar temporalment a `0.0`.

## Tòpics Kafka

**Consumeix:**
- `process-payment-requested`

**Publica:**
- `payment-succeeded`
- `payment-failed`

## Tecnologies

- Ruby 3.4.8 / Rails 8.1 (API mode)
- PostgreSQL 16
- Karafka 2.5 (client Kafka)
