class Query
  include Enumerable

  def execute(sql)
    res = ActiveRecord::Base.connection.exec_query(sql)

    res.to_a.map do |row|
      row.map do |name, value|
        [name, res.column_type(name).type_cast(value)]
      end.to_h
    end
  end
end
