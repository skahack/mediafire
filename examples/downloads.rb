require './common'

m = login

uuid = create_uuid
folder1 = m.create_folder(uuid, root_folder)

uuid = create_uuid
folder2 = m.create_folder(uuid, root_folder)

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end
file1 = m.upload(uuid, folder1)
File.delete(uuid)
puts 'upload file1'

uuid = create_uuid
File.open(uuid, "w") do |f|
  f.write(uuid)
end
file2 = m.upload(uuid, folder2)
File.delete(uuid)
puts 'upload file2'

files = [file1, file2]


m.downloads(files, nil)
