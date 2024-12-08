class Token
  attr_reader :lexeme, :token_type, :line

  def initialize(token_type, lexeme, line)
    @token_type = token_type
    @lexeme = lexeme
    @line = line
  end

  def print
    "[#{@token_type}], #{@lexeme}, line: #{@line}"
  end
end