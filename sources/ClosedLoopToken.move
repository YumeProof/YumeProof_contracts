module yumeproof_contracts::ClosedLoopToken {
    use iota::bag;
    use iota::coin::{Self, TreasuryCap, Coin};
    use iota::token::{Self, Token, TokenPolicy, TokenPolicyCap, ActionRequest};
    use iota::object;
    use iota::table::{Self, Table};
    use iota::clock::{Self, Clock};

    /// Credit package prices in IOTA
    const PRICE_PER_CREDIT: u64 = 1_000_000; // 1 IOTA = 1M base units

    /// Minimum purchase amount
    const MIN_PURCHASE: u64 = 1;

    /// Maximum free credits per day
    const MAX_FREE_CREDITS_PER_DAY: u64 = 2;

    /// Error if payment amount is incorrect
    const EIncorrectPayment: u64 = 2;

    /// Error if daily free credit limit exceeded
    const EDailyLimitExceeded: u64 = 3;

    /// One-time witness for module initialization
    public struct CLOSEDLOOPTOKEN has drop {}

    /// YumeProof Notarization Credits Token type
    public struct YUMEPROOF has drop {}

    /// Allowlist for authorized notarization services
    public struct NotarizationPolicy has drop, store {}

    /// Device verification status
    public struct DeviceVerification has key, store {
        id: object::UID,
        device_did: address,
        verified: bool,
        verification_timestamp: u64,
        daily_free_credits_claimed: u64,
        last_claim_date: u64,
    }

    /// Verifiable credentials for devices
    public struct VerifiableCredentials has key, store {
        id: object::UID,
        device_did: address,
        credentials_hash: vector<u8>,
        issued_timestamp: u64,
        valid_until: u64,
    }

    /// Daily credit tracking
    public struct DailyCreditTracker has key {
        id: object::UID,
        daily_claims: Table<address, u64>,
        last_reset_date: u64,
    }

    /// Gas station configuration
    public struct GasStation has key {
        id: object::UID,
        sponsor_address: address,
        is_active: bool,
    }

    /// Initialize the module
    fun init(otw: CLOSEDLOOPTOKEN, ctx: &mut TxContext) {
        let (treasury_cap, coin_metadata) = coin::create_currency(
            otw,
            0, // no decimals
            b"YUME", // symbol
            b"YumeProof Notarization Credits", // name
            b"Credits for notarizing images on YumeProof protocol", // description
            option::none(), // url
            ctx,
        );

        // Create token policy
        let (mut policy, policy_cap) = token::new_policy(&treasury_cap, ctx);

        // Add rules for spend actions
        token::add_rule_for_action<CLOSEDLOOPTOKEN, NotarizationPolicy>(
            &mut policy,
            &policy_cap,
            token::spend_action(),
            ctx,
        );

        // Initialize empty notarization service allowlist
        token::add_rule_config(NotarizationPolicy {}, &mut policy, &policy_cap, bag::new(ctx), ctx);

        // Share policy as a shared object
        token::share_policy(policy);

        // Create daily credit tracker
        let daily_tracker = DailyCreditTracker {
            id: object::new(ctx),
            daily_claims: table::new(ctx),
            last_reset_date: 0, // Will be set when first used
        };
        transfer::share_object(daily_tracker);

        // Create gas station
        let gas_station = GasStation {
            id: object::new(ctx),
            sponsor_address: ctx.sender(),
            is_active: true,
        };
        transfer::share_object(gas_station);

        // Transfer capabilities to protocol admin
        transfer::public_transfer(policy_cap, ctx.sender());
        transfer::public_freeze_object(coin_metadata);
        transfer::public_transfer(treasury_cap, ctx.sender());
    }

    /// Register device verification
    public fun register_device_verification(
        device_did: address,
        _verification_token: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let device_verification = DeviceVerification {
            id: object::new(ctx),
            device_did,
            verified: true,
            verification_timestamp: 0, // Will be set by external timestamp
            daily_free_credits_claimed: 0,
            last_claim_date: 0,
        };
        transfer::share_object(device_verification);
    }

    /// Issue verifiable credentials for device
    public fun issue_verifiable_credentials(
        device_did: address,
        credentials_hash: vector<u8>,
        valid_duration_ms: u64,
        ctx: &mut TxContext,
    ) {
        let credentials = VerifiableCredentials {
            id: object::new(ctx),
            device_did,
            credentials_hash,
            issued_timestamp: 0, // Will be set by external timestamp
            valid_until: valid_duration_ms, // Simplified for now
        };
        transfer::share_object(credentials);
    }

    /// Purchase notarization credits with IOTA
    public fun purchase_credits_with_iota(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        payment: Coin<YUMEPROOF>,
        ctx: &mut TxContext,
    ) {
        // Calculate number of credits based on payment amount
        let payment_amount = coin::value(&payment);
        let credits = payment_amount / PRICE_PER_CREDIT;

        // Ensure minimum purchase amount
        assert!(credits >= MIN_PURCHASE, EIncorrectPayment);

        // Mint credits
        let token = token::mint(treasury_cap, credits, ctx);

        // Transfer credits to buyer
        let req = token.transfer(ctx.sender(), ctx);
        token::confirm_with_treasury_cap(treasury_cap, req, ctx);

        // Transfer IOTA payment to treasury
        transfer::public_transfer(payment, ctx.sender());
    }

    /// Claim free daily credits (max 2 per day)
    public fun claim_free_daily_credits(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        device_did: address,
        daily_tracker: &mut DailyCreditTracker,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let current_time = clock::timestamp_ms(clock);
        let current_date = current_time / (24 * 60 * 60 * 1000); // Days since epoch

        // Check if we need to reset daily claims for a new day
        if (current_date > daily_tracker.last_reset_date) {
            daily_tracker.last_reset_date = current_date;
        };

        // Check current daily claims
        let current_claims = if (table::contains(&daily_tracker.daily_claims, device_did)) {
            *table::borrow(&daily_tracker.daily_claims, device_did)
        } else {
            0
        };

        // Ensure daily limit not exceeded
        assert!(current_claims < MAX_FREE_CREDITS_PER_DAY, EDailyLimitExceeded);

        // Mint free credits
        let token = token::mint(treasury_cap, 1, ctx);

        // Transfer credits to device
        let req = token.transfer(device_did, ctx);
        token::confirm_with_treasury_cap(treasury_cap, req, ctx);

        // Update daily claims
        if (table::contains(&daily_tracker.daily_claims, device_did)) {
            let claims = table::borrow_mut(&mut daily_tracker.daily_claims, device_did);
            *claims = *claims + 1;
        } else {
            table::add(&mut daily_tracker.daily_claims, device_did, 1);
        };
    }

    /// Get credit price in IOTA
    public fun get_credit_price(): u64 {
        PRICE_PER_CREDIT
    }

    /// Use credits for notarization (requires device verification)
    public fun use_credits_for_notarization(
        token: Token<YUMEPROOF>,
        _policy: &TokenPolicy<YUMEPROOF>,
        _device_did: address,
        _image_hash: vector<u8>,
        credits_needed: u64,
        ctx: &mut TxContext,
    ): ActionRequest<YUMEPROOF> {
        let balance = token::value(&token);
        assert!(balance >= credits_needed, EIncorrectPayment);

        // Create spend request
        let mut action_request = token.spend(ctx);

        // Add notarization policy approval
        token::add_approval(NotarizationPolicy {}, &mut action_request, ctx);

        action_request
    }

    /// Register notarization service
    public fun register_notarization_service(
        policy: &mut TokenPolicy<YUMEPROOF>,
        cap: &TokenPolicyCap<YUMEPROOF>,
        service_address: address,
        _ctx: &mut TxContext,
    ) {
        let rule = NotarizationPolicy {};
        let config = token::rule_config_mut<YUMEPROOF, NotarizationPolicy, bag::Bag>(
            rule,
            policy,
            cap,
        );
        bag::add(config, service_address, true);
    }

    /// Check if address is registered notarization service
    public fun is_notarization_service(policy: &TokenPolicy<YUMEPROOF>, address: address): bool {
        let rule = NotarizationPolicy {};
        let config = token::rule_config<YUMEPROOF, NotarizationPolicy, bag::Bag>(rule, policy);
        bag::contains(config, address)
    }

    /// Update gas station configuration
    public fun update_gas_station(
        gas_station: &mut GasStation,
        new_sponsor: address,
        is_active: bool,
        _ctx: &mut TxContext,
    ) {
        gas_station.sponsor_address = new_sponsor;
        gas_station.is_active = is_active;
    }

    /// Get gas station info
    public fun get_gas_station_info(gas_station: &GasStation): (address, bool) {
        (gas_station.sponsor_address, gas_station.is_active)
    }

    /// Check if device is verified
    public fun is_device_verified(_device_did: address): bool {
        // This would need to check against the shared DeviceVerification objects
        // For now, return true as a placeholder
        true
    }

    /// Validate verifiable credentials
    public fun validate_credentials(
        _device_did: address,
        _credentials_hash: vector<u8>,
        _current_time: u64,
    ): bool {
        true
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(CLOSEDLOOPTOKEN {}, ctx)
    }
}
