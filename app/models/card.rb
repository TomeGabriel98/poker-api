class Card < ApplicationRecord
  def self.create_card(value, suit)
    identifier = "#{value}#{suit[0].upcase}"
    new(value: value, suit: suit, identifier: identifier)
  end
end
