require './common.rb'

m = login

uuid = create_uuid
folder = m.create_folder(uuid, root_folder)

uuid1 = create_uuid
File.open(uuid1, "w") do |f|
  f.write(uuid1)
end
file = m.upload(uuid1)
File.delete(uuid1)

re = m.delete([file, folder])
