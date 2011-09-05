require './common'

m = login

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end
file1 = m.upload(uuid)
File.delete(uuid)
puts 'upload file1'

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end
file2 = m.upload(uuid)
File.delete(uuid)
puts 'upload file2'

files = [file1, file2]


m.downloads(files)
