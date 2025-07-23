# hello_shoes.rb
Shoes.app do
  stack margin: 10 do
    para "¡Hola, Shoes desde Ruby!"
    button "Haz clic" do
      alert "¡Hiciste clic en el botón!"
    end
  end
end