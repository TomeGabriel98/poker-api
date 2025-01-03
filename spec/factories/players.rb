FactoryBot.define do
  factory :player do
    sequence(:name) { |n| "Player #{n}" }
    chips { 100 }
    current_bet { 0 }
    hand { [] }
  end
end
