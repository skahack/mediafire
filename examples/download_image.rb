require './common'

m = login

uuid = create_uuid + '.gif'
File.open(uuid, 'w') do |f|
  f.write(File.open('./pic.gif').read)
end
pic = m.upload(uuid)
File.delete(uuid)

puts m.download_image(pic)
