# ruby_restaurant_app/db/migrate/20230101000000_create_categories_and_products.rb
class CreateCategoriesAndProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false, unique: true
      t.timestamps
    end

    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 8, scale: 2, null: false
      t.references :category, null: false, foreign_key: true
      t.timestamps
    end
  end
end
