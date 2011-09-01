require '../lib/mediafire'
require 'uuidtools'

def login
  account = ''
  password = ''

  m = Mediafire.new
  m.login(account, password)
  return m
end

def pritty_format_datafile(f)
  out = "filename:#{f.name} "
  out << "size:#{f.size} "
  out << "link:http://www.mediafire.com/download.php?#{f.quickkey}"
end

def root_folder
  key = 'b37807725fe86791'
  data = ['1', '2', '0', key, key, 'myfiles', '0'].fill('', 7..20)
  Mediafire::StoreObject.new(data)
end

def create_uuid
  UUIDTools::UUID.random_create.to_s
end
