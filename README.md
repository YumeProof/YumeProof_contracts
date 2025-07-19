# YumeProof ClosedLoopToken Module

This Move module implements a closed-loop token system for the YumeProof protocol, providing notarization credits that can be purchased with IOTA and used for notarizing images. The module includes mechanisms for credit purchase, usage, and service registration, as well as access control via a policy allowlist.

## Overview
- **Token Name:** YumeProof Notarization Credits
- **Symbol:** YUME
- **Purpose:** Credits for notarizing images on the YumeProof protocol
- **Purchase Mechanism:** Buy credits with IOTA
- **Access Control:** Only allowlisted services can perform notarization actions

## Function Descriptions

### `init(otw: CLOSEDLOOPTOKEN, ctx: &mut TxContext)`
Initializes the module:
- Creates the YUME token and its metadata.
- Sets up the token policy and allowlist for notarization services.
- Shares the policy as a shared object.
- Transfers admin capabilities to the protocol admin (sender).

### `purchase_credits_with_iota(treasury_cap: &mut TreasuryCap<YUMEPROOF>, payment: Coin<YUMEPROOF>, ctx: &mut TxContext)`
Allows users to purchase notarization credits by paying IOTA:
- Calculates the number of credits based on the payment amount and the fixed price per credit.
- Ensures the minimum purchase amount is met.
- Mints the corresponding number of credits.
- Transfers credits to the buyer and the IOTA payment to the treasury.

### `get_credit_price(): u64`
Returns the fixed price (in IOTA base units) for one notarization credit.

### `use_credits(token: Token<YUMEPROOF>, _policy: &TokenPolicy<YUMEPROOF>, credits_needed: u64, ctx: &mut TxContext): ActionRequest<YUMEPROOF>`
Allows a user to spend credits for notarization:
- Checks that the user has enough credits.
- Creates a spend request for the specified number of credits.
- Adds notarization policy approval to the request.
- Returns the action request for further processing.

### `register_notarization_service(policy: &mut TokenPolicy<YUMEPROOF>, cap: &TokenPolicyCap<YUMEPROOF>, service_address: address, _ctx: &mut TxContext)`
Registers a new notarization service:
- Adds the given service address to the allowlist in the token policy.
- Only callable by an entity with the policy capability.

### `is_notarization_service(policy: &TokenPolicy<YUMEPROOF>, address: address): bool`
Checks if a given address is a registered notarization service:
- Returns `true` if the address is in the allowlist, `false` otherwise.

### `test_init(ctx: &mut TxContext)`
Test-only function to initialize the module in a test context.

## Constants
- `PRICE_PER_CREDIT`: The price of one credit in IOTA base units (1_000_000).
- `MIN_PURCHASE`: The minimum number of credits that can be purchased in a single transaction.
- `EIncorrectPayment`: Error code for incorrect payment amounts.

## Structs
- `CLOSEDLOOPTOKEN`: One-time witness for module initialization.
- `YUMEPROOF`: The token type for notarization credits.
- `NotarizationPolicy`: Policy struct for allowlisting notarization services.

## Usage Notes
- Only allowlisted services can perform notarization actions using credits.
- Credits are non-divisible (no decimals).
- All admin capabilities are transferred to the protocol admin after initialization.

---
For more details, see the source code in `sources/ClosedLoopToken.move`. 