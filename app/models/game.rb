class Game < ApplicationRecord
	attr_accessor :deck

	after_initialize :initialize_custom_attributes

	def build_deck
    suits = %w[hearts diamonds clubs spades]
    values = %w[A K Q J 10 9 8 7 6 5 4 3 2]
    suits.product(values).map { |suit, value| Card.create_card(value, suit) }
  end

	private

	def initialize_custom_attributes
		self.current_phase ||= 'pre-flop'
		self.current_turn ||= 1
		self.pot ||= 0
	end
end
