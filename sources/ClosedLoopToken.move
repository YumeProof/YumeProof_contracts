module yumeproof_contracts::ClosedLoopToken {
    use iota::bag;
    use iota::coin::{Self, TreasuryCap, Coin};
    use iota::token::{Self, Token, TokenPolicy, TokenPolicyCap, ActionRequest};
    use iota::object;
    use iota::table::{Self, Table};
    use iota::clock::{Self, Clock};

    /// Credit package prices in IOTA
    const PRICE_PER_CREDIT: u64 = 1_000_000; // 1 IOTA = 1M base units

    /// Maximum free credits per day
    const MAX_FREE_CREDITS_PER_DAY: u64 = 2;

    /// Error if payment amount is incorrect
    const EIncorrectPayment: u64 = 2;

    /// Error if daily free credit limit exceeded
    const EDailyLimitExceeded: u64 = 3;

    /// Error if notarization ID already exists
    const ENotarizationIdExists: u64 = 4;

    /// Error if notarization ID not found
    const ENotarizationIdNotFound: u64 = 5;

    /// One-time witness for module initialization
    public struct CLOSEDLOOPTOKEN has drop {}

    /// YumeProof Notarization Credits Token type
    public struct YUMEPROOF has drop {}

    /// Allowlist for authorized notarization services
    public struct NotarizationPolicy has drop, store {}

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

    /// Notarization record with ID for indexing
    public struct NotarizationRecord has key, store {
        id: object::UID,
        notarization_id: vector<u8>,
        user_address: address,
        image_hash: vector<u8>,
        timestamp: u64,
        status: u8, // 0: pending, 1: completed, 2: failed
        credits_used: u64,
    }

    /// Notarization registry for ID indexing
    public struct NotarizationRegistry has key {
        id: object::UID,
        notarizations: Table<vector<u8>, address>, // notarization_id -> record_address
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

        // Create notarization registry for indexing
        let notarization_registry = NotarizationRegistry {
            id: object::new(ctx),
            notarizations: table::new(ctx),
        };
        transfer::share_object(notarization_registry);

        // Transfer capabilities to protocol admin
        transfer::public_transfer(policy_cap, ctx.sender());
        transfer::public_freeze_object(coin_metadata);
        transfer::public_transfer(treasury_cap, ctx.sender());
    }

    /// Purchase notarization credits with IOTA (Step 7: Buy Credits) - Sponsored
    public fun purchase_credits_with_iota<T>(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        payment: Coin<T>,
        ctx: &mut TxContext,
    ) {
        // Calculate number of credits based on payment amount
        let payment_amount = coin::value(&payment);
        let credits = payment_amount / PRICE_PER_CREDIT;

        // Mint credits
        let token = token::mint(treasury_cap, credits, ctx);

        // Transfer credits to buyer
        let req = token.transfer(ctx.sender(), ctx);
        token::confirm_with_treasury_cap(treasury_cap, req, ctx);

        // Transfer payment to treasury
        transfer::public_transfer(payment, ctx.sender());

        // Gas station automatically sponsors this transaction
    }

    /// Claim free daily credits (Step 7: Free Credits Max 2 Per Day) - Sponsored
    public fun claim_free_daily_credits(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        user_address: address,
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
        let current_claims = if (table::contains(&daily_tracker.daily_claims, user_address)) {
            *table::borrow(&daily_tracker.daily_claims, user_address)
        } else {
            0
        };

        // Ensure daily limit not exceeded
        assert!(current_claims < MAX_FREE_CREDITS_PER_DAY, EDailyLimitExceeded);

        // Mint free credits
        let token = token::mint(treasury_cap, 1, ctx);

        // Transfer credits to user
        let req = token.transfer(user_address, ctx);
        token::confirm_with_treasury_cap(treasury_cap, req, ctx);

        // Update daily claims
        if (table::contains(&daily_tracker.daily_claims, user_address)) {
            let claims = table::borrow_mut(&mut daily_tracker.daily_claims, user_address);
            *claims = *claims + 1;
        } else {
            table::add(&mut daily_tracker.daily_claims, user_address, 1);
        };

        // Gas station automatically sponsors this transaction
    }

    /// Get credit price in IOTA
    public fun get_credit_price(): u64 {
        PRICE_PER_CREDIT
    }

    /// Get user's credit balance from their token
    /// Note: In IOTA, the token object itself determines ownership.
    /// The user must hold the token object in their wallet to use it.
    public fun get_user_credits(token: &Token<YUMEPROOF>): u64 {
        token::value(token)
    }

    /// Free mint function for testing - Mint YUMEPROOF tokens without payment
    /// This function allows free minting for testing and development
    public fun free_mint_yumeproof(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        ctx: &mut TxContext,
    ): Token<YUMEPROOF> {
        // Mint YUMEPROOF tokens for free (testing only)
        let token = token::mint(treasury_cap, amount, ctx);
        
        // Return the minted token directly
        token
    }

    /// Use credits for notarization with ID indexing (Step 8: Notarize Image + Step 9: Spend Token for indexing) - Sponsored
    public fun use_credits_for_notarization_with_id(
        token: Token<YUMEPROOF>,
        _policy: &TokenPolicy<YUMEPROOF>,
        notarization_id: vector<u8>,
        image_hash: vector<u8>,
        credits_needed: u64,
        registry: &mut NotarizationRegistry,
        ctx: &mut TxContext,
    ): (ActionRequest<YUMEPROOF>, NotarizationRecord) {
        let balance = token::value(&token);
        assert!(balance >= credits_needed, EIncorrectPayment);

        // Check if notarization ID already exists
        assert!(!table::contains(&registry.notarizations, notarization_id), ENotarizationIdExists);

        // Create notarization record for indexing
        let record = NotarizationRecord {
            id: object::new(ctx),
            notarization_id,
            user_address: ctx.sender(),
            image_hash,
            timestamp: 0, // Will be set by external timestamp
            status: 0, // pending
            credits_used: credits_needed,
        };

        // Register the notarization for indexing
        table::add(&mut registry.notarizations, record.notarization_id, object::uid_to_address(&record.id));

        // Create spend request
        let mut action_request = token.spend(ctx);

        // Add notarization policy approval
        token::add_approval(NotarizationPolicy {}, &mut action_request, ctx);

        // Gas station automatically sponsors this transaction

        (action_request, record)
    }

    /// Complete a notarization
    public fun complete_notarization(
        notarization_record: &mut NotarizationRecord,
        status: u8, // 1: completed, 2: failed
        _ctx: &mut TxContext,
    ) {
        notarization_record.status = status;
        notarization_record.timestamp = 0; // Will be set by external timestamp
    }

    /// Get notarization record by ID for verification
    public fun get_notarization_by_id(
        registry: &NotarizationRegistry,
        notarization_id: vector<u8>,
    ): (address, vector<u8>, u64, u8, u64) {
        assert!(table::contains(&registry.notarizations, notarization_id), ENotarizationIdNotFound);
        
        let record_address = *table::borrow(&registry.notarizations, notarization_id);
        // In a real implementation, you would fetch the record from the address
        // For now, return placeholder values
        (record_address, b"", 0, 0, 0)
    }

    /// Check if notarization ID exists
    public fun notarization_exists(
        registry: &NotarizationRegistry,
        notarization_id: vector<u8>,
    ): bool {
        table::contains(&registry.notarizations, notarization_id)
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

    /// Check if gas station is available for sponsorship
    public fun is_gas_station_available(gas_station: &GasStation): bool {
        gas_station.is_active
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(CLOSEDLOOPTOKEN {}, ctx)
    }
}
