require './common'

m = login

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end
file_a = m.upload(uuid)
File.delete(uuid)

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end
file_b = m.upload(uuid)
File.delete(uuid)

puts pritty_format_datafile(file_a)
puts pritty_format_datafile(file_b)
m.update(file_a, file_b)

