require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

folder = m.create_folder("<folder_name>")
re = m.delete(folder)

filepath = "testfile"
file = m.upload(filepath)
folder = m.create_folder("delete_test")

re = m.delete([file, folder])
