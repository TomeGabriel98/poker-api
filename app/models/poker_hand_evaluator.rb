class PokerHandEvaluator
	attr_reader :cards

	HAND_RANKS = {
    royal_flush: {rank: 10, hand: "royal_flush"},
    straight_flush: {rank: 9, hand:"straight_flush"},
    four_of_a_kind: {rank: 8, hand: "four_of_a_kind"},
    full_house: {rank: 7, hand: "full_house"},
    flush: {rank: 6, hand: "flush"},
    straight: {rank: 5, hand: "straight"},
    three_of_a_kind: {rank: 4, hand: "three_of_a_kind"},
    two_pair: {rank: 3, hand: "two_pair"},
    pair: {rank: 2, hand: "pair"},
    high_card: {rank: 1, hand: "high_card"}
  }

	def initialize(cards)
		@cards = cards
	end

	def rank
		if royal_flush?
			return HAND_RANKS[:royal_flush]
		elsif straight_flush?
			return HAND_RANKS[:straight_flush]
		elsif four_of_a_kind?
			return HAND_RANKS[:four_of_a_kind]
    elsif full_house?
      return HAND_RANKS[:full_house]
    elsif flush?
      return HAND_RANKS[:flush]
    elsif straight?
      return HAND_RANKS[:straight]
    elsif three_of_a_kind?
      return HAND_RANKS[:three_of_a_kind]
    elsif two_pair?
      return HAND_RANKS[:two_pair]
    elsif pair?
      return HAND_RANKS[:pair]
    else
      return HAND_RANKS[:high_card]
    end
	end

	private

	def royal_flush?
		values = cards.map { |card| rank_value(card["value"]) }.uniq.sort
		return true if values.each_cons(5).any? { |sequence| sequence.last - sequence.first == 4 }
	
		values.include?(14) && values.include?(2) && values.include?(3) && values.include?(4) && values.include?(5)
  end

  def straight_flush?
    flush? && straight?
  end

  def four_of_a_kind?
    grouped_ranks.any? { |_rank, group| group.size == 4 }
  end

  def full_house?
    grouped_ranks.size == 2 && grouped_ranks.values.sort == [2, 3]
  end

  def flush?
		suits = cards.map{ |card| card["suit"] }
    suits.group_by { |suit| suit }.values.any? { |group| group.size >= 5 }
  end

  def straight?
		values = cards.map { |card| rank_value(card["value"]) }.uniq.sort
		return true if values.each_cons(5).any? { |sequence| sequence.last - sequence.first == 4 }
	
		values.include?(14) && values.include?(2) && values.include?(3) && values.include?(4) && values.include?(5)
  end

  def three_of_a_kind?
    grouped_ranks.any? { |_rank, group| group.size == 3 }
  end

  def two_pair?
    grouped_ranks.select { |_rank, group| group.size == 2 }.size == 2
  end

  def pair?
    grouped_ranks.any? { |_rank, group| group.size == 2 }
  end

  def grouped_ranks
    cards.group_by{ |card| card["value"] }
  end

	def rank_value(value)
		case value
		when 'A' then 14
		when 'K' then 13
		when 'Q' then 12
		when 'J' then 11
		else
			value.to_i
		end
	end
end
