module Lox
  %i[
  left_paren right_paren left_brace right_brace
  comma dot minus plus semicolon slash star

  bang bang_equal equal equal_equal
  greater greater_equal less less_equal

  identifier string number

  eof
  ].each.with_index do |sym, idx| 
    Token.const_set(sym.upcase, sym)
  end
end
