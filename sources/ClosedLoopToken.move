module yumeproof_contracts::ClosedLoopToken {
    use std::option::{Self, Option};
    use iota::token::{Self, Token, TokenPolicy, TokenPolicyCap, ActionRequest};
    use iota::coin::{Self, TreasuryCap};
    use iota::tx_context::{Self, TxContext};
    use iota::transfer;
    use iota::balance::{Self, Balance};
    use iota::bag::{Self, Bag};

    /// YumeProof Notarization Credits Token
    struct YUMEPROOF has drop {}

    /// Error if action is not allowed
    const ENotAuthorized: u64 = 0;
    /// Error if trying to use more credits than available
    const EInsufficientCredits: u64 = 1;

    /// Allowlist for authorized notarization services
    struct NotarizationPolicy has drop {}

    /// Initialize the module
    fun init(otw: YUMEPROOF, ctx: &mut TxContext) {
        let (treasury_cap, coin_metadata) = coin::create_currency(
            otw,
            0, // no decimals
            b"YUME",  // symbol
            b"YumeProof Notarization Credits", // name
            b"Credits for notarizing images on YumeProof protocol", // description
            option::none(), // url
            ctx
        );

        // Create token policy for notarization service
        let (mut policy, policy_cap) = token::new_policy(&treasury_cap, ctx);
        
        // Add rules for spend actions (using credits)
        policy.add_rule_for_action<YUMEPROOF, NotarizationPolicy>(
            &policy_cap, 
            token::spend_action(), 
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

    /// Purchase notarization credits
    public fun purchase_credits(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let token = token::mint(treasury_cap, amount, ctx);
        let req = token.transfer(recipient, ctx);
        token::confirm_with_treasury_cap(treasury_cap, req, ctx);
    }

    /// Use credits for notarization
    public fun use_credits(
        token: Token<YUMEPROOF>,
        policy: &TokenPolicy<YUMEPROOF>,
        credits_needed: u64,
        ctx: &mut TxContext
    ): ActionRequest<YUMEPROOF> {
        // Verify token has enough credits
        assert!(balance::value(&token::into_balance(token)) >= credits_needed, EInsufficientCredits);
        
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
        ctx: &mut TxContext
    ) {
        let config = token::rule_config_mut<NotarizationPolicy, Bag>(policy, cap);
        bag::add(config, service_address, true);
    }

    /// Check if address is registered notarization service
    public fun is_notarization_service(
        policy: &TokenPolicy<YUMEPROOF>,
        address: address
    ): bool {
        let config = token::rule_config<NotarizationPolicy, Bag>(policy);
        bag::contains(config, address)
    }
}


