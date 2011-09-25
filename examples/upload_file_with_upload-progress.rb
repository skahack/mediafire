require 'mediafire'
require 'progressbar'

if ARGV.size < 1
  exit
end

queue = Queue.new

file = ARGV[0]
filename = File.basename(file)
puts "Filename: " + filename
filesize = File.stat(file).size
puts "Filesize: " + filesize.to_s

m = Mediafire.new
m.login('<account>', '<password>')

Thread.new do
  queue.push m.upload(file)
end

upload_t = nil
while upload_t.nil?
  Thread.list.each do |n|
    if n.key?(:filename)
      upload_t = n
      break
    end
  end
  sleep 0.1
end

pbar = ProgressBar.new('test(bytes)', filesize)
pbar.file_transfer_mode
while upload_t.alive?
  uploadsize = m.upload_size filename
  pbar.set(uploadsize) if uploadsize <= filesize
  sleep 0.01
end
pbar.finish

uploadfile = queue.pop
puts "filename: #{uploadfile.name} size: #{uploadfile.size} key: #{uploadfile.quickkey}"
