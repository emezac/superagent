require "markly"

doc = Markly::Document.new
doc.append_heading("Mi título", 1)
doc.append_paragraph("Este es un párrafo.")
doc.append_list(["Elemento 1", "Elemento 2"], ordered: false)

File.write("mi_archivo.md", doc.to_markdown)

