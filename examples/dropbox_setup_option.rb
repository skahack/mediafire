require './common'

m = login

uuid = create_uuid
folder = m.create_folder(uuid, root_folder)
m.dropbox_setup(folder, true)
options = {
  :header => 'edited',
  :message => 'edited',
}
m.dropbox_setup_option(folder, options)

