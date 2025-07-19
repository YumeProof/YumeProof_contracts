module yumeproof_contracts::ClosedLoopToken {
    use std::option::{Self, Option};
    use iota::token::{Self, Token};
    use iota::coin::{Self, TreasuryCap};
    use iota::tx_context::{Self, TxContext};
    use iota::transfer;
    use iota::balance::{Self, Balance};

    /// YumeProof Token OTW (One Time Witness)
    struct YUMEPROOF has drop {}

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

        // Transfer capabilities to sender
        transfer::public_transfer(treasury_cap, ctx.sender());
        transfer::public_freeze_object(coin_metadata);
    }

    /// Mint new tokens
    public fun mint(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        amount: u64,
        ctx: &mut TxContext
    ): Token<YUMEPROOF> {
        token::mint(treasury_cap, amount, ctx)
    }

    /// Burn tokens
    public fun burn(
        treasury_cap: &mut TreasuryCap<YUMEPROOF>,
        token: Token<YUMEPROOF>
    ): u64 {
        let balance = token::into_balance(token);
        let amount = balance::value(&balance);
        token::burn_balance(treasury_cap, balance);
        amount
    }
}


