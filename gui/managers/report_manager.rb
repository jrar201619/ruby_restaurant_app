# gui/managers/report_manager.rb
# Maneja la interfaz y lógica para la generación de reportes.

require 'tk'
require 'bigdecimal'
require_relative '../../models/product' # Necesita Product para reportes
require_relative '../../models/sale' # Necesita Sale para reportes
require_relative '../services/message_service'

class ReportManager
  include Tk

  def initialize(main_content_frame, message_service, app_instance)
    @main_content_frame = main_content_frame
    @message_service = message_service
    @app_instance = app_instance
  end

  def show_management_base # Método base para mostrar el área de reportes
    clear_frame
    Tk::TkLabel.new(@main_content_frame) {
      text 'Generación de Reportes'
      font 'Arial 16 bold'
      pack(pady: 10)
    }

    report_buttons_frame = Tk::TkFrame.new(@main_content_frame) { pack(pady: 10) }
    Tk::TkButton.new(report_buttons_frame) {
      text 'Reporte de Ventas por Producto'
      command proc { show_sales_by_product_report }
      pack(side: 'left', padx: 10)
    }
    Tk::TkButton.new(report_buttons_frame) {
      text 'Reporte de Ingresos Totales'
      command proc { show_total_revenue_report }
      pack(side: 'left', padx: 10)
    }
    Tk::TkButton.new(report_buttons_frame) {
      text 'Reporte de Estado de Stock'
      command proc { show_stock_status_report }
      pack(side: 'left', padx: 10)
    }

    @report_display_frame = Tk::TkFrame.new(@main_content_frame) { pack(fill: 'both', expand: true, pady: 10) }
  end

  def show_sales_by_product_report
    show_management_base # Vuelve a cargar la base de reportes
    Tk::TkLabel.new(@report_display_frame) {
      text '--- Reporte de Ventas por Producto ---'
      font 'Arial 14 bold'
      pack(pady: 10)
    }

    sales_data = Sale.all.includes(:product)
    product_sales = Hash.new(0)
    product_revenue = Hash.new(BigDecimal('0.0'))

    sales_data.each do |sale|
      product_name = sale.product&.name || 'Producto Desconocido'
      product_sales[product_name] += sale.quantity
      product_revenue[product_name] += sale.total_price
    end

    if product_sales.empty?
      Tk::TkLabel.new(@report_display_frame) { text 'No hay datos de ventas para generar el reporte.'; pack(pady: 5) }
    else
      product_sales.each do |product_name, quantity_sold|
        revenue = product_revenue[product_name]
        Tk::TkLabel.new(@report_display_frame) {
          text "Producto: #{product_name}, Unidades Vendidas: #{quantity_sold}, Ingresos Totales: $#{format('%.2f', revenue)}"
          pack(anchor: 'w', padx: 20)
        }
      end
    end
  end

  def show_total_revenue_report
    show_management_base # Vuelve a cargar la base de reportes
    Tk::TkLabel.new(@report_display_frame) {
      text '--- Reporte de Ingresos Totales ---'
      font 'Arial 14 bold'
      pack(pady: 10)
    }

    total_revenue = Sale.sum(:total_price)
    Tk::TkLabel.new(@report_display_frame) {
      text "Ingresos Totales Generados: $#{format('%.2f', total_revenue)}"
      pack(pady: 5)
    }
  end

  def show_stock_status_report
    show_management_base # Vuelve a cargar la base de reportes
    Tk::TkLabel.new(@report_display_frame) {
      text '--- Reporte de Estado de Stock ---'
      font 'Arial 14 bold'
      pack(pady: 10)
    }

    products = Product.all.order(:name)
    if products.empty?
      Tk::TkLabel.new(@report_display_frame) { text 'No hay productos registrados para verificar el stock.'; pack(pady: 5) }
    else
      products.each do |product|
        status = product.stock > 0 ? "En Stock" : "Agotado"
        Tk::TkLabel.new(@report_display_frame) {
          text "Producto: #{product.name}, Stock Actual: #{product.stock}, Estado: #{status}"
          pack(anchor: 'w', padx: 20)
        }
      end
    end
  end

  private

  def clear_frame
    @main_content_frame.winfo_children.each(&:destroy)
  end
end