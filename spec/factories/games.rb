FactoryBot.define do
  factory :game do
    current_phase { 'pre-flop' }
    current_turn { 1 }
    pot { 0 }
    community_cards { [] }
    deck { [] }

    trait :with_winner do
      winner_player { { id: 1, name: "Player 1", chips: 1000 } }
    end
  end
end
