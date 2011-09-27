require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

filepath1 = "testfile1"
filepath2 = "testfile2"
file_a = m.upload(filepath1)
file_b = m.upload(filepath2)

m.update(file_a, file_b)

