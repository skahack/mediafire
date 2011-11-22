require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

folder = m.create_folder("<folder_name>")
m.dropbox_setup(folder, true)

folder = m.create_folder("<folder_name>")
m.dropbox_setup(folder, true)
m.dropbox_setup(folder, false)
