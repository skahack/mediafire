require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

filepath1 = "testfile1"
file1 = m.upload(filepath1)
puts "upload complete #{file1.name}"

filepath2 = "testfile2"
file2 = m.upload(filepath2)
puts "upload complete #{file2.name}"

m.downloads([file1, file2])
