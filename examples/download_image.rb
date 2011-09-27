require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

filepath = "testfile.gif"
pic = m.upload(filepath)

puts m.download_image(pic)
