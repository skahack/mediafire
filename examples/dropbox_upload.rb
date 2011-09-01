require './common'

m = Mediafire.new
dropbox_id = ''
m.dropbox_upload('test.txt', dropbox_id)

