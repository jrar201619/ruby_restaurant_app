# models/product.rb
# Definición del modelo Product.

require 'active_record'
require_relative 'category' # Asegúrate de que Category esté cargado

class Product < ActiveRecord::Base
  validates :name, presence: true, uniqueness: { scope: :category_id, message: "ya existe en esta categoría." }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, message: "debe ser un número positivo o cero." }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "debe ser un número entero positivo o cero." }
  belongs_to :category
  has_many :sales # Un producto puede tener muchas ventas
end
