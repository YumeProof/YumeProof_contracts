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
    public fun test_credit_price() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Get credit price
        test_scenario::next_tx(&mut scenario, USER);
        {
            let price = ClosedLoopToken::get_credit_price();
            assert!(price == 1_000_000, 0); // Should be 1M base units
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_gas_station_operations() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Update gas station configuration
        test_scenario::next_tx(&mut scenario, USER);
        {
            // Take GasStation shared object
            let mut gas_station = test_scenario::take_shared<ClosedLoopToken::GasStation>(&scenario);
            
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::update_gas_station(&mut gas_station, USER, true, ctx);

            test_scenario::return_shared(gas_station);
        };

        // Get gas station info
        test_scenario::next_tx(&mut scenario, USER);
        {
            // Take GasStation shared object
            let gas_station = test_scenario::take_shared<ClosedLoopToken::GasStation>(&scenario);
            
            let (sponsor, is_active) = ClosedLoopToken::get_gas_station_info(&gas_station);
            
            // Verify the values
            assert!(sponsor == USER, 0);
            assert!(is_active == true, 1);

            test_scenario::return_shared(gas_station);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_notarization_id_operations() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Test notarization ID operations
        test_scenario::next_tx(&mut scenario, USER);
        {
            // Take NotarizationRegistry shared object
            let registry = test_scenario::take_shared<ClosedLoopToken::NotarizationRegistry>(&scenario);
            
            let notarization_id = b"notarization_001";
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
