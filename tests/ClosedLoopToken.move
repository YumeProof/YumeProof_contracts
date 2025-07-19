#[test_only]
module yumeproof_contracts::ClosedLoopToken_tests {
    use std::vector;
    use iota::tx_context::{Self, TxContext};
    use iota::test_utils::TestUtilsScenario;
    use yumeproof_contracts::ClosedLoopToken::{Self, YUMEPROOF};

    // Error constants matching the main contract
    const ENoConfig: u64 = 0;
    const ESenderNotAShop: u64 = 1;
    const ESenderIsAShop: u64 = 2;
    const ERecipientNotAShop: u64 = 3;

    // Test addresses
    const ADMIN: address = @0xAD;
    const SHOP1: address = @0xSH1;
    const SHOP2: address = @0xSH2;
    const USER1: address = @0xU1;
    const USER2: address = @0xU2;

    #[test]
    fun test_init_and_mint() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize the module
        ClosedLoopToken::init(YUMEPROOF {}, ctx);

        // TODO: Add assertions to verify initialization
        TestUtilsScenario::end(scenario);
    }

    #[test]
    fun test_register_shop() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize
        ClosedLoopToken::init(YUMEPROOF {}, ctx);

        // Register shops
        let shops = vector::empty<address>();
        vector::push_back(&mut shops, SHOP1);
        vector::push_back(&mut shops, SHOP2);

        // TODO: Call register_shop and verify registration

        TestUtilsScenario::end(scenario);
    }

    #[test]
    fun test_gift_token() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize
        ClosedLoopToken::init(YUMEPROOF {}, ctx);

        // TODO: Test gifting tokens to users

        TestUtilsScenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ESenderIsAShop)]
    fun test_shop_cannot_transfer() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize
        ClosedLoopToken::init(YUMEPROOF {}, ctx);

        // TODO: Test that shops cannot transfer tokens

        TestUtilsScenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ERecipientNotAShop)]
    fun test_transfer_to_non_shop_fails() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize
        ClosedLoopToken::init(YUMEPROOF {}, ctx);

        // TODO: Test that transfers to non-shops fail

        TestUtilsScenario::end(scenario);
    }

    #[test]
    fun test_return_token() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize
        ClosedLoopToken::init(YUMEPROOF {}, ctx);

        // TODO: Test token return flow from shop to treasury

        TestUtilsScenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ESenderNotAShop)]
    fun test_non_shop_cannot_return() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize
        ClosedLoopToken::init(YUMEPROOF {}, ctx);

        // TODO: Test that non-shops cannot return tokens

        TestUtilsScenario::end(scenario);
    }
}
