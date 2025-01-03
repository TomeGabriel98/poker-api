module Errors
  class UnauthorizedGameOperationError < StandardError
    attr_reader :details

    def initialize(message = "Operação não permitida", details = {})
      super(message)
      @details = details
    end
  end
end
