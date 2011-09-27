require 'mediafire'

m = Mediafire.new
dropbox_id = '<dropbox_id>'
filepath = "testfile"
m.dropbox_upload(filepath, dropbox_id)

