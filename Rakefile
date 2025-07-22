# ruby_restaurant_app/Rakefile
require 'active_record'
require 'active_record/tasks'
require 'rake'
require 'fileutils' # Para FileUtils.mkdir_p

# Configuración de la base de datos para Rake
# Asegúrate de que esta configuración coincida con la de main.rb
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/restaurant.sqlite3'
)

namespace :db do
  desc "Migrate the database"
  task :migrate do
    ActiveRecord::MigrationContext.new(File.expand_path('db/migrate', __dir__), ActiveRecord::Base.connection.schema_migration).migrate
    puts "Database migrated successfully!"
  end

  desc "Create the database file (if it doesn't exist)"
  task :create do
    db_path = 'db/restaurant.sqlite3'
    FileUtils.mkdir_p(File.dirname(db_path)) unless File.directory?(File.dirname(db_path))
    # ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'sqlite3:db/restaurant.sqlite3')
    # ActiveRecord::Base.connection # Esto crea el archivo si no existe
    puts "Database created (or already exists) at #{db_path}"
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