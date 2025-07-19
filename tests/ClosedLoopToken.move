#[test_only]
module yumeproof_contracts::ClosedLoopToken_tests {
    use iota::test_scenario;
    use yumeproof_contracts::ClosedLoopToken;


    use iota::coin::{TreasuryCap, Coin};
    


    const ADMIN: address = @0xA1;
    const USER: address = @0xB1;

    #[test]
    public fun test_init_closed_loop_token() {
        let mut scenario = test_scenario::begin(ADMIN);

        // First transaction: initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };


        // tx 2: user purchases credits
        test_scenario::next_tx(&mut scenario, USER);
        {
            // take TreasuryCap<YUMEPROOF> owned by ADMIN
            let mut treasury = test_scenario::take_from_address<TreasuryCap<ClosedLoopToken::YUMEPROOF>>(&scenario, ADMIN);

            // Mint credits by directly calling your `purchase_credits_with_iota` or similar function
        let coin = test_scenario::mint_coin<ClosedLoopToken::YUMEPROOF>(&mut scenario, 1_000_000 * 1000); // mint IOTA for 1000 credits worth
            
            
            
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::purchase_credits_with_iota(&mut treasury, coin, ctx);

            test_scenario::return_to_address(ADMIN, treasury);
        };


        test_scenario::end(scenario);
    }
}
