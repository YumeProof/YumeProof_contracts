module yumeproof_contracts::ClosedLoopToken {
    use iota::token::{Self, Token, TokenPolicy, TokenPolicyCap, ActionRequest};
    use iota::coin::{Self, TreasuryCap, Coin};
    use iota::tx_context;
    use iota::bag;
    use iota::transfer;

    /// Credit package prices in IOTA
    const PRICE_PER_CREDIT: u64 = 1_000_000; // 1 IOTA = 1M base units
    
    /// Minimum purchase amount
    const MIN_PURCHASE: u64 = 1;
    
    /// Error if payment amount is incorrect
    const EIncorrectPayment: u64 = 2;
    
    /// Error if action is not authorized
    const ENotAuthorized: u64 = 3;

    /// One-time witness for module initialization
    public struct CLOSEDLOOPTOKEN has drop {}

    /// YumeProof Notarization Credits Token type - only usable within YumeProof protocol
    public struct YUMEPROOF has store {}

    /// Allowlist for authorized notarization services
    public struct NotarizationPolicy has drop, store {}

    /// Initialize the module
    fun init(otw: CLOSEDLOOPTOKEN, ctx: &mut TxContext) {
        let (treasury_cap, coin_metadata) = coin::create_currency(
            otw,
            0, // no decimals
            b"YUME",  // symbol
            b"YumeProof Notarization Credits", // name
            b"Credits for notarizing images on YumeProof protocol", // description
            option::none(), // url
            ctx
        ); 

        

        // Create token policy
        let (mut policy, policy_cap) = token::new_policy(&treasury_cap, ctx);
        
        // Add rules for spend and transfer actions
        token::add_rule_for_action<CLOSEDLOOPTOKEN, NotarizationPolicy>(
            &mut policy,
            &policy_cap, 
            token::spend_action(), 
            ctx
        );
        
        // Prevent direct transfers between users
        token::add_rule_for_action<CLOSEDLOOPTOKEN, NotarizationPolicy>(
            &mut policy,
            &policy_cap,
            token::transfer_action(),
            ctx
        );

        // Initialize empty notarization service allowlist
        token::add_rule_config(NotarizationPolicy {}, &mut policy, &policy_cap, bag::new(ctx), ctx);

        // Share policy as a shared object
        token::share_policy(policy);

        // Transfer capabilities to protocol admin
        transfer::public_transfer(policy_cap, ctx.sender());
        transfer::public_freeze_object(coin_metadata);
        transfer::public_transfer(treasury_cap, ctx.sender());
    }

    /// Purchase notarization credits with IOTA
    public fun purchase_credits_with_iota(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        payment: Coin<YUMEPROOF>,
        ctx: &mut TxContext
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
    
    
    /// Get credit price in IOTA
    public fun get_credit_price(): u64 {
        PRICE_PER_CREDIT
    }

    /// Use credits for notarization
    public fun use_credits(
        token: Token<YUMEPROOF>,
        _policy: &TokenPolicy<YUMEPROOF>,
        credits_needed: u64,
        ctx: &mut TxContext
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
        _ctx: &mut TxContext
    ) {
        let rule = NotarizationPolicy {};
        let config = token::rule_config_mut<YUMEPROOF, NotarizationPolicy, bag::Bag>(rule, policy, cap);
        bag::add(config, service_address, true);
    }

    /// Check if address is registered notarization service
    public fun is_notarization_service(
        policy: &TokenPolicy<YUMEPROOF>,
        address: address
    ): bool {
        let rule = NotarizationPolicy {};
        let config = token::rule_config<YUMEPROOF, NotarizationPolicy, bag::Bag>(rule, policy);
        bag::contains(config, address)
    }
}


