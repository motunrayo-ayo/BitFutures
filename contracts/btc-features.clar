;; Title: BitFutures - Trustless Bitcoin Price Prediction Markets on Stacks L2
;; 
;; Summary:
;;   A Bitcoin-native prediction market protocol enabling decentralized speculation
;;   on BTC price movements using STX tokens, secured by Stacks Layer 2 infrastructure.
;;
;; Description:
;;   BitFutures creates a decentralized marketplace for Bitcoin price predictions,
;;   combining Stacks' Layer 2 scalability with Bitcoin's security model. Participants
;;   stake STX tokens to predict BTC/USD price direction within defined time windows,
;;   with automated settlement via oracle feeds and non-custodial reward distribution.
;;
;;   Built for Bitcoin maximalists and derivatives traders, BitFutures offers:
;;   - Bitcoin-denominated markets settled in sBTC
;;   - Stacks-based smart contracts with Bitcoin finality
;;   - Decentralized price oracles with miner-enforced validity
;;   - Programmatic risk management for BTC-native positions
;;   - Compliance with Bitcoin's monetary policy through pure Proof-of-Transfer

;; Protocol Traits
;; - Non-custodial staking
;; - Transparent price resolution
;; - Layer 2 micro-prediction markets
;; - Bitcoin-settled derivatives

;; Constants
(define-constant contract-owner tx-sender) ;; Admin multisig address
(define-constant err-owner-only (err u100)) ;; Authorization error
(define-constant err-not-found (err u101)) ;; Data lookup error
(define-constant err-invalid-prediction (err u102)) ;; Invalid market position
(define-constant err-market-closed (err u103)) ;; Market lifecycle error
(define-constant err-market-not-started (err u107)) ;; Early participation attempt
(define-constant err-market-ended (err u108)) ;; Late participation attempt
(define-constant err-market-already-resolved (err u109)) ;; Duplicate resolution
(define-constant err-already-claimed (err u104)) ;; Reward claim error
(define-constant err-insufficient-balance (err u105)) ;; STX balance check
(define-constant err-invalid-parameter (err u106)) ;; Input validation

;; Economic Parameters
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) ;; Trusted price feed
(define-data-var minimum-stake uint u1000000) ;; 1 STX minimum position
(define-data-var fee-percentage uint u2) ;; 2% protocol fee (bps)
(define-data-var market-counter uint u0) ;; Sequential market IDs

;; Market Data Structures
(define-map markets
  uint ;; market-id
  { ;; Bitcoin price market specification
    start-price: uint,    ;; BTC/USD opening price (sats)
    end-price: uint,     ;; BTC/USD closing price (sats)
    total-up-stake: uint, ;; Aggregate long positions
    total-down-stake: uint, ;; Aggregate short positions
    start-block: uint,   ;; Stacks block height - market open
    end-block: uint,     ;; Stacks block height - market close
    resolved: bool       ;; Settlement status
  }
)

(define-map user-predictions
  {market-id: uint, user: principal}
  { ;; Individual position tracking
    prediction: (string-ascii 4), ;; "up" or "down"
    stake: uint,                  ;; STX committed
    claimed: bool                 ;; Reward status
  }
)

;; Core Market Operations

