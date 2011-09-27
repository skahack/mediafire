require 'mediafire'

m = Mediafire.new
m.login("<account>", "<password>")

m.list.each do |n|
  out = "filename:#{n.name} "
  out << "size:#{n.size} "
  out << "link:http://www.mediafire.com/download.php?#{n.quickkey}"
  puts out unless n.is_folder?
end
