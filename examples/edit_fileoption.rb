require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")


filepath = "testfile"
file = m.upload(filepath)
options = {
  :filename => 'edited',
  :description => 'edited',
  :tags => 'edited',
  :password => 'edited',
}
m.edit_fileoption(file, options)

File.delete(uuid)
