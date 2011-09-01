require './common'

m = login
m.list.each {|n| puts pritty_format_datafile(n) unless n.is_folder?}
