# BitFutures: Trustless Bitcoin Price Prediction Markets

BitFutures is a decentralized prediction market protocol built on Stacks Layer 2, enabling trustless speculation on Bitcoin price movements using STX tokens. The protocol combines the security of Bitcoin with the scalability of Stacks to create a robust, non-custodial platform for BTC price predictions.

## Overview

BitFutures allows participants to:

- Create and participate in BTC/USD price prediction markets
- Stake STX tokens on price movement directions ("up" or "down")
- Earn rewards based on successful predictions
- Interact with a fully transparent and automated settlement system

## Core Features

- **Non-custodial Operation**: All funds are secured by smart contracts
- **Transparent Price Resolution**: Oracle-based price feeds for reliable settlement
- **Layer 2 Efficiency**: Built on Stacks for scalable, cost-effective operations
- **Bitcoin-Native**: Leverages Bitcoin's security model and Stacks' sBTC integration

## Smart Contract Architecture

### Key Components

1. **Market Management**

   - Sequential market IDs for unique identification
   - Configurable start and end blocks
   - Price thresholds and settlement parameters
   - Total stake tracking for both directions

2. **User Positions**

   - Individual stake tracking
   - Direction-based predictions ("up"/"down")
   - Claim status management

3. **Economic Parameters**
   - Minimum stake requirements
   - Protocol fee configuration
   - Oracle address management

### Core Functions

#### Market Creation

```clarity
(define-public (create-market (start-price uint) (start-block uint) (end-block uint)))
```

Creates a new prediction market with specified parameters:

- `start-price`: Initial BTC/USD price
- `start-block`: Market opening block height
- `end-block`: Market closing block height

#### Making Predictions

```clarity
(define-public (make-prediction (market-id uint) (prediction (string-ascii 4)) (stake uint)))
```

Allows users to participate in markets:

- `market-id`: Target market identifier
- `prediction`: "up" or "down" price movement
- `stake`: Amount of STX to commit

#### Market Resolution

```clarity
(define-public (resolve-market (market-id uint) (end-price uint)))
```

Finalizes markets with oracle-provided prices:

- `market-id`: Market to resolve
- `end-price`: Final BTC/USD price

#### Claiming Rewards

```clarity
(define-public (claim-winnings (market-id uint)))
```

Enables winners to claim their rewards from resolved markets

### Administrative Controls

- Oracle address management
- Minimum stake adjustment
- Fee percentage configuration
- Protocol revenue withdrawal

## Economic Model

### Fees and Rewards

- Protocol fee: Configurable percentage of winnings
- Winner's reward: Proportional to stake and total market liquidity
- Minimum stake: Prevents dust transactions

### Settlement Logic

1. Market closes at specified block height
2. Oracle provides final price
3. Winning direction determined
4. Winners can claim proportional rewards
5. Protocol fees automatically distributed

## Security Features

- Owner-only administrative functions
- Non-custodial fund management
- Oracle-based price verification
- Block height-based market phases
- Balance checks for all transfers

## Error Handling

The contract includes comprehensive error codes:

- `err-owner-only` (u100): Authorization failures
- `err-not-found` (u101): Invalid data lookups
- `err-invalid-prediction` (u102): Wrong prediction format
- `err-market-closed` (u103): Lifecycle violations
- `err-already-claimed` (u104): Duplicate claims
- `err-insufficient-balance` (u105): Funding issues

## Integration Guidelines

### Reading Market Data

```clarity
(define-read-only (get-market (market-id uint)))
(define-read-only (get-user-prediction (market-id uint) (user principal)))
```

### Monitoring Contract State

```clarity
(define-read-only (get-contract-balance))
```

## Best Practices for Users

1. **Before Participating**

   - Verify market parameters
   - Check current block height
   - Ensure sufficient STX balance

2. **Making Predictions**

   - Confirm market is active
   - Verify minimum stake requirement
   - Double-check prediction direction

3. **Claiming Rewards**
   - Wait for market resolution
   - Verify winning direction
   - Check claim status

## Protocol Governance

The contract owner can:

- Update oracle addresses
- Adjust minimum stakes
- Modify fee percentages
- Withdraw protocol revenues

## Future Considerations

The protocol is designed to support:

- Multiple oracle integration
- Dynamic fee structures
- Enhanced market parameters
- Advanced settlement mechanisms

## Technical Requirements

- Stacks 2.0 compatible wallet
- Sufficient STX for predictions
- Understanding of block height mechanics
