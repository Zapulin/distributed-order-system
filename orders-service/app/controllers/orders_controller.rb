class OrdersController < ApplicationController
  def create
    result = CreateOrder.new.call(order_params)
    render json: result, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def show
    order = Order.includes(:order_items).find(params[:id])
    render json: order.as_json(include: :order_items)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Order not found" }, status: :not_found
  end

  private

  def order_params
    params.require(:order).permit(items: [ :product_id, :quantity, :unit_price ])
  end
end
