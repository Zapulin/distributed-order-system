# Arquitectura del sistema

## Visió general

El sistema implementa la gestió de comandes en un entorn de microserveis. Cada servei té una responsabilitat única, la seva pròpia base de dades i es comunica amb els altres exclusivament a través de missatges Kafka. No hi ha cap crida HTTP directa entre serveis.

L'objectiu principal és il·lustrar com es pot mantenir la consistència de dades en un sistema distribuït sense fer ús de transaccions distribuïdes (2PC), substituint-les pel patró Saga.

---

## Serveis

### orders-service

Punt d'entrada del sistema. Exposa una API REST per crear i consultar comandes, i actua com a **orquestrador de la Saga**: reacciona als esdeveniments dels altres serveis i decideix el següent pas del flux.

- Conté els models `Order` i `OrderItem`
- Els estats possibles d'una comanda són: `CREATED → RESERVED → CONFIRMED` (happy path) o `CANCELLED` (qualsevol error)
- Publica comandes cap a inventory-service i payments-service
- Consumeix els resultats i aplica les transicions d'estat

### inventory-service

Gestiona l'estoc de productes i les reserves. No exposa cap API externa; tot el seu comportament és reactiu als missatges que rep.

- Conté els models `ProductStock` i `StockReservation`
- Les reserves tenen un temps d'expiració de 15 minuts
- Utilitza `SELECT FOR UPDATE` per evitar condicions de carrera en entorns concurrents
- Garanteix idempotència: si rep dos cops la mateixa sol·licitud de reserva (mateix `order_id`), no reserva el stock dues vegades

### payments-service

Processa pagaments de forma simulada. Com inventory-service, és completament reactiu.

- Conté el model `Payment`
- Simula un 80% de pagaments exitosos
- Garanteix idempotència: si rep dues vegades la sol·licitud per al mateix `order_id`, retorna el resultat ja calculat sense tornar a processar

---

## Infraestructura

El sistema s'executa completament sobre Docker. Tots els contenidors pertanyen a la mateixa xarxa interna i es comuniquen per nom de servei, sense exposar ports innecessaris a l'exterior.

**Contenidors d'aplicació:**
- `orders-api` — servidor HTTP Puma, escolta al port 3000 (únic punt d'entrada extern)
- `orders-worker` — consumidor Kafka de l'orders-service; comparteix imatge amb `orders-api` però amb una comanda d'arrencada diferent
- `inventory-worker` — consumidor Kafka de l'inventory-service
- `payments-worker` — consumidor Kafka del payments-service

**Infraestructura de suport:**
- `kafka` + `zookeeper` — broker de missatgeria (Confluent 7.4)
- `order-db`, `inventory-db`, `payment-db` — tres instàncies PostgreSQL 16 independents, una per servei

Cada servei d'aplicació accedeix únicament a la seva pròpia base de dades. No comparteixen ni esquema ni connexions, seguint el principi de *database per service*.

**Tòpics Kafka del sistema:**

| Tòpic | Publicat per | Consumit per |
|---|---|---|
| `reserve-stock-requested` | orders-service | inventory-service |
| `stock-reserved` | inventory-service | orders-service |
| `stock-reservation-failed` | inventory-service | orders-service |
| `process-payment-requested` | orders-service | payments-service |
| `payment-succeeded` | payments-service | orders-service |
| `payment-failed` | payments-service | orders-service |
| `release-reservation-requested` | orders-service | inventory-service |
| `reservation-released` | inventory-service | orders-service |
| `reservation-expired` | inventory-service | orders-service |
| `order-confirmed` | orders-service | — |
| `order-cancelled` | orders-service | — |

Els tòpics `order-confirmed` i `order-cancelled` es publiquen per completesa del flux però no tenen consumidors implementats en aquest prototip. En un sistema real serien consumits per altres serveis (notificacions, analítica, etc.).

---

## Patró Saga (orquestrada)

El problema central del sistema és que crear una comanda implica operacions en tres serveis independents: reservar estoc, processar el pagament i confirmar la comanda. Si una d'aquestes operacions falla, cal desfer les anteriors.

En un sistema monolític, això es resoldria amb una transacció de base de dades. En un sistema distribuït, no és possible fer una transacció que abasti múltiples bases de dades de forma fiable sense pagar un cost molt elevat en disponibilitat (teorema CAP).

La Saga substitueix la transacció distribuïda per una seqüència de transaccions locals coordinades per missatges, incloent **accions compensatòries** per desfer els passos anteriors en cas d'error.

### Flux happy path

```
Client
  │
  ▼
POST /orders ──► [orders-service] crea Order (CREATED)
                      │
                      ▼
              reserve-stock-requested
                      │
                      ▼
              [inventory-service] reserva estoc
                      │
                      ▼
                stock-reserved
                      │
                      ▼
              [orders-service] Order → RESERVED
                      │
                      ▼
              process-payment-requested
                      │
                      ▼
              [payments-service] processa pagament
                      │
                      ▼
               payment-succeeded
                      │
                      ▼
              [orders-service] Order → CONFIRMED
```

### Flux de cancel·lació per estoc insuficient

```
[inventory-service] no hi ha estoc
        │
        ▼
stock-reservation-failed
        │
        ▼
[orders-service] Order → CANCELLED
```

### Flux de cancel·lació per pagament fallat (amb compensació)

```
[payments-service] pagament rebutjat
        │
        ▼
  payment-failed
        │
        ▼
[orders-service] Order → CANCELLED
        │
        ├──► order-cancelled
        │
        └──► release-reservation-requested
                    │
                    ▼
        [inventory-service] restaura l'estoc
                    │
                    ▼
           reservation-released
```

En aquest flux, l'alliberament de la reserva és l'**acció compensatòria**: desfà la reserva d'estoc que s'havia fet correctament en el pas anterior.

---

## Decisions de disseny

**Saga orquestrada vs. coreografiada**

S'ha escollit una Saga orquestrada perquè centralitza la lògica de coordinació a l'orders-service, facilitant la traçabilitat del flux. En una Saga coreografiada, cada servei reacciona als esdeveniments dels altres i decideix el seu propi pas següent, cosa que augmenta el desacoblament però distribueix la lògica i dificulta el seguiment del flux global.

**Idempotència als consumidors**

Kafka pot lliurar el mateix missatge més d'una vegada en determinades circumstàncies (reinicis, rebalanceig de particions). Per aquest motiu, tant `ReserveStock` com `ProcessPayment` comproven si ja existeix un registre per a l'`order_id` abans d'executar l'operació.

**`SELECT FOR UPDATE` a inventory-service**

Quan dos missatges de reserva arriben simultàniament per al mateix producte, sense un mecanisme de control podrien llegir el mateix valor d'estoc i reservar més unitats de les disponibles. El bloqueig a nivell de fila garanteix que les lectures i escriptures sobre `ProductStock` es fan de forma serialitzada dins d'una transacció.

**UUID com a clau primària**

Es fan servir UUIDs en lloc d'IDs seqüencials per evitar col·lisions en un entorn distribuït i per no revelar informació sobre el volum de comandes a través de la URL.

---

## Limitacions del prototip

- El servei de pagaments és una simulació probabilística, no una integració real.
- L'expiració de reserves requereix un procés extern (rake task) en lloc d'un mecanisme automàtic.
- No s'implementen reintents automàtics ni circuit breakers.
- La configuració (credencials, URLs) es gestiona amb variables d'entorn sense un sistema de secrets centralitzat.
- El sistema no està preparat per a un entorn de producció: no hi ha TLS, monitoratge ni alta disponibilitat a Kafka.
