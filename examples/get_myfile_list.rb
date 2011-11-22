require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

m.file_list.each do |n|
  out = "filename:#{n.name} "
  out << "size:#{n.size} "
  out << "link:http://www.mediafire.com/download.php?#{n.key}"
  puts out
end
