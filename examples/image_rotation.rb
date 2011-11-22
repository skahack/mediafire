require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

filepath = "testfile.gif"
pic = m.upload(filepath)

m.image_rotation(pic, 90)
#m.image_rotation(pic, 180)
#m.image_rotation(pic, 270)
#m.image_rotation(pic, 0)
