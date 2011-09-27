require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

download_url = 'http://www.mediafire.com/?xxxxxxxxxxxxxxx'
quickkey = download_url.match(/\?.*/)[1]
m.save_file_to_my_account(quickkey)

