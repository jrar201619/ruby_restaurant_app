# gui/restaurant_app.rb
# Contiene la clase principal de la aplicación de interfaz gráfica,
# que coordina los diferentes "managers" de la UI.

require 'tk' # Asegúrate de que Tk esté cargado primero
require 'tk/variable'
require 'tk/menubar'
# No es necesario cargar explícitamente cada componente de Tk si 'tk' ya lo hace.
# Los DEBUGs pueden ser útiles para depuración, pero los elimino en la versión final limpia.

require_relative 'managers/category_manager'
require_relative 'managers/product_manager'
require_relative 'managers/sale_manager'
require_relative 'managers/report_manager'
require_relative 'services/message_service'

class RestaurantApp
  include Tk

  attr_reader :root, :main_content_frame

  def initialize
    @root = Tk::Root.new  { # Correcto
      title 'Aplicación de Gestión de Restaurante'
      geometry '1024x768'
      minsize(800, 600)
      maxsize(1400, 900)
    }

    @menu_bar_frame = Tk::Frame.new(@root) {
      pack(side: 'top', fill: 'x')
    }

    @main_content_frame = Tk::Frame.new(@root) {
      pack(fill: 'both', expand: true, padx: 10, pady: 10)
    }

    # Instanciar los managers, pasándoles las referencias necesarias
    @message_service = MessageService.new(@root) # El servicio de mensajes necesita el root
    @category_manager = CategoryManager.new(@main_content_frame, @message_service, self)
    @product_manager = ProductManager.new(@main_content_frame, @message_service, self)
    @sale_manager = SaleManager.new(@main_content_frame, @message_service, self)
    @report_manager = ReportManager.new(@main_content_frame, @message_service, self)

    create_menu
    show_dashboard
  end

  # gui/restaurant_app.rb (fragmento del método create_menu)

  def create_menu
    @menu_bar_frame.winfo_children.each(&:destroy)

    # Captura la referencia a la instancia actual de RestaurantApp
    # antes de entrar a los bloques de configuración de los menús.
    app_instance = self

    # Menú Archivo
    @file_menubutton = Tk::Menubutton.new(@menu_bar_frame) {
      text 'Archivo'
      pack(side: 'left', padx: 5, pady: 2)
    }
    @file_menu = Tk::Menu.new(@file_menubutton, tearoff: false) {
      add('command', label: 'Salir', command: proc { exit }) # 'exit' no necesita contexto de instancia
    }
    @file_menubutton.menu(@file_menu)

    # Menú Gestionar
    @manage_menubutton = Tk::Menubutton.new(@menu_bar_frame) {
      text 'Gestionar'
      pack(side: 'left', padx: 5, pady: 2)
    }
    @manage_menu = Tk::Menu.new(@manage_menubutton, tearoff: false) {
      # Ahora usamos 'app_instance' para referenciar los métodos
      add('command', label: 'Categorías', command: app_instance.method(:show_category_management))
      add('command', label: 'Productos', command: app_instance.method(:show_product_management))
      add('command', label: 'Ventas', command: app_instance.method(:show_sale_management))
    }
    @manage_menubutton.menu(@manage_menu)

    # Menú Reportes
    @reports_menubutton = Tk::Menubutton.new(@menu_bar_frame) {
      text 'Reportes'
      pack(side: 'left', padx: 5, pady: 2)
    }
    @reports_menu = Tk::Menu.new(@reports_menubutton, tearoff: false) {
      # Y aquí también usamos 'app_instance'
      add('command', label: 'Reporte de Ventas por Producto', command: app_instance.method(:show_sales_by_product_report))
      add('command', label: 'Reporte de Ingresos Totales', command: app_instance.method(:show_total_revenue_report))
      add('command', label: 'Reporte de Estado de Stock', command: app_instance.method(:show_stock_status_report))
    }
    @reports_menubutton.menu(@reports_menu)
  end

  def clear_main_frame
    @main_content_frame.winfo_children.each(&:destroy)
  end

  def show_dashboard
    clear_main_frame
    Tk::Label.new(@main_content_frame) {
      text 'Bienvenido al Sistema Administrativo de Restaurante'
      font 'Arial 18 bold'
      pack(pady: 50)
    }
    Tk::Label.new(@main_content_frame) {
      text 'Usa el menú para administrar categorías, productos, ventas y generar reportes.'
      font 'Arial 12'
      pack
    }
  end

  # Métodos que delegan a los managers
  def show_category_management
    @category_manager.show_management
  end

  def show_product_management
    @product_manager.show_management
  end

  def show_sale_management
    @sale_manager.show_management
  end

  def show_sales_by_product_report
    @report_manager.show_sales_by_product_report
  end

  def show_total_revenue_report
    @report_manager.show_total_revenue_report
  end

  def show_stock_status_report
    @report_manager.show_stock_status_report
  end

  # Métodos auxiliares que pueden necesitar otros managers
  def refresh_product_data
    # Estos managers ya están definidos en initialize, no se necesita 'if defined?'
    @product_manager.load_products
    @sale_manager.create_sale_form # También para actualizar la lista de productos en ventas
  end

  def run
    Tk.mainloop
  end
end