module MyModule::CommunityRewards {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;

    /// Struct representing a user's reward balance in the community
    struct RewardBalance has store, key {
        available_rewards: u64,  // Total unclaimed reward tokens
        total_earned: u64,       // Lifetime rewards earned
    }

    /// Struct for the community admin to manage the reward pool
    struct CommunityPool has store, key {
        total_pool: u64,         // Total tokens available for rewards
        members: vector<address>, // List of community members
    }

    /// Function for community admin to issue rewards to a member
    public fun issue_reward(
        admin: &signer, 
        member_address: address, 
        reward_amount: u64
    ) acquires RewardBalance, CommunityPool {
        let admin_addr = signer::address_of(admin);
        
        // Ensure admin has a community pool
        let pool = borrow_global_mut<CommunityPool>(admin_addr);
        assert!(pool.total_pool >= reward_amount, 1);
        
        // Deduct from admin's pool
        pool.total_pool = pool.total_pool - reward_amount;
        
        // Initialize member's rewards if they don't exist
        if (!exists<RewardBalance>(member_address)) {
            let new_balance = RewardBalance {
                available_rewards: reward_amount,
                total_earned: reward_amount,
            };
            move_to(admin, new_balance);
        } else {
            let member_rewards = borrow_global_mut<RewardBalance>(member_address);
            member_rewards.available_rewards = member_rewards.available_rewards + reward_amount;
            member_rewards.total_earned = member_rewards.total_earned + reward_amount;
        };
    }

    /// Function for members to claim their available rewards
    public fun claim_rewards(member: &signer) acquires RewardBalance {
        let member_addr = signer::address_of(member);
        let rewards = borrow_global_mut<RewardBalance>(member_addr);
        
        assert!(rewards.available_rewards > 0, 2);
        
        let claim_amount = rewards.available_rewards;
        rewards.available_rewards = 0;
        
        // Transfer claimed tokens to member
        let reward_coins = coin::withdraw<AptosCoin>(member, claim_amount);
        coin::deposit<AptosCoin>(member_addr, reward_coins);
    }
}