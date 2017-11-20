module Utilities

  def symbolize_keys(hash)
    hash.inject({}) do | memo, (k,v) |
      memo[k.to_sym] = v
      memo
    end
  end
end