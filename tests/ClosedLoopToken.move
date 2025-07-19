#[test_only]
module yumeproof_contracts::ClosedLoopToken_tests {
    use iota::test_scenario;
    use yumeproof_contracts::ClosedLoopToken;

    const ADMIN: address = @0xA1;
    const USER: address = @0xB1;
    const DEVICE_DID: address = @0xC1;

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
    public fun test_device_verification_and_credentials() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Register device verification
        test_scenario::next_tx(&mut scenario, USER);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let verification_token = b"google_play_integrity_token";
            ClosedLoopToken::register_device_verification(DEVICE_DID, verification_token, ctx);
        };

        // Issue verifiable credentials
        test_scenario::next_tx(&mut scenario, USER);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let credentials_hash = b"device_credentials_hash";
            let valid_duration = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
            ClosedLoopToken::issue_verifiable_credentials(DEVICE_DID, credentials_hash, valid_duration, ctx);
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
    public fun test_device_verification_status() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Test device verification (placeholder implementation)
        test_scenario::next_tx(&mut scenario, USER);
        {
            let is_verified = ClosedLoopToken::is_device_verified(DEVICE_DID);
            assert!(is_verified == true, 0); // Placeholder returns true
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_credential_validation() {
        let mut scenario = test_scenario::begin(ADMIN);

        // Initialize module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            ClosedLoopToken::test_init(ctx);
        };

        // Test credential validation (placeholder implementation)
        test_scenario::next_tx(&mut scenario, USER);
        {
            let credentials_hash = b"test_credentials_hash";
            let current_time = 1000000; // Mock timestamp
            let is_valid = ClosedLoopToken::validate_credentials(DEVICE_DID, credentials_hash, current_time);
            assert!(is_valid == true, 0); // Placeholder returns true
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
}
