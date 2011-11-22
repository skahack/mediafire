require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

filepath = "testfile"
file = m.upload(filepath)

file = m.rename(file, 'edited')
file = m.description(file, 'edited')
file = m.password(file, 'edited')
