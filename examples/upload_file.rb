require './common'

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end

m = login
obj = m.upload(uuid)
puts pritty_format_datafile(obj)

File.delete(uuid)
