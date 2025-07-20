# YumeProof ClosedLoopToken Module

This Move module implements a closed-loop token system for the YumeProof protocol, providing notarization credits that can be purchased with IOTA and used for notarizing images. The module focuses on credit management and notarization ID indexing as outlined in the architecture steps 7, 8, and 9.

## Overview
- **Token Name:** YumeProof Notarization Credits
- **Symbol:** YUME
- **Purpose:** Credits for notarizing images on the YumeProof protocol
- **Purchase Mechanism:** Buy credits with IOTA or claim free daily credits (max 2 per day)
- **Access Control:** Only allowlisted services can perform notarization actions
- **Gas Station:** All transactions are automatically sponsored by the IOTA Gas Station
- **Notarization ID Indexing:** Unique ID tracking for each notarization request

## Architecture Integration
This contract handles the following steps from the architecture:
- **Step 7: Buy Credits (Free Credits Max 2 Per Day)** - Credit purchase and daily free credit claims
- **Step 8: Notarize Image** - Using credits for image notarization
- **Step 9: Spend Token (for indexing)** - Notarization ID indexing and tracking

Note: Steps 1-6 (device verification, credentials) are handled by external services (Google Play Integrity API, Google Confidential Computing) and are not part of this smart contract.

## Gas Station Integration
All transactions in this contract are automatically sponsored by the IOTA Gas Station at the network level:
- **Purchase Credits**: Gas station covers transaction fees automatically
- **Claim Free Credits**: Gas station covers transaction fees automatically
- **Notarization**: Gas station covers transaction fees automatically

The gas station sponsorship is handled by the IOTA network infrastructure, not explicitly in the contract code. Users don't need to pay gas fees for any operations.

## Function Descriptions

### `init(otw: CLOSEDLOOPTOKEN, ctx: &mut TxContext)`
Initializes the module:
- Creates the YUME token and its metadata.
- Sets up the token policy and allowlist for notarization services.
- Creates a daily credit tracker for managing free credit limits.
- Creates a gas station configuration object for tracking sponsorship settings.
- Creates a notarization registry for ID indexing.
- Shares the policy as a shared object.
- Transfers admin capabilities to the protocol admin (sender).

### `purchase_credits_with_iota<T>(treasury_cap: &mut TreasuryCap<YUMEPROOF>, payment: Coin<T>, ctx: &mut TxContext)`
Allows users to purchase notarization credits by paying with IOTA or other coins (Step 7: Buy Credits):
- Accepts any coin type as payment (typically IOTA coins).
- Calculates the number of credits based on the payment amount and the fixed price per credit.
- Ensures the minimum purchase amount is met.
- Mints the corresponding number of YUMEPROOF credits.
- Transfers credits to the buyer and the payment to the treasury.
- **Gas station automatically sponsors the transaction fees at the network level.**

### `claim_free_daily_credits(treasury_cap: &mut TreasuryCap<YUMEPROOF>, user_address: address, daily_tracker: &mut DailyCreditTracker, clock: &Clock, ctx: &mut TxContext)`
Allows users to claim free daily credits (Step 7: Free Credits Max 2 Per Day):
- Checks daily claim limits and resets counters for new days.
- Ensures the user hasn't exceeded the daily free credit limit (max 2 per day).
- Mints and transfers one free credit to the user.
- Updates the daily claim tracking.
- **Gas station automatically sponsors the transaction fees at the network level.**

### `get_credit_price(): u64`
Returns the fixed price (in IOTA base units) for one notarization credit.

### `get_user_credits(token: &Token<YUMEPROOF>): u64`
Returns the user's current credit balance:
- Takes a token object as input.
- Returns the number of credits the user currently holds.
- Useful for checking balance before making purchases or notarizations.

### `free_mint_yumeproof(treasury_cap: &mut TreasuryCap<YUMEPROOF>, amount: u64, ctx: &mut TxContext): Token<YUMEPROOF>`
Free minting function for testing purposes:
- Mints YUMEPROOF tokens without requiring any payment.
- Takes the amount of tokens to mint directly as a parameter.
- Returns the minted tokens immediately.
- **For testing and development only - not for production use.**
- **Gas station automatically sponsors the transaction fees at the network level.**