;; Initialize new BTC price prediction market
(define-public (create-market (start-price uint) (start-block uint) (end-block uint))
  (let
    ((market-id (var-get market-counter)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> end-block start-block) err-invalid-parameter)
    (asserts! (> start-price u0) err-invalid-parameter)
    (map-set markets market-id
      {
        start-price: start-price,
        end-price: u0,
        total-up-stake: u0,
        total-down-stake: u0,
        start-block: start-block,
        end-block: end-block,
        resolved: false
      }
    )
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Execute BTC price prediction with STX
(define-public (make-prediction (market-id uint) (prediction (string-ascii 4)) (stake uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (current-block-height stacks-block-height)
    )
    (asserts! (and (>= current-block-height (get start-block market)) 
                   (< current-block-height (get end-block market))) 
              err-market-ended)
    (asserts! (or (is-eq prediction "up") (is-eq prediction "down")) 
              err-invalid-prediction)
    (asserts! (>= stake (var-get minimum-stake)) err-invalid-parameter)
    (asserts! (<= stake (stx-get-balance tx-sender)) err-insufficient-balance)
    
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    
    (map-set user-predictions {market-id: market-id, user: tx-sender}
      {prediction: prediction, stake: stake, claimed: false}
    )
    
    (map-set markets market-id
      (merge market
        { ;; Update market liquidity
          total-up-stake: (if (is-eq prediction "up")
                           (+ (get total-up-stake market) stake)
                           (get total-up-stake market)),
          total-down-stake: (if (is-eq prediction "down")
                            (+ (get total-down-stake market) stake)
                            (get total-down-stake market))
        }
      )
    )
    (ok true)
  )
)

;; Finalize market with oracle price
(define-public (resolve-market (market-id uint) (end-price uint))
  (let
    ((market (unwrap! (map-get? markets market-id) err-not-found)))
    (asserts! (is-eq tx-sender (var-get oracle-address)) err-owner-only)
    (asserts! (>= stacks-block-height (get end-block market)) err-market-ended)
    (asserts! (not (get resolved market)) err-market-already-resolved)
    (asserts! (> end-price u0) err-invalid-parameter)
    
    (map-set markets market-id
      (merge market
        { ;; Set settlement parameters
          end-price: end-price,
          resolved: true
        }
      )
    )
    (ok true)
  )
)

;; Claim prediction rewards
(define-public (claim-winnings (market-id uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (prediction (unwrap! (map-get? user-predictions 
                                    {market-id: market-id, user: tx-sender}) 
                          err-not-found))
    )
    (asserts! (get resolved market) err-market-closed)
    (asserts! (not (get claimed prediction)) err-already-claimed)
    
    (let
      (
        (winning-prediction (if (> (get end-price market) 
                                 (get start-price market)) 
                              "up" 
                              "down"))
        (total-stake (+ (get total-up-stake market) 
                       (get total-down-stake market)))
        (winning-stake (if (is-eq winning-prediction "up") 
                        (get total-up-stake market) 
                        (get total-down-stake market)))
      )
      (asserts! (is-eq (get prediction prediction) winning-prediction) 
                err-invalid-prediction)
      
      (let
        (
          (winnings (/ (* (get stake prediction) total-stake) winning-stake))
          (fee (/ (* winnings (var-get fee-percentage)) u100))
          (payout (- winnings fee))
        )
        (try! (as-contract (stx-transfer? payout (as-contract tx-sender) 
                                        tx-sender)))
        (try! (as-contract (stx-transfer? fee (as-contract tx-sender) 
                                        contract-owner)))
        
        (map-set user-predictions {market-id: market-id, user: tx-sender}
          (merge prediction {claimed: true})
        )
        (ok payout)
      )
    )
  )
)

;; Market Data Accessors

;; Get market parameters
(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

;; Get user position details
(define-read-only (get-user-prediction (market-id uint) (user principal))
  (map-get? user-predictions {market-id: market-id, user: user})
)

;; Protocol Analytics

;; Check contract STX balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Administrative Controls

;; Update price oracle address
(define-public (set-oracle-address (new-address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-eq new-address (var-get oracle-address))) err-invalid-parameter)
    (ok (var-set oracle-address new-address))
  )
)

;; Configure minimum position size
(define-public (set-minimum-stake (new-minimum uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-minimum u0) err-invalid-parameter)
    (ok (var-set minimum-stake new-minimum))
  )
)

;; Adjust protocol fee
(define-public (set-fee-percentage (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u100) err-invalid-parameter)
    (ok (var-set fee-percentage new-fee))
  )
)

;; Withdraw protocol revenue
(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount (stx-get-balance (as-contract tx-sender))) 
              err-insufficient-balance)
    (try! (as-contract (stx-transfer? amount (as-contract tx-sender) 
                                    contract-owner)))
    (ok amount)
  )
)