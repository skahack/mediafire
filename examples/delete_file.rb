require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

# Get a my list and root_folder
mylist = m.list


folder = m.create_folder("<folder name>", m.root_folder)

re = m.delete(folder)


filepath = "testfile"
file = m.upload(filepath)
folder = m.create_folder("<folder name>", m.root_folder)

re = m.delete([file, folder])
