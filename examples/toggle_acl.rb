require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

folder = m.create_folder("<folder name>")
m.toggle_acl(folder)
