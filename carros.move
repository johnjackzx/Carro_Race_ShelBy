module carros::carro_race {
    use std::string::{Self, String};
    use std::option;
    use std::signer;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::aptos_token::{Self, Token};
    use aptos_framework::randomness;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    // Car stats resource (attached to each NFT)
    struct CarStats has key, store {
        speed: u64,
        handling: u64,
        ai_boost: u64,
    }

    // Race event
    struct RaceEvent has drop, store {
        car1: Object<Token>,
        car2: Object<Token>,
        winner: Object<Token>,
    }

    // Create the Car collection (call once by deployer)
    public entry fun create_collection(creator: &signer) {
        let description = string::utf8(b"Carro Race - AI Powered Cars on Aptos + Shelby Storage");
        let name = string::utf8(b"Carro Race Cars");
        let uri = string::utf8(b"https://shelby.xyz/your-collection-metadata"); // point to Shelby-hosted metadata

        aptos_token::create_collection(
            creator,
            name,
            description,
            uri,
            option::none(), // max supply unlimited
            option::none()  // no royalty for simplicity
        );
    }

    // Mint a Car NFT (anyone can mint)
    public entry fun mint_carro(
        player: &signer,
        name: String,
        description: String,
        uri: String,           // e.g. "https://your-shelby-object-url/car-render.png"
        speed: u64,
        handling: u64,
        ai_boost: u64
    ) {
        let constructor_ref = aptos_token::create_named_token(
            player,
            string::utf8(b"Carro Race Cars"), // collection name
            description,
            name,
            option::none(),
            uri
        );

        let token_obj = object::object_from_constructor_ref<Token>(&constructor_ref);

        // Attach stats
        let stats = CarStats { speed, handling, ai_boost };
        move_to(&object::generate_signer_for_extending(&constructor_ref), stats);
    }

    // Simple 1v1 race (uses Aptos on-chain randomness)
    public entry fun start_race(
        player1: &signer,
        player2: &signer,
        car1_obj: Object<Token>,
        car2_obj: Object<Token>
    ) acquires CarStats {
        // Verify ownership (basic check - expand as needed)
        assert!(object::is_owner(car1_obj, signer::address_of(player1)), 1);
        assert!(object::is_owner(car2_obj, signer::address_of(player2)), 2);

        let stats1 = borrow_global<CarStats>(object::object_address(&car1_obj));
        let stats2 = borrow_global<CarStats>(object::object_address(&car2_obj));

        // Randomness seed (Aptos built-in)
        let random = randomness::u64_range(0, 100);

        // Score calculation
        let score1 = stats1.speed * 40 + stats1.handling * 30 + stats1.ai_boost * 30 + random;
        let score2 = stats2.speed * 40 + stats2.handling * 30 + stats2.ai_boost * 30 + (100 - random);

        let winner = if (score1 >= score2) { car1_obj } else { car2_obj };

        // Emit event (for frontend)
        // You can add event emission here if desired

        // Reward winner with 0.1 APT (example - adjust)
        let reward = 10000000; // 0.1 APT in octas
        coin::transfer<AptosCoin>(player1, signer::address_of(player2), reward); // simplistic - use proper escrow in production
    }
}
