require './common'

m = login

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end

m = login
file = m.upload(uuid)
options = {
  :filename => 'edited',
  :description => 'edited',
  :tags => 'edited',
  :password => 'edited',
}
m.edit_fileoption(file, options)

File.delete(uuid)
