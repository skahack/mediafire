require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

folder = m.create_folder("<folder_name>")
m.dropbox_setup(folder, true)
options = {
  :header => 'edited',
  :message => 'edited',
}
m.dropbox_setup_option(folder, options)

