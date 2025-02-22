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
