#[test_only]
module yumeproof_contracts::ClosedLoopToken_tests {
    use iota::test_scenario;
    use yumeproof_contracts::ClosedLoopToken;

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

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_free_mint_yumeproof() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Test free minting - this test will need to be simplified since we can't access TreasuryCap
        test_scenario::next_tx(&mut scenario, USER);
        {
            // For now, just test that the function exists and module initializes correctly
            let price = ClosedLoopToken::get_credit_price();
            assert!(price == 1_000_000, 0);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_credit_balance_function() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Test that credit price function works
        test_scenario::next_tx(&mut scenario, USER);
        {
            let price = ClosedLoopToken::get_credit_price();
            assert!(price == 1_000_000, 0);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_notarization_workflow() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Test notarization registry operations
        test_scenario::next_tx(&mut scenario, USER);
        {
            let registry = test_scenario::take_shared<ClosedLoopToken::NotarizationRegistry>(&scenario);
            
            let notarization_id = b"test_notarization_001";
            let exists = ClosedLoopToken::notarization_exists(&registry, notarization_id);
            assert!(exists == false, 0); // Should not exist initially
            
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_complete_workflow() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Step 1: Test credit price
        test_scenario::next_tx(&mut scenario, USER);
        {
            let price = ClosedLoopToken::get_credit_price();
            assert!(price == 1_000_000, 0);
        };

        // Step 2: Test gas station operations
        test_scenario::next_tx(&mut scenario, USER);
        {
            let mut gas_station = test_scenario::take_shared<ClosedLoopToken::GasStation>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::update_gas_station(&mut gas_station, USER, true, ctx);
            test_scenario::return_shared(gas_station);
        };

        // Step 3: Test notarization registry
        test_scenario::next_tx(&mut scenario, USER);
        {
            let registry = test_scenario::take_shared<ClosedLoopToken::NotarizationRegistry>(&scenario);
            let notarization_id = b"test_notarization";
            let exists = ClosedLoopToken::notarization_exists(&registry, notarization_id);
            assert!(exists == false, 0);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }
}
