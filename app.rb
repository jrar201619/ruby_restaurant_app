# app.rb

puts "--- DEBUGGING TK LOADING ---"
begin
  require 'tk'
  puts "1. 'tk' gem required successfully."
  puts "   Defined Tk::Root? #{defined?(Tk::Root)}"
  puts "   Defined Tk::Frame? #{defined?(Tk::Frame)}"
  puts "   Defined Tk::Label? #{defined?(Tk::Label)}"

  # Intenta cargar tk/variable explícitamente aquí de nuevo
  require 'tk/variable'
  puts "2. 'tk/variable' required successfully."
  puts "   Defined Tk::Variable? #{defined?(Tk::Variable)}"
  puts "   Defined Tk::StringVar? #{defined?(Tk::StringVar)}"
  puts "   Defined Tk::OptionMenu? #{defined?(Tk::OptionMenu)}" # OptionMenu a menudo depende de variables

rescue LoadError => e
  puts "ERROR: Could not require a Tk component: #{e.message}"
  exit # Salimos para ver el error de carga inmediatamente
rescue NameError => e
  puts "ERROR: NameError during Tk component check: #{e.message}"
  exit
end
puts "--- END DEBUGGING TK LOADING ---"


require 'bundler/setup' # Asegura que Bundler cargue las gemas correctas
# ... el resto de tu app.rb
require_relative 'config/database'
require_relative 'db/migrate'
require_relative 'models/category'
require_relative 'models/product'
require_relative 'models/sale'
require_relative 'gui/restaurant_app'

restaurant_app_instance = RestaurantApp.new
restaurant_app_instance.run