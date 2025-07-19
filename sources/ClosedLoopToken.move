module yumeproof_contracts::ClosedLoopToken {
    use std::vector;
    use std::option::{Self, Option};
    use iota::bag::{Self, Bag};
    use iota::token::{Self, Token, TokenPolicy, TokenPolicyCap, ActionRequest};
    use iota::coin::{Self, TreasuryCap};
    use iota::tx_context::{Self, TxContext};
    use iota::transfer;

    /// One Time Witness for the token
    struct YUMEPROOF has drop {}

    /// Error if no configuration is found
    const ENoConfig: u64 = 0;
    /// Error if sender is not a shop
    const ESenderNotAShop: u64 = 1;
    /// Error if sender is a shop
    const ESenderIsAShop: u64 = 2;
    /// Error if recipient is not a shop
    const ERecipientNotAShop: u64 = 3;

    /// The allowlist rule struct that implements our token policy
    struct Allowlist has drop {}

    /// Initialize the module
    fun init(otw: YUMEPROOF, ctx: &mut TxContext) {
        let (treasury_cap, coin_metadata) = coin::create_currency(
            otw,
            0, // no decimals
            b"YUME",  // symbol
            b"YumeProof Token", // name
            b"Token used for YumeProof protocol", // description
            option::none(), // url
            ctx
        );

        // Create token policy
        let (mut policy, policy_cap) = token::new_policy(&treasury_cap, ctx);
        
        // Add rules for transfer and spend actions
        policy.add_rule_for_action<YUMEPROOF, Allowlist>(
            &policy_cap, 
            token::transfer_action(), 
            ctx
        );
        policy.add_rule_for_action<YUMEPROOF, Allowlist>(
            &policy_cap, 
            token::spend_action(), 
            ctx
        );

        // Share policy as a shared object
        token::share_policy(policy);

        // Transfer capabilities to sender
        transfer::public_transfer(policy_cap, ctx.sender());
        transfer::public_freeze_object(coin_metadata);
        transfer::public_transfer(treasury_cap, ctx.sender());
    }

    /// Check if policy has a rule config
    public fun has_config<T>(policy: &TokenPolicy<T>): bool {
        token::has_rule_config<Allowlist, Bag>(policy)
    }

    /// Get the rule config
    public fun config<T>(policy: &TokenPolicy<T>): &Bag {
        token::rule_config<Allowlist, Bag>(policy)
    }

    /// Get mutable rule config
    public fun config_mut<T>(
        policy: &TokenPolicy<T>,
        cap: &TokenPolicyCap<T>
    ): &mut Bag {
        token::rule_config_mut<Allowlist, Bag>(policy, cap)
    }

    /// Add addresses to the allowlist
    public fun add_addresses<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut addresses: vector<address>,
        ctx: &mut TxContext,
    ) {
        if (!has_config(policy)) {
            token::add_rule_config(Allowlist {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        while (vector::length(&addresses) > 0) {
            bag::add(config_mut, vector::pop_back(&mut addresses), true)
        }
    }

    /// Verify rule compliance
    public fun verify<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) {
        assert!(has_config(policy), ENoConfig);

        let config = config(policy);
        let sender = token::sender(request);
        let recipient = token::recipient(request);

        if (request.action() == token::spend_action()) {
            // Sender needs to be a shop
            assert!(bag::contains(config, sender), ESenderNotAShop);
        } else if (request.action() == token::transfer_action()) {
            // The sender can't be a shop
            assert!(!bag::contains(config, sender), ESenderIsAShop);

            // The recipient has to be a shop
            let recipient = *option::borrow(&recipient);
            assert!(bag::contains(config, recipient), ERecipientNotAShop);
        };

        token::add_approval(Allowlist {}, request, ctx);
    }

    /// Gift tokens to an address
    public fun gift_token(
        cap: &mut TreasuryCap<YUMEPROOF>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let token = token::mint(cap, amount, ctx);
        let req = token.transfer(recipient, ctx);
        token::confirm_with_treasury_cap(cap, req, ctx);
    }

    /// Register shop addresses that can receive tokens
    public fun register_shop(
        policy: &mut TokenPolicy<YUMEPROOF>,
        cap: &TokenPolicyCap<YUMEPROOF>,
        addresses: vector<address>,
        ctx: &mut TxContext
    ) {
        add_addresses(policy, cap, addresses, ctx)
    }

    /// Return token to treasury
    public fun return_token(
        token: Token<YUMEPROOF>,
        policy: &TokenPolicy<YUMEPROOF>,
        ctx: &mut TxContext
    ): ActionRequest<YUMEPROOF> {
        let mut action_request = token.spend(ctx);
        verify(policy, &mut action_request, ctx);
        action_request
    }
}


