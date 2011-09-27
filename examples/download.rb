require 'mediafire'

m = Mediafire.new

filepath = "testfile"
file = m.upload(filepath)
out = "filename:#{file.name} "
out << "size:#{file.size} "
out << "link:http://www.mediafire.com/download.php?#{file.quickkey}"
puts out

puts m.download(file)
