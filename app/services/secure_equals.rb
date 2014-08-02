module SecureEquals
  def self.secure_equals(first, second)
    return false if first.nil? || second.nil? || first.bytesize != second.bytesize

    same = true

    first.bytes.zip(second.bytes) do |b1, b2|
      same = false if b1 != b2
    end

    same
  end
end
