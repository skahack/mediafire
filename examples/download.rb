require './common'

m = Mediafire.new

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end
file1 = m.upload(uuid)
File.delete(uuid)
puts pritty_format_datafile(file1)

puts m.download(file1)
