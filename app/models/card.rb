class Card < ApplicationRecord
  enum suit: [ :hearts, :diamonds, :clubs, :spades ]

  validates :value, presence: true
  validates :suit, presence: true, inclusion: { in: suites.keys }
  validates :identifier, presence: true

end
