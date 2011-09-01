require './common'

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end

m = login
file = m.upload(uuid)
note = {
  :subject => 'edited',
  :description=> 'edited',
}
m.edit_note(file, note)

File.delete(uuid)
