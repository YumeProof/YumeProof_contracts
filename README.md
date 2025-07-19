# YumeProof ClosedLoopToken Module

This Move module implements a closed-loop token system for the YumeProof protocol, providing notarization credits that can be purchased with IOTA and used for notarizing images. The module includes mechanisms for credit purchase, usage, and service registration, as well as access control via a policy allowlist. The system is designed to work with device verification, verifiable credentials, and gas station sponsorship as outlined in the architecture.

## Overview
- **Token Name:** YumeProof Notarization Credits
- **Symbol:** YUME
- **Purpose:** Credits for notarizing images on the YumeProof protocol
- **Purchase Mechanism:** Buy credits with IOTA or claim free daily credits (max 2 per day)
- **Access Control:** Only allowlisted services can perform notarization actions
- **Device Verification:** Integration with Google Play Integrity API for device verification
- **Gas Station:** Sponsorship of on-chain transactions

## Function Descriptions

### `init(otw: CLOSEDLOOPTOKEN, ctx: &mut TxContext)`
Initializes the module:
- Creates the YUME token and its metadata.
- Sets up the token policy and allowlist for notarization services.
- Creates a daily credit tracker for managing free credit limits.
- Creates a gas station for transaction sponsorship.
- Shares the policy as a shared object.
- Transfers admin capabilities to the protocol admin (sender).

### `register_device_verification(device_did: address, verification_token: vector<u8>, ctx: &mut TxContext)`
Registers a device verification after Google Play Integrity API validation:
- Creates a DeviceVerification object with the device's DID.
- Records verification timestamp and initializes daily credit tracking.
- Shares the verification object for future reference.

### `issue_verifiable_credentials(device_did: address, credentials_hash: vector<u8>, valid_duration_ms: u64, ctx: &mut TxContext)`
Issues verifiable credentials for a verified device:
- Creates VerifiableCredentials object with device DID and credentials hash.
- Sets validity period for the credentials.
- Shares the credentials object for validation during notarization.

### `purchase_credits_with_iota(treasury_cap: &mut TreasuryCap<YUMEPROOF>, payment: Coin<YUMEPROOF>, ctx: &mut TxContext)`
Allows users to purchase notarization credits by paying IOTA:
- Calculates the number of credits based on the payment amount and the fixed price per credit.
- Ensures the minimum purchase amount is met.
- Mints the corresponding number of credits.
- Transfers credits to the buyer and the IOTA payment to the treasury.

### `claim_free_daily_credits(treasury_cap: &mut TreasuryCap<YUMEPROOF>, device_did: address, daily_tracker: &mut DailyCreditTracker, clock: &Clock, ctx: &mut TxContext)`
Allows verified devices to claim free daily credits (max 2 per day):
- Checks daily claim limits and resets counters for new days.
- Ensures the device hasn't exceeded the daily free credit limit.
- Mints and transfers one free credit to the device.
- Updates the daily claim tracking.

### `get_credit_price(): u64`
Returns the fixed price (in IOTA base units) for one notarization credit.

### `use_credits_for_notarization(token: Token<YUMEPROOF>, policy: &TokenPolicy<YUMEPROOF>, device_did: address, image_hash: vector<u8>, credits_needed: u64, ctx: &mut TxContext): ActionRequest<YUMEPROOF>`
Allows a verified device to spend credits for notarization:
- Checks that the user has enough credits.
- Validates device verification and credentials (placeholder implementation).
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

### `update_gas_station(gas_station: &mut GasStation, new_sponsor: address, is_active: bool, _ctx: &mut TxContext)`
Updates the gas station configuration:
- Changes the sponsor address for transaction sponsorship.
- Enables or disables the gas station functionality.

### `get_gas_station_info(gas_station: &GasStation): (address, bool)`
Returns the current gas station configuration:
- Returns the sponsor address and active status.

### `is_device_verified(device_did: address): bool`
Checks if a device is verified (placeholder implementation):
- Would validate against shared DeviceVerification objects.
- Currently returns true as a placeholder.

### `validate_credentials(device_did: address, credentials_hash: vector<u8>, current_time: u64): bool`
Validates verifiable credentials for a device (placeholder implementation):
- Would validate against shared VerifiableCredentials objects.
- Currently returns true as a placeholder.

### `test_init(ctx: &mut TxContext)`
Test-only function to initialize the module in a test context.

## Constants
- `PRICE_PER_CREDIT`: The price of one credit in IOTA base units (1_000_000).
- `MIN_PURCHASE`: The minimum number of credits that can be purchased in a single transaction.
- `MAX_FREE_CREDITS_PER_DAY`: Maximum free credits that can be claimed per day (2).
- `EIncorrectPayment`: Error code for incorrect payment amounts.
- `EDailyLimitExceeded`: Error code for exceeding daily free credit limit.
- `EDeviceNotVerified`: Error code for unverified devices.
- `EInvalidCredentials`: Error code for invalid credentials.

## Structs
- `CLOSEDLOOPTOKEN`: One-time witness for module initialization.
- `YUMEPROOF`: The token type for notarization credits.
- `NotarizationPolicy`: Policy struct for allowlisting notarization services.
- `DeviceVerification`: Tracks device verification status and daily credit claims.
- `VerifiableCredentials`: Stores verifiable credentials for devices with validity periods.
- `DailyCreditTracker`: Manages daily free credit claims across all devices.
- `GasStation`: Configuration for transaction sponsorship.

## Architecture Integration
The contract is designed to integrate with the following components from the architecture:
- **Google Play Integrity API**: Device verification through `register_device_verification`
- **Google Confidential Computing**: Credential issuance through `issue_verifiable_credentials`
- **IOTA Gas Station**: Transaction sponsorship through `GasStation` struct
- **Mobile Application**: Credit claiming and notarization through daily limits and device verification
- **Verifier Web Interface**: Service registration and verification through notarization service allowlist

## Usage Notes
- Only allowlisted services can perform notarization actions using credits.
- Credits are non-divisible (no decimals).
- All admin capabilities are transferred to the protocol admin after initialization.
- Devices must be verified before claiming free credits or performing notarization.
- Daily free credit limits are enforced per device DID.
- Gas station sponsorship is available for covering transaction costs. 