;; title: bee_colony_health_monitoring
;; version: 1.0.0
;; summary: Smart contract for Bee Colony Health Monitoring

(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-UNAUTHORIZED u401)
(define-constant ERR-INVALID-DATA u400)
(define-constant ERR-ALREADY-EXISTS u409)

(define-map colonies
  { colony-id: uint }
  {
    owner: principal,
    location: (string-ascii 100),
    health-score: uint,
    population: uint,
    last-inspected: uint,
    created-at: uint
  }
)

(define-map health-records
  { colony-id: uint, record-id: uint }
  {
    temperature: uint,
    humidity: uint,
    disease-detected: bool,
    timestamp: uint,
    recorded-by: principal
  }
)

(define-data-var next-colony-id uint u0)
(define-data-var next-record-id uint u0)

(define-public (register-colony (location (string-ascii 100)))
  (let
    (
      (colony-id (var-get next-colony-id))
    )
    (if (> (len location) u0)
      (begin
        (map-set colonies
          { colony-id: colony-id }
          {
            owner: tx-sender,
            location: location,
            health-score: u100,
            population: u0,
            last-inspected: burn-block-height,
            created-at: burn-block-height
          }
        )
        (var-set next-colony-id (+ colony-id u1))
        (ok colony-id)
      )
      (err ERR-INVALID-DATA)
    )
  )
)

(define-public (record-health-check (colony-id uint) (temperature uint) (humidity uint) (disease bool))
  (let
    (
      (colony (map-get? colonies { colony-id: colony-id }))
      (record-id (var-get next-record-id))
    )
    (match colony
      colony-data
      (if (is-eq (get owner colony-data) tx-sender)
        (begin
          (map-set health-records
            { colony-id: colony-id, record-id: record-id }
            {
              temperature: temperature,
              humidity: humidity,
              disease-detected: disease,
              timestamp: burn-block-height,
              recorded-by: tx-sender
            }
          )
          (map-set colonies
            { colony-id: colony-id }
            (merge colony-data { last-inspected: burn-block-height })
          )
          (var-set next-record-id (+ record-id u1))
          (ok record-id)
        )
        (err ERR-UNAUTHORIZED)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (update-colony-population (colony-id uint) (new-population uint))
  (let
    (
      (colony (map-get? colonies { colony-id: colony-id }))
    )
    (match colony
      colony-data
      (if (is-eq (get owner colony-data) tx-sender)
        (begin
          (map-set colonies
            { colony-id: colony-id }
            (merge colony-data { population: new-population })
          )
          (ok true)
        )
        (err ERR-UNAUTHORIZED)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (update-health-score (colony-id uint) (score uint))
  (let
    (
      (colony (map-get? colonies { colony-id: colony-id }))
    )
    (match colony
      colony-data
      (if (and (is-eq (get owner colony-data) tx-sender) (<= score u100))
        (begin
          (map-set colonies
            { colony-id: colony-id }
            (merge colony-data { health-score: score })
          )
          (ok true)
        )
        (err ERR-UNAUTHORIZED)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-read-only (get-colony-info (colony-id uint))
  (map-get? colonies { colony-id: colony-id })
)

(define-read-only (get-health-record (colony-id uint) (record-id uint))
  (map-get? health-records { colony-id: colony-id, record-id: record-id })
)

(define-read-only (get-colony-health-status (colony-id uint))
  (let
    (
      (colony (map-get? colonies { colony-id: colony-id }))
    )
    (match colony
      colony-data
      (ok (get health-score colony-data))
      (err ERR-NOT-FOUND)
    )
  )
)
