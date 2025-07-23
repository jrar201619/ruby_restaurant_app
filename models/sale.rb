# models/sale.rb
# Definición del modelo Sale.

require 'active_record'
require_relative 'product' # Asegúrate de que Product esté cargado

class Sale < ActiveRecord::Base
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0, message: "debe ser un número entero mayor que cero." }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0, message: "debe ser un número positivo o cero." }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0, message: "debe ser un número positivo o cero." }
  belongs_to :product

  # Callback para actualizar el stock del producto después de crear una venta
  after_create :decrease_product_stock

  private

  def decrease_product_stock
    product.with_lock do # Bloquea el producto para evitar condiciones de carrera
      if product.stock >= self.quantity
        product.stock -= self.quantity
        product.save!
      else
        # Esto debería ser manejado antes de crear la venta en la GUI,
        # pero es una capa de seguridad. Podrías lanzar una excepción aquí.
        raise ActiveRecord::Rollback, "Stock insuficiente para el producto #{product.name}."
      end
    end
  end
end
