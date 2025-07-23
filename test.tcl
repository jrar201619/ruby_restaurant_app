# test.tcl
puts "Hello from Tcl!"
package require Tk
puts "Hello from Tk!"
wm withdraw .
set myvar "This is a Tk variable directly from Tcl."
label .l -textvariable myvar
button .b -text "Click Me" -command {
    set myvar "Text changed directly from Tcl: [clock seconds]"
}
pack .l .b
wm deiconify .
# Vuelve a retirar la ventana después de 5 segundos para que no se quede abierta si hay error
after 5000 wm withdraw .
puts "Tk window should be visible for 5 seconds."