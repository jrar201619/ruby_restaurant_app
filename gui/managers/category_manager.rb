# gui/managers/category_manager.rb
# Maneja la interfaz y lógica para la gestión de categorías.

require 'tk'
require 'bigdecimal' # Aunque no se usa directamente aquí, es buena práctica si la vas a usar para otros modelos
require_relative '../../models/category' # Ruta relativa correcta
require_relative '../services/message_service' # Ruta relativa correcta

class CategoryManager
  include Tk

  def initialize(main_content_frame, message_service, app_instance)
    @main_content_frame = main_content_frame
    @message_service = message_service
    @app_instance = app_instance # Referencia a la instancia de RestaurantApp
  end

  def show_management
    clear_frame
    Tk::Label.new(@main_content_frame) {
      text 'Gestión de Categorías'
      font 'Arial 16 bold'
      pack(pady: 10)
    }

    @category_form_frame = Tk::Frame.new(@main_content_frame) { pack(pady: 10) }
    create_category_form

    @category_list_frame = Tk::Frame.new(@main_content_frame) { pack(fill: 'both', expand: true) }
    load_categories
  end

  def create_category_form(category = nil)
    @category_form_frame.winfo_children.each(&:destroy)

    @category_id = category ? category.id : nil
    initial_name = category ? category.name : ''

    Tk::Label.new(@category_form_frame) { text 'Nombre de la Categoría:'; pack(side: 'left', padx: 5) }
    Tk::Entry.new(@category_form_frame) {
      width 40
      insert 0, initial_name
      pack(side: 'left', padx: 5)
    }.tap { |e| @category_name_entry = e }

    button_text = category ? 'Actualizar Categoría' : 'Agregar Categoría'
    command_proc = category ? proc { update_category } : proc { add_category }

    Tk::Button.new(@category_form_frame) {
      text button_text
      command command_proc
      pack(side: 'left', padx: 5)
    }

    if category
      Tk::Button.new(@category_form_frame,
                   'text' => 'Cancelar Edición',
                   'command' => proc { create_category_form }) {
        pack(side: 'left', padx: 5)
      }
    end
  end

  def add_category
    name = @category_name_entry.value.strip
    if name.empty?
      @message_service.show_error('Error de Validación', 'El nombre de la categoría no puede estar vacío.')
      return
    end

    begin
      Category.create!(name: name)
      @category_name_entry.value = ''
      load_categories
      @message_service.show_success('Éxito', 'Categoría agregada correctamente.')
      @app_instance.refresh_product_data # Notificar a la app principal para refrescar datos de productos/ventas
    rescue ActiveRecord::RecordInvalid => e
      @message_service.show_error('Error al Guardar', "Error al agregar categoría: #{e.message}")
    rescue StandardError => e
      @message_service.show_error('Error Inesperado', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def update_category
    category = Category.find_by(id: @category_id)
    unless category
      @message_service.show_error('Error', 'Categoría no encontrada para actualizar.')
      return
    end

    new_name = @category_name_entry.value.strip
    if new_name.empty?
      @message_service.show_error('Error de Validación', 'El nombre de la categoría no puede estar vacío.')
      return
    end

    begin
      category.update!(name: new_name)
      create_category_form
      load_categories
      @message_service.show_success('Éxito', 'Categoría actualizada correctamente.')
      @app_instance.refresh_product_data # Notificar a la app principal para refrescar datos de productos/ventas
    rescue ActiveRecord::RecordInvalid => e
      @message_service.show_error('Error al Guardar', "Error al actualizar categoría: #{e.message}")
    rescue StandardError => e
      @message_service.show_error('Error Inesperado', "Ocurrió un error inesperado: #{e.message}")
    end
  end

  def load_categories
    @category_list_frame.winfo_children.each(&:destroy)

    Tk::Label.new(@category_list_frame) { text 'ID'; grid(row: 0, column: 0, padx: 5, pady: 2) }
    Tk::Label.new(@category_list_frame) { text 'Nombre'; grid(row: 0, column: 1, padx: 5, pady: 2) }
    Tk::Label.new(@category_list_frame) { text 'Acciones'; grid(row: 0, column: 2, columnspan: 2, padx: 5, pady: 2) }

    categories = Category.all.order(:name)
    row_num = 1
    categories.each do |category|
      Tk::Label.new(@category_list_frame) { text category.id.to_s; grid(row: row_num, column: 0, padx: 5, pady: 2) }
      Tk::Label.new(@category_list_frame) { text category.name; grid(row: row_num, column: 1, padx: 5, pady: 2) }

      Tk::Button.new(@category_list_frame,
                   'text' => 'Editar',
                   'command' => proc { edit_category(category) }) {
        grid(row: row_num, column: 2, padx: 2, pady: 2)
      }
      Tk::Button.new(@category_list_frame,
                   'text' => 'Borrar',
                   'command' => proc { confirm_delete_category(category) }) {
        grid(row: row_num, column: 3, padx: 2, pady: 2)
      }
      row_num += 1
    end

    if categories.empty?
      Tk::Label.new(@category_list_frame) {
        text 'No hay categorías para mostrar.'
        grid(row: row_num, column: 0, columnspan: 4, pady: 10)
      }
    end
  end

  def edit_category(category)
    create_category_form(category)
  end

  def confirm_delete_category(category)
    @message_service.confirm_dialog(
      'Confirmar Eliminación',
      "Estás seguro de que quieres eliminar la categoría '#{category.name}'?\nEsto también eliminará todos los productos asociados.",
      proc { delete_category(category) }
    )
  end

  def delete_category(category)
    begin
      category.destroy
      load_categories
      @message_service.show_success('Éxito', 'Categoría eliminada correctamente.')
      @app_instance.refresh_product_data # Notificar a la app principal para refrescar datos de productos/ventas
    rescue StandardError => e
      @message_service.show_error('Error al Eliminar', "Error al eliminar categoría: #{e.message}")
    end
  end

  private

  def clear_frame
    @main_content_frame.winfo_children.each(&:destroy)
  end
end