### `use_credits_for_notarization_with_id(token: Token<YUMEPROOF>, policy: &TokenPolicy<YUMEPROOF>, notarization_id: vector<u8>, image_hash: vector<u8>, credits_needed: u64, registry: &mut NotarizationRegistry, ctx: &mut TxContext): (ActionRequest<YUMEPROOF>, NotarizationRecord)`
Allows users to spend credits for notarization with ID indexing (Step 8: Notarize Image + Step 9: Spend Token for indexing):
- Checks that the user has enough credits.
- Validates that the notarization ID doesn't already exist.
- Creates a notarization record with the provided ID for indexing.
- Creates a spend request for the specified number of credits.
- Adds notarization policy approval to the request.
- Returns both the action request and the notarization record.
- **Gas station automatically sponsors the transaction fees at the network level.**

### `complete_notarization(notarization_record: &mut NotarizationRecord, status: u8, ctx: &mut TxContext)`
Completes a notarization with a status update:
- Updates the notarization status (1: completed, 2: failed).
- Records the completion timestamp.

### `get_notarization_by_id(registry: &NotarizationRegistry, notarization_id: vector<u8>): (address, vector<u8>, u64, u8, u64)`
Retrieves notarization information by ID for verification:
- Returns the record address, image hash, timestamp, status, and credits used.
- Fails if the notarization ID doesn't exist.

### `notarization_exists(registry: &NotarizationRegistry, notarization_id: vector<u8>): bool`
Checks if a notarization ID exists in the registry:
- Returns true if the notarization ID is found, false otherwise.

### `register_notarization_service(policy: &mut TokenPolicy<YUMEPROOF>, cap: &TokenPolicyCap<YUMEPROOF>, service_address: address, _ctx: &mut TxContext)`
Registers a new notarization service:
- Adds the given service address to the allowlist in the token policy.
- Only callable by an entity with the policy capability.

### `is_notarization_service(policy: &TokenPolicy<YUMEPROOF>, address: address): bool`
Checks if a given address is a registered notarization service:
- Returns `true` if the address is in the allowlist, `false` otherwise.

### `update_gas_station(gas_station: &mut GasStation, new_sponsor: address, is_active: bool, _ctx: &mut TxContext)`
Updates the gas station configuration:
- Changes the sponsor address for transaction sponsorship.
- Enables or disables the gas station functionality.

### `get_gas_station_info(gas_station: &GasStation): (address, bool)`
Returns the current gas station configuration:
- Returns the sponsor address and active status.

### `is_gas_station_available(gas_station: &GasStation): bool`
Checks if the gas station is available for sponsorship:
- Returns true if the gas station is active, false otherwise.

### `test_init(ctx: &mut TxContext)`
Test-only function to initialize the module in a test context.

## Constants
- `PRICE_PER_CREDIT`: The price of one credit in IOTA base units (1_000_000).
- `MIN_PURCHASE`: The minimum number of credits that can be purchased in a single transaction.
- `MAX_FREE_CREDITS_PER_DAY`: Maximum free credits that can be claimed per day (2).
- `EIncorrectPayment`: Error code for incorrect payment amounts.
- `EDailyLimitExceeded`: Error code for exceeding daily free credit limit.
- `ENotarizationIdExists`: Error code for duplicate notarization IDs.
- `ENotarizationIdNotFound`: Error code for non-existent notarization IDs.

## Structs
- `CLOSEDLOOPTOKEN`: One-time witness for module initialization.
- `YUMEPROOF`: The token type for notarization credits.
- `NotarizationPolicy`: Policy struct for allowlisting notarization services.
- `DailyCreditTracker`: Manages daily free credit claims across all users.
- `GasStation`: Configuration for tracking gas station sponsorship settings.
- `NotarizationRecord`: Stores individual notarization records with IDs for indexing.
- `NotarizationRegistry`: Manages all notarization records and ID tracking.

## Usage Notes
- Only allowlisted services can perform notarization actions using credits.
- Credits are non-divisible (no decimals).
- All admin capabilities are transferred to the protocol admin after initialization.
- Daily free credit limits are enforced per user address (max 2 per day).
- **All transactions are automatically sponsored by the IOTA Gas Station at the network level.**
- Each notarization request requires a unique ID for tracking and verification.
- Notarization records are stored with status tracking (pending, completed, failed).
- Device verification and credential management are handled by external services.
- Users don't need to pay gas fees for any operations. 