require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

# Get a my list and root_folder
mylist = m.list

folder = m.create_folder("<folder name>", m.root_folder)

puts "folder name : #{folder.name}"
