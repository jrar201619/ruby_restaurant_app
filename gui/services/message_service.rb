# gui/services/message_service.rb
# Provee métodos para mostrar cuadros de diálogo de mensajes y confirmación.

require 'tk'

class MessageService
  include Tk

  def initialize(root_window)
    @root_window = root_window
  end

  def show_message_box(title, message)
    dialog = Tk::TkToplevel.new(@root_window) {
      title title
      grab :set
      transient @root_window
      resizable false, false
    }

    Tk::TkLabel.new(dialog) {
      text message
      pack(padx: 20, pady: 20)
    }

    Tk::TkButton.new(dialog) {
      text 'OK'
      command proc { dialog.destroy }
      pack(pady: 10)
    }
  end

  def show_error(title, message)
    show_message_box("Error: #{title}", message)
  end

  def show_success(title, message)
    show_message_box("Éxito: #{title}", message)
  end

  def confirm_dialog(title, message, &on_confirm_proc)
    dialog = Tk::TkToplevel.new(@root_window) {
      title title
      transient @root_window
      grab :set
      resizable false, false
    }

    Tk::TkLabel.new(dialog) {
      text message
      pack(padx: 20, pady: 20)
    }

    button_frame = Tk::TkFrame.new(dialog) { pack(pady: 10) }

    Tk::TkButton.new(button_frame,
                 'text' => 'Sí, Continuar',
                 'command' => proc {
                   on_confirm_proc.call if on_confirm_proc # Llama al bloque si existe
                   dialog.destroy
                 }) {
      pack(side: 'left', padx: 10)
    }

    Tk::TkButton.new(button_frame,
                 'text' => 'Cancelar',
                 'command' => proc { dialog.destroy }) {
      pack(side: 'left', padx: 10)
    }
  end
end