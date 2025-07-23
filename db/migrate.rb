# db/migrate.rb
# Lógica para asegurar que la base de datos y sus tablas existan.

require 'active_record'
require 'fileutils'
require_relative '../config/database' # Carga la configuración de la base de datos

# Asegurarse de que las migraciones se ejecuten si la base de datos no existe o no tiene la estructura correcta
# Se usa un esquema de versión para simular migraciones simples.
# En un entorno de producción, usarías herramientas de migración de Rails o similar.
unless File.exist?('db/restaurant.sqlite3') && ActiveRecord::Base.connection.table_exists?('categories') && ActiveRecord::Base.connection.table_exists?('products') && ActiveRecord::Base.connection.table_exists?('sales')
  puts "Base de datos no encontrada o tablas incompletas. Ejecutando migraciones..."
  ActiveRecord::Schema.define(version: 20240722120000) do # Nueva versión para incluir 'sales' y 'stock'
    unless ActiveRecord::Base.connection.table_exists?(:categories)
      create_table :categories do |t|
        t.string :name, null: false, unique: true
        t.timestamps
      end
    end

    unless ActiveRecord::Base.connection.table_exists?(:products)
      create_table :products do |t|
        t.string :name, null: false
        t.text :description # Añadido campo de descripción
        t.decimal :price, precision: 10, scale: 2, null: false # Mayor precisión para precios
        t.integer :stock, default: 0, null: false # Añadido campo de stock
        t.references :category, null: false, foreign_key: true
        t.timestamps
      end
    end

    unless ActiveRecord::Base.connection.table_exists?(:sales)
      create_table :sales do |t|
        t.references :product, null: false, foreign_key: true
        t.integer :quantity, null: false
        t.decimal :unit_price, precision: 10, scale: 2, null: false
        t.decimal :total_price, precision: 10, scale: 2, null: false
        t.datetime :sale_date, null: false, default: -> { 'CURRENT_TIMESTAMP' }
        t.timestamps
      end
    end
  end
  puts "Migraciones completadas."
else
  puts "Base de datos existente y tablas verificadas."
end
