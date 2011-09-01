require './common'

uuid = create_uuid
uuid1 = create_uuid
m = login
folder = m.create_folder(uuid, root_folder)
file = m.create_folder(uuid1, root_folder)

re = m.move(file, folder)

