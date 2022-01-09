%i[
left_paran right_paran left_brace right_brace
comma dot minus plus semicolon slash star

bang bang_equal equal equal_equal
greater greater_equal less less_equal

identifier string number

and class else false fun for if nil or
print return super this true var while

eof
].each.with_index do |sym, idx| 
  Lox::Token.const_set(sym.upcase, sym)
end
