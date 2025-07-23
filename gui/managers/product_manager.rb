# gui/managers/product_manager.rb
# Maneja la interfaz y lógica para la gestión de productos.

require 'tk'
require 'tk/variable'
require 'bigdecimal'
require_relative '../../models/product' # Ruta relativa correcta
require_relative '../../models/category' # Necesita Category para el selector
require_relative '../services/message_service'

class ProductManager
  include Tk

  def initialize(main_content_frame, message_service, app_instance)
    @main_content_frame = main_content_frame
    @message_service = message_service
    @app_instance = app_instance # Referencia a la instancia de RestaurantApp
  end

  def show_management
    clear_frame
    Tk::Label.new(@main_content_frame) {
      text 'Gestión de Productos'
      font 'Arial 16 bold'
      pack(pady: 10)
    }

    @product_form_frame = Tk::Frame.new(@main_content_frame) { pack(pady: 10) }
    create_product_form

    @product_list_frame = Tk::Frame.new(@main_content_frame) { pack(fill: 'both', expand: true) }
    load_products
  end

  def create_product_form(product = nil)
    @product_form_frame.winfo_children.each(&:destroy)

    @product_id = product ? product.id : nil
    initial_name = product ? product.name : ''
    initial_description = product ? product.description : ''
    initial_price = product ? format('%.2f', product.price) : ''
    initial_stock = product ? product.stock.to_s : '0'
    initial_category_id = product ? product.category_id : nil

    input_frame = Tk::Frame.new(@product_form_frame) { pack(pady: 5) }

    Tk::Label.new(input_frame) { text 'Nombre:'; pack(side: 'left', padx: 5) }
    Tk::Entry.new(input_frame) {
      width 25
      insert 0, initial_name
      pack(side: 'left', padx: 5)
    }.tap { |e| @product_name_entry = e }

    Tk::Label.new(input_frame) { text 'Descripción:'; pack(side: 'left', padx: 5) }
    Tk::Entry.new(input_frame) {
      width 30
      insert 0, initial_description
      pack(side: 'left', padx: 5)
    }.tap { |e| @product_description_entry = e }

    Tk::Label.new(input_frame) { text 'Precio:'; pack(side: 'left', padx: 5) }
    Tk::Entry.new(input_frame) {
      width 10
      insert 0, initial_price
      pack(side: 'left', padx: 5)
    }.tap { |e| @product_price_entry = e }

    Tk::Label.new(input_frame) { text 'Stock:'; pack(side: 'left', padx: 5) }
    Tk::Entry.new(input_frame) {
      width 8
      insert 0, initial_stock
      pack(side: 'left', padx: 5)
    }.tap { |e| @product_stock_entry = e }

    # Selector de Categoría
    category_frame = Tk::Frame.new(@product_form_frame) { pack(pady: 5) }
    Tk::Label.new(category_frame) { text 'Categoría:'; pack(side: 'left', padx: 5) }
    categories = Category.all.order(:name)
    category_names = categories.map(&:name)
    @selected_category_name = ::Tk::StringVar.new

    if initial_category_id
      selected_cat = categories.find { |cat| cat.id == initial_category_id }
      @selected_category_name.value = selected_cat.name if selected_cat
    else
      @selected_category_name.value = category_names.first if category_names.any?
    end

    Tk::OptionMenu.new(category_frame, @selected_category_name, *category_names) {
      pack(side: 'left', padx: 5)
    }.tap { |e| @category_option_menu = e }

    # Botones de acción
    button_frame = Tk::Frame.new(@product_form_frame) { pack(pady: 5) }
    button_text = product ? 'Actualizar Producto' : 'Agregar Producto'
    command_proc = product ? proc { update_product } : proc { add_product }

    Tk::Button.new(button_frame) {
      text button_text
      command command_proc
      pack(side: 'left', padx: 5)
    }

    if product
      Tk::Button.new(button_frame,
                   'text' => 'Cancelar Edición',
                   'command' => proc { create_product_form }) {
        pack(side: 'left', padx: 5)
      }
    end
  end

  def add_product
    name = @product_name_entry.value.strip
    description = @product_description_entry.value.strip
    price_str = @product_price_entry.value.strip
    stock_str = @product_stock_entry.value.strip
    category_name = @selected_category_name.value

    if name.empty? || price_str.empty? || stock_str.empty? || category_name.empty?
      @message_service.show_error('Error de Validación', 'Nombre, precio, stock y categoría no pueden estar vacíos.')
      return
    end

    begin
      price = BigDecimal(price_str)
      stock = Integer(stock_str)
    rescue ArgumentError
      @message_service.show_error('Error de Formato', 'El precio y el stock deben ser números válidos.')
      return
    end

    if price < 0
      @message_service.show_error('Error de Validación', 'El precio debe ser un número no negativo.')
      return
    end
    if stock < 0
      @message_service.show_error('Error de Validación', 'El stock debe ser un número entero no negativo.')
      return
    end

    category = Category.find_by(name: category_name)
    unless category
      @message_service.show_error('Error de Validación', 'Categoría seleccionada no encontrada.')
      return
    end

    begin
      Product.create!(
        name: name,
        description: description,
        price: price,
        stock: stock,
        category: category
      )
      @product_name_entry.value = ''
      @product_description_entry.value = ''
      @product_price_entry.value = ''
      @product_stock_entry.value = '0'
      load_products
      @message_service.show_success('Éxito', 'Producto agregado correctamente.')
      @app_instance.refresh_product_data # Notificar a la app principal para refrescar datos de ventas
    rescue ActiveRecord::RecordInvalid => e
      @message_service.show_error('Error al Guardar', "Error de validación al agregar producto: #{e.message}")
    rescue ActiveRecord::ActiveRecordError => e # Captura errores relacionados con ActiveRecord
      @message_service.show_error('Error de Base de Datos', "Ocurrió un error en la base de datos: #{e.message}")
    rescue StandardError => e # Otros errores inesperados
      @message_service.show_error('Error Inesperado', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def update_product
    product = Product.find_by(id: @product_id)
    unless product
      @message_service.show_error('Error', 'Producto no encontrado para actualizar.')
      return
    end

    name = @product_name_entry.value.strip
    description = @product_description_entry.value.strip
    price_str = @product_price_entry.value.strip
    stock_str = @product_stock_entry.value.strip
    category_name = @selected_category_name.value

    if name.empty? || price_str.empty? || stock_str.empty? || category_name.empty?
      @message_service.show_error('Error de Validación', 'Nombre, precio, stock y categoría no pueden estar vacíos.')
      return
    end

    begin
      price = BigDecimal(price_str)
      stock = Integer(stock_str)
    rescue ArgumentError
      @message_service.show_error('Error de Formato', 'El precio y el stock deben ser números válidos.')
      return
    end

    if price < 0
      @message_service.show_error('Error de Validación', 'El precio debe ser un número no negativo.')
      return
    end
    if stock < 0
      @message_service.show_error('Error de Validación', 'El stock debe ser un número entero no negativo.')
      return
    end

    category = Category.find_by(name: category_name)
    unless category
      @message_service.show_error('Error de Validación', 'Categoría seleccionada no encontrada.')
      return
    end

    begin
      product.update!(
        name: name,
        description: description,
        price: price,
        stock: stock,
        category: category
      )
      create_product_form
      load_products
      @message_service.show_success('Éxito', 'Producto actualizado correctamente.')
      @app_instance.refresh_product_data # Notificar a la app principal para refrescar datos de ventas
    rescue ActiveRecord::RecordInvalid => e
      @message_service.show_error('Error al Guardar', "Error de validación al actualizar producto: #{e.message}")
    rescue ActiveRecord::ActiveRecordError => e
      @message_service.show_error('Error de Base de Datos', "Ocurrió un error en la base de datos: #{e.message}")
    rescue StandardError => e
      @message_service.show_error('Error Inesperado', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def load_products
    @product_list_frame.winfo_children.each(&:destroy)

    # ... (el resto del método load_products es el mismo)
    Tk::Label.new(@product_list_frame) { text 'ID'; grid(row: 0, column: 0, padx: 5, pady: 2) }
    Tk::Label.new(@product_list_frame) { text 'Nombre'; grid(row: 0, column: 1, padx: 5, pady: 2) }
    Tk::Label.new(@product_list_frame) { text 'Categoría'; grid(row: 0, column: 2, padx: 5, pady: 2) }
    Tk::Label.new(@product_list_frame) { text 'Precio'; grid(row: 0, column: 3, padx: 5, pady: 2) }
    Tk::Label.new(@product_list_frame) { text 'Stock'; grid(row: 0, column: 4, padx: 5, pady: 2) }
    Tk::Label.new(@product_list_frame) { text 'Acciones'; grid(row: 0, column: 5, columnspan: 2, padx: 5, pady: 2) }

    products = Product.all.includes(:category).order(:name)
    row_num = 1
    products.each do |product|
      Tk::Label.new(@product_list_frame) { text product.id.to_s; grid(row: row_num, column: 0, padx: 5, pady: 2) }
      Tk::Label.new(@product_list_frame) { text product.name; grid(row: row_num, column: 1, padx: 5, pady: 2) }
      Tk::Label.new(@product_list_frame) { text product.category&.name || 'N/A'; grid(row: row_num, column: 2, padx: 5, pady: 2) }
      Tk::Label.new(@product_list_frame) { text format('%.2f', product.price); grid(row: row_num, column: 3, padx: 5, pady: 2) }
      Tk::Label.new(@product_list_frame) { text product.stock.to_s; grid(row: row_num, column: 4, padx: 5, pady: 2) }

      Tk::Button.new(@product_list_frame,
                   'text' => 'Editar',
                   'command' => proc { edit_product(product) }) {
        grid(row: row_num, column: 5, padx: 2, pady: 2)
      }
      Tk::Button.new(@product_list_frame,
                   'text' => 'Borrar',
                   'command' => proc { confirm_delete_product(product) }) {
        grid(row: row_num, column: 6, padx: 2, pady: 2)
      }
      row_num += 1
    end

    if products.empty?
      Tk::Label.new(@product_list_frame) {
        text 'No hay productos para mostrar.'
        grid(row: row_num, column: 0, columnspan: 7, pady: 10)
      }
    end
  end

  def edit_product(product)
    create_product_form(product)
  end

  def confirm_delete_product(product)
    @message_service.confirm_dialog(
      'Confirmar Eliminación',
      "Estás seguro de que quieres eliminar el producto '#{product.name}'?",
      proc { delete_product(product) }
    )
  end

  def delete_product(product)
    begin
      product.destroy
      load_products
      @message_service.show_success('Éxito', 'Producto eliminado correctamente.')
      @app_instance.refresh_product_data # Notificar a la app principal para refrescar datos de ventas
    rescue ActiveRecord::ActiveRecordError => e # Captura errores relacionados con ActiveRecord
      @message_service.show_error('Error de Base de Datos', "Error al eliminar producto: #{e.message}")
    rescue StandardError => e
      @message_service.show_error('Error Inesperado', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  private

  def clear_frame
    @main_content_frame.winfo_children.each(&:destroy)
  end
end