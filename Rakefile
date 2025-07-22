# ruby_restaurant_app/Rakefile
require 'bundler/setup' # Asegura que Bundler cargue las gemas
Bundler.require(:default, ENV['RACK_ENV'] || :development) # Carga todas las gemas del Gemfile

require 'active_record' # Asegura que ActiveRecord esté cargado explícitamente
require 'rake'
require 'fileutils' # Para FileUtils.mkdir_p

# Configuración de la base de datos para Rake
# Asegúrate de que esta configuración coincida con la de main.rb
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/restaurant.sqlite3'
)

# Configura las rutas de las migraciones para ActiveRecord::Tasks
ActiveRecord::Tasks::DatabaseTasks.migrations_paths = File.expand_path('db/migrate', __dir__)
ActiveRecord::Tasks::DatabaseTasks.db_dir = File.expand_path('db', __dir__) # Necesario para algunas tareas

namespace :db do
  desc "Migrate the database"
  task :migrate do
    # Corrección: Usar ActiveRecord::Tasks::DatabaseTasks.migrate directamente
    # Esta es la forma estándar y más robusta de ejecutar migraciones en Rake.
    ActiveRecord::Tasks::DatabaseTasks.migrate
    puts "Database migrated successfully!"
  end

  desc "Create the database file (if it doesn't exist)"
  task :create do
    db_path = 'db/restaurant.sqlite3'
    FileUtils.mkdir_p(File.dirname(db_path)) unless File.directory?(File.dirname(db_path))
    # ActiveRecord::Tasks::DatabaseTasks.create_current # Otra forma de crear la DB si es necesario
    # ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'sqlite3:db/restaurant.sqlite3')
    # ActiveRecord::Base.connection # Esto crea el archivo si no existe
    puts "Database created (o ya existe) at #{db_path}"
  end

  desc "Drop the database file"
  task :drop do
    db_path = 'db/restaurant.sqlite3'
    if File.exist?(db_path)
      File.delete(db_path)
      puts "Database dropped: #{db_path}"
    else
      puts "Database does not exist: #{db_path}"
    end
  end
end
