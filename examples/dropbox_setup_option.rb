require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

# Get a my list and root_folder
mylist = m.list

folder = m.create_folder("<folder name>", m.root_folder)
m.dropbox_setup(folder, true)
options = {
  :header => 'edited',
  :message => 'edited',
}
m.dropbox_setup_option(folder, options)

