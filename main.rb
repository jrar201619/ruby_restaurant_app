# frozen_string_literal: true

require 'tk'
require 'active_record'
require 'fileutils'

# Configuración de la base de datos
# Asegúrate de que el directorio 'db' exista
FileUtils.mkdir_p('db') unless File.directory?('db')
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/restaurant.sqlite3'
)

# Definición de los modelos
# Modelo de Categoría
class Category < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  has_many :products, dependent: :destroy # Si se borra una categoría, sus productos también se borran
end

# Modelo de Producto
class Product < ActiveRecord::Base
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  belongs_to :category
end

# --- Interfaz Gráfica (Tk) ---

class RestaurantApp
  def initialize
    @root = TkRoot.new {
      title 'Aplicación de Restaurante'
      geometry '800x600'
      # Establece el tamaño mínimo y máximo de la ventana
      minsize(800, 600)
      maxsize(1200, 800)
    }

    # Frame principal para la navegación
    @main_frame = TkFrame.new(@root) {
      pack(fill: 'both', expand: true, padx: 10, pady: 10)
    }

    create_menu
    show_dashboard
  end

  # Crea la barra de menú
  def create_menu
    menubar = TkMenu.new(@root)

    file_menu = TkMenu.new(menubar, tearoff: false)
    file_menu.add('command', label: 'Salir', command: proc { exit })
    menubar.add('cascade', label: 'Archivo', menu: file_menu)

    manage_menu = TkMenu.new(menubar, tearoff: false)
    # Importante: Aquí se usan los 'proc' directamente.
    # Hemos añadido mensajes de depuración para ver si se llaman.
    manage_menu.add('command', label: 'Categorías', command: proc {
      puts "DEBUG: Menú 'Categorías' clicado." # Línea de depuración
      show_category_management
    })
    manage_menu.add('command', label: 'Productos', command: proc {
      puts "DEBUG: Menú 'Productos' clicado." # Línea de depuración
      show_product_management
    })
    menubar.add('cascade', label: 'Gestionar', menu: manage_menu)

    # Asignar el menú a la ventana raíz usando la opción -menu
    @root.configure(menu: menubar)
  end

  # Limpia el frame principal para mostrar una nueva vista
  def clear_main_frame
    # Usa winfo_children para obtener los widgets hijos y destruirlos
    @main_frame.winfo_children.each(&:destroy)
  end

  # Muestra el panel principal
  def show_dashboard
    clear_main_frame
    TkLabel.new(@main_frame) {
      text 'Bienvenido a la Aplicación de Gestión de Restaurante'
      font 'Arial 16 bold'
      pack(pady: 50)
    }
    TkLabel.new(@main_frame) {
      text 'Usa el menú "Gestionar" para administrar categorías y productos.'
      font 'Arial 12'
      pack
    }
  end

  # --- Gestión de Categorías ---

  def show_category_management
    puts "DEBUG: show_category_management llamado." # Línea de depuración
    clear_main_frame
    TkLabel.new(@main_frame) {
      text 'Gestión de Categorías'
      font 'Arial 14 bold'
      pack(pady: 10)
    }

    # Frame para el formulario de categorías
    @category_form_frame = TkFrame.new(@main_frame) {
      pack(pady: 10)
    }
    create_category_form

    # Frame para la lista de categorías
    @category_list_frame = TkFrame.new(@main_frame) {
      pack(fill: 'both', expand: true)
    }
    load_categories
  end

  def create_category_form(category = nil)
    @category_form_frame.winfo_children.each(&:destroy) # Limpiar el formulario

    @category_id = category ? category.id : nil
    initial_name = category ? category.name : ''

    TkLabel.new(@category_form_frame) {
      text 'Nombre de la Categoría:'
      pack(side: 'left', padx: 5)
    }
    @category_name_entry = TkEntry.new(@category_form_frame) {
      width 40
      insert 0, initial_name # Pre-rellenar si es para editar
      pack(side: 'left', padx: 5)
    }

    button_text = category ? 'Actualizar Categoría' : 'Agregar Categoría'
    command_proc = category ? proc { update_category } : proc { add_category }

    TkButton.new(@category_form_frame) {
      text button_text
      command command_proc
      pack(side: 'left', padx: 5)
    }

    if category # Si estamos editando, mostrar botón de cancelar
      TkButton.new(@category_form_frame) {
        text 'Cancelar Edición'
        command proc {
          create_category_form # Volver al formulario de "agregar"
          load_categories # Recargar la lista
        }
        pack(side: 'left', padx: 5)
      }
    end
  end

  def add_category
    name = @category_name_entry.value.strip
    if name.empty?
      show_message_box('Error', 'El nombre de la categoría no puede estar vacío.')
      return
    end

    begin
      Category.create!(name: name)
      @category_name_entry.value = '' # Limpiar el campo
      load_categories
      show_message_box('Éxito', 'Categoría agregada correctamente.')
    rescue ActiveRecord::RecordInvalid => e
      show_message_box('Error', "Error al agregar categoría: #{e.message}")
    rescue StandardError => e
      show_message_box('Error', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def update_category
    category = Category.find_by(id: @category_id)
    unless category
      show_message_box('Error', 'Categoría no encontrada para actualizar.')
      return
    end

    new_name = @category_name_entry.value.strip
    if new_name.empty?
      show_message_box('Error', 'El nombre de la categoría no puede estar vacío.')
      return
    end

    begin
      category.update!(name: new_name)
      create_category_form # Volver al formulario de "agregar"
      load_categories
      show_message_box('Éxito', 'Categoría actualizada correctamente.')
    rescue ActiveRecord::RecordInvalid => e
      show_message_box('Error', "Error al actualizar categoría: #{e.message}")
    rescue StandardError => e
      show_message_box('Error', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def load_categories
    @category_list_frame.winfo_children.each(&:destroy) # Limpiar la lista

    # Encabezados de la tabla
    TkLabel.new(@category_list_frame) { text 'ID'; grid(row: 0, column: 0, padx: 5, pady: 2) }
    TkLabel.new(@category_list_frame) { text 'Nombre'; grid(row: 0, column: 1, padx: 5, pady: 2) }
    TkLabel.new(@category_list_frame) { text 'Acciones'; grid(row: 0, column: 2, columnspan: 2, padx: 5, pady: 2) }

    categories = Category.all.order(:name)
    row_num = 1
    categories.each do |category|
      TkLabel.new(@category_list_frame) { text category.id.to_s; grid(row: row_num, column: 0, padx: 5, pady: 2) }
      TkLabel.new(@category_list_frame) { text category.name; grid(row: row_num, column: 1, padx: 5, pady: 2) }

      TkButton.new(@category_list_frame) {
        text 'Editar'
        command proc { edit_category(category) }
        grid(row: row_num, column: 2, padx: 2, pady: 2)
      }
      TkButton.new(@category_list_frame) {
        text 'Borrar'
        command proc { confirm_delete_category(category) }
        grid(row: row_num, column: 3, padx: 2, pady: 2)
      }
      row_num += 1
    end

    if categories.empty?
      TkLabel.new(@category_list_frame) {
        text 'No hay categorías para mostrar.'
        grid(row: row_num, column: 0, columnspan: 4, pady: 10)
      }
    end
  end

  def edit_category(category)
    create_category_form(category)
  end

  def confirm_delete_category(category)
    # Usar una ventana de diálogo personalizada en lugar de Tk.messageBox.askquestion
    # para evitar problemas con la ejecución en algunos entornos.
    dialog = TkToplevel.new(@root) {
      title 'Confirmar Eliminación'
      transient @root
      grab true # Bloquear otras interacciones hasta que se cierre el diálogo
      resizable false, false
      geometry '+%d+%d' % [@root.winfo_x + 50, @root.winfo_y + 50]
    }

    TkLabel.new(dialog) {
      text "Estás seguro de que quieres eliminar la categoría '#{category.name}'?\nEsto también eliminará todos los productos asociados."
      pack(padx: 20, pady: 20)
    }

    button_frame = TkFrame.new(dialog) { pack(pady: 10) }

    TkButton.new(button_frame) {
      text 'Sí, Eliminar'
      command proc {
        delete_category(category)
        dialog.destroy
      }
      pack(side: 'left', padx: 10)
    }

    TkButton.new(button_frame) {
      text 'Cancelar'
      command proc { dialog.destroy }
      pack(side: 'left', padx: 10)
    }
  end


  def delete_category(category)
    begin
      category.destroy
      load_categories
      show_message_box('Éxito', 'Categoría eliminada correctamente.')
    rescue StandardError => e
      show_message_box('Error', "Error al eliminar categoría: #{e.message}")
    end
  end

  # --- Gestión de Productos ---

  def show_product_management
    puts "DEBUG: show_product_management llamado." # Línea de depuración
    clear_main_frame
    TkLabel.new(@main_frame) {
      text 'Gestión de Productos'
      font 'Arial 14 bold'
      pack(pady: 10)
    }

    # Frame para el formulario de productos
    @product_form_frame = TkFrame.new(@main_frame) {
      pack(pady: 10)
    }
    create_product_form

    # Frame para la lista de productos
    @product_list_frame = TkFrame.new(@main_frame) {
      pack(fill: 'both', expand: true)
    }
    load_products
  end

  def create_product_form(product = nil)
    @product_form_frame.winfo_children.each(&:destroy) # Limpiar el formulario

    @product_id = product ? product.id : nil
    initial_name = product ? product.name : ''
    initial_description = product ? product.description : ''
    initial_price = product ? product.price.to_s : ''
    initial_category_id = product ? product.category_id : nil

    # Campos de entrada para nombre, descripción y precio
    TkLabel.new(@product_form_frame) { text 'Nombre:'; pack(side: 'left', padx: 5) }
    @product_name_entry = TkEntry.new(@product_form_frame) {
      width 25
      insert 0, initial_name
      pack(side: 'left', padx: 5)
    }

    TkLabel.new(@product_form_frame) { text 'Descripción:'; pack(side: 'left', padx: 5) }
    @product_description_entry = TkEntry.new(@product_form_frame) {
      width 30
      insert 0, initial_description
      pack(side: 'left', padx: 5)
    }

    TkLabel.new(@product_form_frame) { text 'Precio:'; pack(side: 'left', padx: 5) }
    @product_price_entry = TkEntry.new(@product_form_frame) {
      width 10
      insert 0, initial_price
      pack(side: 'left', padx: 5)
    }

    # Selector de Categoría
    TkLabel.new(@product_form_frame) { text 'Categoría:'; pack(side: 'left', padx: 5) }
    categories = Category.all.order(:name)
    category_names = categories.map(&:name)
    @selected_category_name = TkVariable.new
    
    # Seleccionar la categoría inicial si se está editando un producto
    if initial_category_id
      selected_cat = categories.find { |cat| cat.id == initial_category_id }
      @selected_category_name.value = selected_cat.name if selected_cat
    else
      @selected_category_name.value = category_names.first if category_names.any?
    end

    @category_option_menu = TkOptionMenu.new(@product_form_frame, @selected_category_name, *category_names)
    @category_option_menu.pack(side: 'left', padx: 5)

    button_text = product ? 'Actualizar Producto' : 'Agregar Producto'
    command_proc = product ? proc { update_product } : proc { add_product }

    TkButton.new(@product_form_frame) {
      text button_text
      command command_proc
      pack(side: 'left', padx: 5)
    }

    if product # Si estamos editando, mostrar botón de cancelar
      TkButton.new(@product_form_frame) {
        text 'Cancelar Edición'
        command proc {
          create_product_form # Volver al formulario de "agregar"
          load_products # Recargar la lista
        }
        pack(side: 'left', padx: 5)
      }
    end
  end

  def add_product
    name = @product_name_entry.value.strip
    description = @product_description_entry.value.strip
    price_str = @product_price_entry.value.strip
    category_name = @selected_category_name.value

    if name.empty? || price_str.empty? || category_name.empty?
      show_message_box('Error', 'Nombre, precio y categoría no pueden estar vacíos.')
      return
    end

    price = Float(price_str) rescue nil
    if price.nil?
      show_message_box('Error', 'El precio debe ser un número válido.')
      return
    end

    category = Category.find_by(name: category_name)
    unless category
      show_message_box('Error', 'Categoría seleccionada no encontrada.')
      return
    end

    begin
      Product.create!(
        name: name,
        description: description,
        price: price,
        category: category
      )
      # Limpiar los campos
      @product_name_entry.value = ''
      @product_description_entry.value = ''
      @product_price_entry.value = ''
      # No limpiar la categoría seleccionada, mantener la última seleccionada
      load_products
      show_message_box('Éxito', 'Producto agregado correctamente.')
    rescue ActiveRecord::RecordInvalid => e
      show_message_box('Error', "Error al agregar producto: #{e.message}")
    rescue StandardError => e
      show_message_box('Error', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def update_product
    product = Product.find_by(id: @product_id)
    unless product
      show_message_box('Error', 'Producto no encontrado para actualizar.')
      return
    end

    name = @product_name_entry.value.strip
    description = @product_description_entry.value.strip
    price_str = @product_price_entry.value.strip
    category_name = @selected_category_name.value

    if name.empty? || price_str.empty? || category_name.empty?
      show_message_box('Error', 'Nombre, precio y categoría no pueden estar vacíos.')
      return
    end

    price = Float(price_str) rescue nil
    if price.nil?
      show_message_box('Error', 'El precio debe ser un número válido.')
      return
    end

    category = Category.find_by(name: category_name)
    unless category
      show_message_box('Error', 'Categoría seleccionada no encontrada.')
      return
    end

    begin
      product.update!(
        name: name,
        description: description,
        price: price,
        category: category
      )
      create_product_form # Volver al formulario de "agregar"
      load_products
      show_message_box('Éxito', 'Producto actualizado correctamente.')
    rescue ActiveRecord::RecordInvalid => e
      show_message_box('Error', "Error al actualizar producto: #{e.message}")
    rescue StandardError => e
      show_message_box('Error', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def load_products
    @product_list_frame.winfo_children.each(&:destroy) # Limpiar la lista

    # Encabezados de la tabla
    TkLabel.new(@product_list_frame) { text 'ID'; grid(row: 0, column: 0, padx: 5, pady: 2) }
    TkLabel.new(@product_list_frame) { text 'Nombre'; grid(row: 0, column: 1, padx: 5, pady: 2) }
    TkLabel.new(@product_list_frame) { text 'Categoría'; grid(row: 0, column: 2, padx: 5, pady: 2) }
    TkLabel.new(@product_list_frame) { text 'Precio'; grid(row: 0, column: 3, padx: 5, pady: 2) }
    TkLabel.new(@product_list_frame) { text 'Acciones'; grid(row: 0, column: 4, columnspan: 2, padx: 5, pady: 2) }

    products = Product.all.includes(:category).order(:name)
    row_num = 1
    products.each do |product|
      TkLabel.new(@product_list_frame) { text product.id.to_s; grid(row: row_num, column: 0, padx: 5, pady: 2) }
      TkLabel.new(@product_list_frame) { text product.name; grid(row: row_num, column: 1, padx: 5, pady: 2) }
      TkLabel.new(@product_list_frame) { text product.category.name; grid(row: row_num, column: 2, padx: 5, pady: 2) }
      TkLabel.new(@product_list_frame) { text format('%.2f', product.price); grid(row: row_num, column: 3, padx: 5, pady: 2) }

      TkButton.new(@product_list_frame) {
        text 'Editar'
        command proc { edit_product(product) }
        grid(row: row_num, column: 4, padx: 2, pady: 2)
      }
      TkButton.new(@product_list_frame) {
        text 'Borrar'
        command proc { confirm_delete_product(product) }
        grid(row: row_num, column: 5, padx: 2, pady: 2)
      }
      row_num += 1
    end

    if products.empty?
      TkLabel.new(@product_list_frame) {
        text 'No hay productos para mostrar.'
        grid(row: row_num, column: 0, columnspan: 6, pady: 10)
      }
    end
  end

  def edit_product(product)
    create_product_form(product)
  end

  def confirm_delete_product(product)
    dialog = TkToplevel.new(@root) {
      title 'Confirmar Eliminación'
      transient @root
      grab true
      resizable false, false
      geometry '+%d+%d' % [@root.winfo_x + 50, @root.winfo_y + 50]
    }

    TkLabel.new(dialog) {
      text "Estás seguro de que quieres eliminar el producto '#{product.name}'?"
      pack(padx: 20, pady: 20)
    }

    button_frame = TkFrame.new(dialog) { pack(pady: 10) }

    TkButton.new(button_frame) {
      text 'Sí, Eliminar'
      command proc {
        delete_product(product)
        dialog.destroy
      }
      pack(side: 'left', padx: 10)
    }

    TkButton.new(button_frame) {
      text 'Cancelar'
      command proc { dialog.destroy }
      pack(side: 'left', padx: 10)
    }
  end

  def delete_product(product)
    begin
      product.destroy
      load_products
      show_message_box('Éxito', 'Producto eliminado correctamente.')
    rescue StandardError => e
      show_message_box('Error', "Error al eliminar producto: #{e.message}")
    end
  end

  # --- Mensajes de Diálogo Personalizados ---
  # Reemplaza Tk.messageBox para un mejor control en entornos embebidos.
  def show_message_box(title, message)
    dialog = TkToplevel.new(@root) {
      title title
      transient @root
      grab true # Bloquear otras interacciones hasta que se cierre el diálogo
      resizable false, false
      geometry '+%d+%d' % [@root.winfo_x + 50, @root.winfo_y + 50]
    }

    TkLabel.new(dialog) {
      text message
      pack(padx: 20, pady: 20)
    }

    TkButton.new(dialog) {
      text 'OK'
      command proc { dialog.destroy }
      pack(pady: 10)
    }
  end

  def run
    Tk.mainloop
  end
end

# --- Ejecución de la Aplicación ---

# Asegurarse de que las migraciones se ejecuten si la base de datos no existe
unless File.exist?('db/restaurant.sqlite3')
  puts "Base de datos no encontrada. Ejecutando migraciones..."
  # Esto es una forma simplificada. En un entorno real, usarías Rake.
  # Para este ejemplo, creamos las tablas directamente si no existen.
  ActiveRecord::Schema.define(version: 20230101000000) do
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
  puts "Migraciones completadas."
end

app = RestaurantApp.new
app.run
