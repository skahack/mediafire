require './common'

uuid = create_uuid

m = login
folder = m.create_folder(uuid, root_folder)
m.toggle_acl(folder)
