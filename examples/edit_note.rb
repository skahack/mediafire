require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

filepath = "testfile"
file = m.upload(filepath)
note = {
  :subject => 'edited',
  :description=> 'edited',
}
m.edit_note(file, note)
