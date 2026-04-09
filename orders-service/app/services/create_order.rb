class CreateOrder
  def call(params)
    items = params[:items] || []
    raise ArgumentError, "Order must have at least one item" if items.empty?

    total_amount = items.sum { |item| item[:quantity].to_i * item[:unit_price].to_f }

    order = ActiveRecord::Base.transaction do
      order = Order.create!(status: "CREATED", total_amount: total_amount)

      items.each do |item|
        order.order_items.create!(
          product_id: item[:product_id],
          quantity: item[:quantity].to_i,
          unit_price: item[:unit_price].to_f
        )
      end

      order
    end

    EventPublisher.publish_reserve_stock_requested(order)

    order.as_json(include: :order_items)
  end
end
