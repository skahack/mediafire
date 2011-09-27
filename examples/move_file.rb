require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

# Get a my list and root_folder
mylist = m.list

folder1 = m.create_folder("<folder name>", m.root_folder)
folder2 = m.create_folder("<folder name>", m.root_folder)

re = m.move(folder2, folder1)
