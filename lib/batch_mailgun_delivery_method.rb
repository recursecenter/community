class BatchMailgunDeliveryMethod
  def initialize(values)
    p "+++++++++++++"
    p values
  end

  def deliver!(mail)
    p "!!!!!!!!!!!!!"
    p mail
  end
end
