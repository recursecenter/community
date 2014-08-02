module SecureEquals
  def self.secure_equals(first, second)
    return false if first.nil? || second.nil? || first.size != second.size

    same = true

    first.chars.zip(second.chars) do |c1, c2|
      same = false if c1 != c2
    end

    same
  end
end
