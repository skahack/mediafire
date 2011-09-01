require './common'

m = login

uuid = create_uuid
folder = m.create_folder(uuid, root_folder)
puts "folder name : #{folder.name}"
