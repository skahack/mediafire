require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

folder = m.create_folder("<folder_name>")

puts "folder name : #{folder.name}"
