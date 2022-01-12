module Lox
  keywords = %i[
    and class else false fun for if nil or
    print return super this true var while
  ]

  Keywords = keywords.map do |kw|
    const = Token.const_set(kw.upcase, kw.to_sym)
    [kw.to_s, const]
  end.to_h
end
