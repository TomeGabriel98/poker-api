FactoryBot.define do
  factory :room do
    active_game { false }
    current_players { [] }
    current_player_turn { nil }
  end
end
