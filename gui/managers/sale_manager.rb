# gui/managers/sale_manager.rb
# Maneja la interfaz y lógica para la gestión de ventas.

require 'tk'
require 'bigdecimal'
require_relative '../../models/sale' # Ruta relativa correcta
require_relative '../../models/product' # Necesita Product para el selector
require_relative '../services/message_service'

class SaleManager
  include Tk

  def initialize(main_content_frame, message_service, app_instance)
    @main_content_frame = main_content_frame
    @message_service = message_service
    @app_instance = app_instance
  end

  def show_management
    clear_frame
    Tk::TkLabel.new(@main_content_frame) {
      text 'Gestión de Ventas'
      font 'Arial 16 bold'
      pack(pady: 10)
    }

    @sale_form_frame = Tk::TkFrame.new(@main_content_frame) { pack(pady: 10) }
    create_sale_form

    @sale_list_frame = Tk::TkFrame.new(@main_content_frame) { pack(fill: 'both', expand: true) }
    load_sales
  end

  def create_sale_form
    @sale_form_frame.winfo_children.each(&:destroy)

    products = Product.all.order(:name)
    product_names = products.map { |p| "#{p.name} (Stock: #{p.stock}, Precio: #{format('%.2f', p.price)})" }
    @selected_product_display_name = Tk::TkVariable.new
    @selected_product_display_name.value = product_names.first if product_names.any?

    Tk::TkLabel.new(@sale_form_frame) { text 'Producto:'; pack(side: 'left', padx: 5) }
    Tk::TkOptionMenu.new(@sale_form_frame, @selected_product_display_name, *product_names) {
      pack(side: 'left', padx: 5)
    }.tap { |e| @product_sale_option_menu = e }

    Tk::TkLabel.new(@sale_form_frame) { text 'Cantidad:'; pack(side: 'left', padx: 5) }
    Tk::TkEntry.new(@sale_form_frame) {
      width 10
      insert 0, '1'
      pack(side: 'left', padx: 5)
    }.tap { |e| @sale_quantity_entry = e }

    Tk::TkButton.new(@sale_form_frame) {
      text 'Registrar Venta'
      command proc { record_sale }
      pack(side: 'left', padx: 15)
    }
  end

  def record_sale
    product_display_name = @selected_product_display_name.value
    quantity_str = @sale_quantity_entry.value.strip

    if product_display_name.empty?
      @message_service.show_error('Error de Validación', 'Por favor, selecciona un producto.')
      return
    end

    quantity = Integer(quantity_str) rescue nil

    if quantity.nil? || quantity <= 0
      @message_service.show_error('Error de Validación', 'La cantidad debe ser un número entero positivo.')
      return
    end

    product_name_match = product_display_name.match(/(.*) \(Stock:/)
    product_name = product_name_match[1].strip if product_name_match

    product = Product.find_by(name: product_name)

    unless product
      @message_service.show_error('Error', 'Producto seleccionado no encontrado en la base de datos.')
      return
    end

    if product.stock < quantity
      @message_service.show_error('Error de Stock', "Stock insuficiente para '#{product.name}'. Stock disponible: #{product.stock}.")
      return
    end

    begin
      Sale.create!(
        product: product,
        quantity: quantity,
        unit_price: product.price,
        total_price: product.price * quantity,
        sale_date: Time.now
      )
      @sale_quantity_entry.value = '1'
      create_sale_form # Recargar el formulario para actualizar stock en el menú desplegable
      load_sales
      @message_service.show_success('Éxito', 'Venta registrada correctamente.')
      @app_instance.refresh_product_data # Notificar a la app principal para refrescar datos de productos
    rescue ActiveRecord::RecordInvalid => e
      @message_service.show_error('Error al Guardar', "Error al registrar venta: #{e.message}")
    rescue StandardError => e
      @message_service.show_error('Error Inesperado', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def load_sales
    @sale_list_frame.winfo_children.each(&:destroy)

    Tk::TkLabel.new(@sale_list_frame) { text 'ID Venta'; grid(row: 0, column: 0, padx: 5, pady: 2) }
    Tk::TkLabel.new(@sale_list_frame) { text 'Producto'; grid(row: 0, column: 1, padx: 5, pady: 2) }
    Tk::TkLabel.new(@sale_list_frame) { text 'Cantidad'; grid(row: 0, column: 2, padx: 5, pady: 2) }
    Tk::TkLabel.new(@sale_list_frame) { text 'Precio Unitario'; grid(row: 0, column: 3, padx: 5, pady: 2) }
    Tk::TkLabel.new(@sale_list_frame) { text 'Total'; grid(row: 0, column: 4, padx: 5, pady: 2) }
    Tk::TkLabel.new(@sale_list_frame) { text 'Fecha'; grid(row: 0, column: 5, padx: 5, pady: 2) }

    sales = Sale.all.includes(:product).order(sale_date: :desc)
    row_num = 1
    sales.each do |sale|
      Tk::TkLabel.new(@sale_list_frame) { text sale.id.to_s; grid(row: row_num, column: 0, padx: 5, pady: 2) }
      Tk::TkLabel.new(@sale_list_frame) { text sale.product&.name || 'N/A'; grid(row: row_num, column: 1, padx: 5, pady: 2) }
      Tk::TkLabel.new(@sale_list_frame) { text sale.quantity.to_s; grid(row: row_num, column: 2, padx: 5, pady: 2) }
      Tk::TkLabel.new(@sale_list_frame) { text format('%.2f', sale.unit_price); grid(row: row_num, column: 3, padx: 5, pady: 2) }
      Tk::TkLabel.new(@sale_list_frame) { text format('%.2f', sale.total_price); grid(row: row_num, column: 4, padx: 5, pady: 2) }
      Tk::TkLabel.new(@sale_list_frame) { text sale.sale_date.strftime('%Y-%m-%d %H:%M:%S'); grid(row: row_num, column: 5, padx: 5, pady: 2) }
      row_num += 1
    end

    if sales.empty?
      Tk::TkLabel.new(@sale_list_frame) {
        text 'No hay ventas para mostrar.'
        grid(row: row_num, column: 0, columnspan: 6, pady: 10)
      }
    end
  end

  private

  def clear_frame
    @main_content_frame.winfo_children.each(&:destroy)
  end
end