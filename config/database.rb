# config/database.rb
# Configuración de la base de datos para la aplicación.
require 'logger'

require 'active_record'
require 'fileutils'

# Asegúrate de que el directorio 'db' exista
FileUtils.mkdir_p('db') unless File.directory?('db')

# Establece la conexión a la base de datos SQLite
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/restaurant.sqlite3'
)
