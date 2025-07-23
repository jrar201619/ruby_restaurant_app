# models/category.rb
# Definición del modelo Category.

require 'active_record'

class Category < ActiveRecord::Base
  validates :name, presence: true, uniqueness: { message: "ya existe. Por favor, elige otro nombre." }
  has_many :products, dependent: :destroy # Si se borra una categoría, sus productos también se borran
end
