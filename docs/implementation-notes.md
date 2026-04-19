# Notes d'implementació

Detalls tècnics de la implementació de cada servei. Per a la visió general, els fluxos de la Saga i les decisions de disseny, vegeu [`architecture.md`](architecture.md).

---

## Orders Service

**Classes principals:**
- `CreateOrder` — valida els ítems, calcula el `total_amount` i persisteix l'ordre i els seus ítems en una sola transacció; publica `ReserveStockRequested`
- `SagaOrchestrator` — rep cada esdeveniment i aplica la transició d'estat corresponent; comprova l'estat actual abans de transicionar per evitar processament duplicat
- `InventoryEventsConsumer`, `PaymentEventsConsumer` — consumidors Kafka que deleguen a `SagaOrchestrator`

**Simplificacions:**
- El `total_amount` es calcula al service d'aplicació a partir dels preus enviats pel client, sense validació de preus al servidor.
- No s'aplica CQRS; el mateix model serveix per a escriptura i lectura.

---

## Inventory Service

**Classes principals:**
- `ReserveStock` — obre una transacció, bloqueja la fila de `ProductStock` amb `FOR UPDATE`, comprova l'estoc disponible i crea la `StockReservation`; comprova idempotència per `order_id` abans d'executar
- `ReleaseReservation` — restaura la quantitat a `ProductStock` i marca la reserva com `released`
- `expire_reservations` (rake task) — detecta reserves `pending` amb `expires_at` passat, restaura l'estoc i publica `ReservationExpired`

**Simplificacions:**
- L'expiració de reserves requereix execució manual o via cron extern; no hi ha cap mecanisme automàtic.
- No es valida l'existència del `product_id` abans de fer la reserva; si no existeix, falla amb una excepció.

---

## Payments Service

**Classes principals:**
- `ProcessPayment` — comprova idempotència per `order_id`; si ja existeix un `Payment`, re-publica el resultat sense re-processar; si no, crea el `Payment` i simula el resultat amb `rand < SUCCESS_RATE`

**Simplificacions:**
- Simulació probabilística amb 80% d'èxit (`SUCCESS_RATE = 0.8`). Per forçar fallades en proves, canviar temporalment a `0.0` i recrcar el contenidor.
- No hi ha integració amb cap passarel·la de pagament real.
- No s'implementen reintents en cas d'error tècnic.

---

## Kafka i missatgeria

**Configuració rellevant:**
- Client: Karafka 2.5 amb WaterDrop per la publicació síncrona (`produce_sync`)
- `initial_offset: earliest` a tots els consumidors — necessari per no perdre missatges en tòpics nous quan el consumidor s'inicia després de la publicació
- `order_id` com a clau de partició — garanteix l'ordre dels missatges per a una mateixa comanda

**Problema trobat durant el desenvolupament:**
Amb `initial_offset: latest` (valor per defecte), els consumidors ignoraven tots els missatges publicats abans del seu arrencada. En un entorn de prototip on els serveis no sempre arrenquen en ordre, això provocava que les comandes quedessin encallades en `CREATED`. Canviar a `earliest` va resoldre el problema, tot i que en producció caldria una estratègia més acurada de gestió d'offsets.
