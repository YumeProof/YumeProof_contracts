#[test_only]
module yumeproof_contracts::ClosedLoopToken_tests {
    use iota::test_utils::TestUtilsScenario;
    use iota::tx_context::TxContext;
    use iota::token::{Token, TokenPolicy};
    use iota::coin::{TreasuryCap, Coin};
    use std::assert;
    use yumeproof_contracts::ClosedLoopToken::{
        CLOSEDLOOPTOKEN, YUMEPROOF, NotarizationPolicy, get_credit_price, is_notarization_service
    };

    // Error code from contract
    const EIncorrectPayment: u64 = 2;

    // Actors
    const ADMIN: address = @0xA;
    const USER1: address = @0x1;
    const SERVICE1: address = @0xS1;
    const NON_SERVICE: address = @0xE1;

    #[test]
    fun test_init() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);

        // Initialize the contract
        yumeproof_contracts::ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

        TestUtilsScenario::end(scenario);
    }

    #[test]
    fn test_purchase_credits_with_iota() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);
        yumeproof_contracts::ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

        // Extract TreasuryCap and create payment
        let treasury_cap = TestUtilsScenario::owned<TreasuryCap<YUMEPROOF>>(ctx, 0);
        let payment = TestUtilsScenario::coin<YUMEPROOF>(get_credit_price(), ctx);

        // Purchase credits
        yumeproof_contracts::ClosedLoopToken::purchase_credits_with_iota(
            &mut treasury_cap, payment, ctx
        );

        // Token should now exist in sender's account
        let _token = TestUtilsScenario::owned<Token<YUMEPROOF>>(ctx, 1);

        TestUtilsScenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectPayment)]
    fn test_purchase_too_little() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);
        yumeproof_contracts::ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

        let treasury_cap = TestUtilsScenario::owned<TreasuryCap<YUMEPROOF>>(ctx, 0);
        let payment = TestUtilsScenario::coin<YUMEPROOF>(500_000, ctx); // half price

        // Should abort due to insufficient value
        yumeproof_contracts::ClosedLoopToken::purchase_credits_with_iota(
            &mut treasury_cap, payment, ctx
        );

        TestUtilsScenario::end(scenario);
    }

    #[test]
    fn test_use_credits_success() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);
        yumeproof_contracts::ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

        let treasury_cap = TestUtilsScenario::owned<TreasuryCap<YUMEPROOF>>(ctx, 0);
        let payment = TestUtilsScenario::coin<YUMEPROOF>(get_credit_price() * 5, ctx);
        yumeproof_contracts::ClosedLoopToken::purchase_credits_with_iota(
            &mut treasury_cap, payment, ctx
        );

        let token = TestUtilsScenario::owned<Token<YUMEPROOF>>(ctx, 1);
        let policy = TestUtilsScenario::shared_ref<TokenPolicy<YUMEPROOF>>(ctx, 0);

        // Spend 3 credits
        let _req = yumeproof_contracts::ClosedLoopToken::use_credits(
            token, policy, 3, ctx
        );

        TestUtilsScenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectPayment)]
    fn test_use_credits_fail() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);
        yumeproof_contracts::ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

        let treasury_cap = TestUtilsScenario::owned<TreasuryCap<YUMEPROOF>>(ctx, 0);
        let payment = TestUtilsScenario::coin<YUMEPROOF>(get_credit_price() * 1, ctx);
        yumeproof_contracts::ClosedLoopToken::purchase_credits_with_iota(
            &mut treasury_cap, payment, ctx
        );

        let token = TestUtilsScenario::owned<Token<YUMEPROOF>>(ctx, 1);
        let policy = TestUtilsScenario::shared_ref<TokenPolicy<YUMEPROOF>>(ctx, 0);

        // Try to spend 5 credits with only 1 available
        let _req = yumeproof_contracts::ClosedLoopToken::use_credits(
            token, policy, 5, ctx
        );

        TestUtilsScenario::end(scenario);
    }

    #[test]
    fn test_register_and_check_service() {
        let scenario = TestUtilsScenario::begin(ADMIN);
        let ctx = TestUtilsScenario::ctx(&mut scenario);
        yumeproof_contracts::ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

        let cap = TestUtilsScenario::owned<TokenPolicyCap<YUMEPROOF>>(ctx, 0);
        let policy = TestUtilsScenario::shared_ref<TokenPolicy<YUMEPROOF>>(ctx, 0);

        yumeproof_contracts::ClosedLoopToken::register_notarization_service(
            policy, &cap, SERVICE1, ctx
        );

        assert!(is_notarization_service(policy, SERVICE1), 101);
        assert!(!is_notarization_service(policy, NON_SERVICE), 102);

        TestUtilsScenario::end(scenario);
    }
}
