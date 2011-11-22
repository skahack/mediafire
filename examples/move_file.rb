require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

filepath = "testfile"
file = m.upload(filepath)

folder1 = m.create_folder("<folder_name>")
folder2 = m.create_folder("<folder_name>")

re = m.move([file, folder1], folder2)
