#[test_only]
module yumeproof_contracts::ClosedLoopToken_tests;

use iota::coin::{Self, TreasuryCap, Coin};
use iota::test_utils::TestUtilsScenario;
use iota::token::{Self, Token, TokenPolicy, TokenPolicyCap};
use iota::tx_context::{Self, TxContext};
use std::assert;
use yumeproof_contracts::ClosedLoopToken::{
    Self,
    CLOSEDLOOPTOKEN,
    YUMEPROOF,
    NotarizationPolicy,
    get_credit_price,
    purchase_credits_with_iota,
    use_credits,
    is_notarization_service,
    register_notarization_service
};

// Error constant
const EIncorrectPayment: u64 = 2;

// Test identities
const ADMIN: address = @0xA1;
const USER1: address = @0xB1;
const SERVICE: address = @0xC1;
const UNKNOWN: address = @0xD1;

#[test]
fun test_init() {
    let scenario = TestUtilsScenario::begin(ADMIN);
    let ctx = TestUtilsScenario::ctx(&mut scenario);

    ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

    // If no panic, init successful
    TestUtilsScenario::end(scenario);
}

#[test]
fun test_purchase_and_use_credits() {
    let scenario = TestUtilsScenario::begin(USER1);
    let ctx = TestUtilsScenario::ctx(&mut scenario);

    TestUtilsScenario::with_actor(ctx, ADMIN);
    ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);
    TestUtilsScenario::with_actor(ctx, USER1);

    let treasury_cap = TestUtilsScenario::owned<TreasuryCap<YUMEPROOF>>(ctx, 0);
    let coin = TestUtilsScenario::coin<YUMEPROOF>(get_credit_price() * 3, ctx);

    purchase_credits_with_iota(&mut treasury_cap, coin, ctx);

    let token = TestUtilsScenario::owned<Token<YUMEPROOF>>(ctx, 1);
    let policy = TestUtilsScenario::shared_ref<TokenPolicy<YUMEPROOF>>(ctx, 0);

    let _req = use_credits(token, policy, 2, ctx);

    TestUtilsScenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = EIncorrectPayment)]
fun test_purchase_too_little() {
    let scenario = TestUtilsScenario::begin(USER1);
    let ctx = TestUtilsScenario::ctx(&mut scenario);

    TestUtilsScenario::with_actor(ctx, ADMIN);
    ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);
    TestUtilsScenario::with_actor(ctx, USER1);

    let treasury_cap = TestUtilsScenario::owned<TreasuryCap<YUMEPROOF>>(ctx, 0);
    let too_small = TestUtilsScenario::coin<YUMEPROOF>(get_credit_price() / 2, ctx);

    purchase_credits_with_iota(&mut treasury_cap, too_small, ctx);

    TestUtilsScenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = EIncorrectPayment)]
fun test_spend_too_much_credits() {
    let scenario = TestUtilsScenario::begin(USER1);
    let ctx = TestUtilsScenario::ctx(&mut scenario);

    TestUtilsScenario::with_actor(ctx, ADMIN);
    ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);
    TestUtilsScenario::with_actor(ctx, USER1);

    let treasury_cap = TestUtilsScenario::owned<TreasuryCap<YUMEPROOF>>(ctx, 0);
    let coin = TestUtilsScenario::coin<YUMEPROOF>(get_credit_price(), ctx);

    purchase_credits_with_iota(&mut treasury_cap, coin, ctx);

    let token = TestUtilsScenario::owned<Token<YUMEPROOF>>(ctx, 1);
    let policy = TestUtilsScenario::shared_ref<TokenPolicy<YUMEPROOF>>(ctx, 0);

    let _req = use_credits(token, policy, 5, ctx); // Too much

    TestUtilsScenario::end(scenario);
}

#[test]
fun test_register_and_check_service() {
    let scenario = TestUtilsScenario::begin(ADMIN);
    let ctx = TestUtilsScenario::ctx(&mut scenario);

    ClosedLoopToken::init(CLOSEDLOOPTOKEN {}, ctx);

    let policy = TestUtilsScenario::shared_ref<TokenPolicy<YUMEPROOF>>(ctx, 0);
    let cap = TestUtilsScenario::owned<TokenPolicyCap<YUMEPROOF>>(ctx, 0);

    register_notarization_service(policy, &cap, SERVICE, ctx);

    assert!(is_notarization_service(policy, SERVICE), 100);
    assert!(!is_notarization_service(policy, UNKNOWN), 101);

    TestUtilsScenario::end(scenario);
}
