module Mediafire
  module API
    include Mediafire::Connection

    def login(account, password)
      @cookie = {}
      toppage
      unless is_loggedin?
        options = {
          :login_email => account,
          :login_pass => password,
          :login_remember => 'on',
        }
        post("dynamic/login.php", options)
      end
      if @cookie.key?('user')
        @loggedin = true
      end
    end

    def list(options={})
      raise NeedLogin unless is_loggedin?

      folder    = options['folder']
      filter    = options['filter']
      recursive = options['recursive'] || true

      if folder.nil?
        response = myfiles(recursive, filter)
      else
        response = info(folder.key, recursive)
      end
      StoreFolder.new(response)
    end

    def folder_list
      list('recursive' => true, 'filter' => 'folders').folders
    end

    def file_list
      list('recursive' => true, 'filter' => 'files').files
    end

    def delete(objs)
      raise NeedLogin unless is_loggedin?

      file_response = true
      folder_response = true

      obj = separate_store_object(objs)

      file_response = delete_files(obj[:files]) unless obj[:files].empty?
      folder_response = delete_folders(obj[:folders]) unless obj[:folders].empty?

      if file_response and folder_response
        true
      else
        false
      end
    end

    def move(src, dest)
      raise NeedLogin unless is_loggedin?

      file_response = true
      folder_response = true

      obj = separate_store_object(src)

      file_response = move_files(obj[:files], dest) unless obj[:files].empty?
      folder_response = move_folders(obj[:folders], dest) unless obj[:folders].empty?

      if file_response and folder_response
        true
      else
        false
      end
    end

    def rename(file, name)
      options = {
        'filename' => name,
        'description' => file.description,
      }
      if file_update(file, options)
        pick_object(file.key, 'file')
      else
        nil
      end
    end

    def description(file, desc)
      options = {
        'filename' => file.name,
        'description' => desc,
      }
      if file_update(file, options)
        pick_object(file.key, 'file')
      else
        nil
      end
    end

    def password(file, pass)
      options = {
        'password' => pass,
      }
      if file_update(file, options)
        pick_object(file.key, 'file')
      else
        nil
      end
    end

    def create_folder(newname, folder=nil)
      raise NeedLogin unless is_loggedin?

      options = base_query
      options << "foldername=#{newname}"
      options << "parent_key=#{folder.key}" unless folder.nil?

      response = get("api/folder/create.php?#{options.join('&')}")
      response = JSON.parse(response.body)['response']
      if response['result'] == 'Success'
        pick_object(response['folder_key'], 'folder', folder)
      else
        nil
      end
    end

    def toggle_acl(file, recursive=false)
      options = {}
      if file.is_public?
        options['privacy'] = 'private'
      else
        options['privacy'] = 'public'
      end
      options['privacy_recursive'] = 'yes' if recursive

      if file_update(file, options)
        pick_object(file.key, 'file')
      else
        nil
      end
    end

    def upload(filepath, folder=nil)
      filename = File.basename(filepath)
      keys = {}
      response = get('basicapi/uploaderconfiguration.php')
      doc = Nokogiri::XML(response.body)
      doc.xpath('//mediafire/config').each do |c|
        keys[:user] = c.xpath('./user').text
        keys[:ukey] = c.xpath('./ukey').text
        keys[:upload_session] = c.xpath('./upload_session').text
        keys[:trackkey] = c.xpath('./trackkey').text
        if folder.nil?
          keys[:folderkey] = c.xpath('./folderkey').text
        else
          keys[:folderkey] = folder.key
        end
      end
      keys[:mful_config] = doc.xpath('//mediafire/MFULConfig').text

      query = []
      query << "type=basic"
      query << "ukey=#{keys[:ukey]}"
      query << "user=#{keys[:user]}"
      query << "uploadkey=#{keys[:folderkey]}"
      query << "filenum=0"
      query << "uploader=0"
      query << "MFULConfig=#{keys[:mful_config]}"
      response = File.open(filepath) do |f|
        options = {:Filedata => UploadIO.new(f, 'application/octet-stream', filename)}
        post("douploadtoapi?#{query.join('&')}", options)
      end
      doc = Nokogiri::XML(response.body)
      keys[:filekey] = doc.xpath('//response/doupload/key').text

      if keys[:filekey] == ''
        puts "Error: upload failed."
        return nil
      end

      keys[:quickkey] = nil

      query = []
      query << "key=#{keys[:filekey]}"
      query << "MFULConfig=#{keys[:mful_config]}"
      while keys[:quickkey] == nil || keys[:quickkey] == ''
        response = get("basicapi/pollupload.php?#{query.join('&')}")
        doc = Nokogiri::XML(response.body)
        keys[:quickkey] = doc.xpath('//response/doupload/quickkey').text
        keys[:size] = doc.xpath('//response/doupload/size').text
        sleep 0.5
      end

      pick_object(keys[:quickkey], 'file', folder)
    end


    #def webupload(url, folder)
    #end

    def download(file)
      if file.is_a?(Array)
        return downloads(file)
      end

      if file.is_a?(StoreFile)
        response = get("?#{file.key}")
      else
        response = get("?#{file}")
      end
      if response.code.to_i == 302
        return response['Location']
      end

      body = response.body
      funcbody = body.scan(/function .*?for.*?eval/)
      functions = funcbody.map {|n| n.match(/function (.*?)\(/).to_a[1]}
      decrypt_str = funcbody.map {|n| find_encrypt_string_and_decrypt(n)}
      [body, funcbody, functions, decrypt_str]

      t = decrypt_str.last
      funcname = t.match(/(.*?)\(/)[1]
      params = t.scan(/'(.*?)'/)
      qk = params[0][0]
      pk1 = params[1][0]
      pkr = body.match(/pKr ?= ?'(.*?)';/)[1]

      t = decrypt_str[functions.index(funcname)]
      key = t.match(/getElementById\("(.*?)"\)/).to_a[1]

      response = get("dynamic/download.php?qk=#{qk}&pk1=#{pk1}&r=#{pkr}")

      body = response.body
      t = body.match(/var.*?function/).to_a[0]
      download_keys = find_encrypt_string_and_decrypt(t)
      t = body.match(/#{key}.*?("http.*?)>.*?if/)[1]
      i,j,k = t.scan(/"(.*?)".*?\+(.*?)\+.*?"(.*?)\\?"/)[0]
      d = download_keys.match(/#{j}='([\w\d]*)'/)[1]

      return "#{i}#{d}#{k}"
    end

    def downloads(files)
      raise NeedLogin unless is_loggedin?

      option = {
        :form_todolist1 => create_list(files),
        :form_todolist2 => '',
        :form_todotype => 3,
        :form_todoparent => '',
        :form_todoconfirm => 0,
      }
      response = post("dynamic/doselected.php", option)

      filename = response['Content-Disposition'].sub(/^.*?filename="(.*)"$/, '\1')
      puts "downloading: #{filename}"
      File.open("./#{filename}", 'w+b') do |f|
        f.write response.body
      end
    end

    def download_image(file, size=6)
      unless file.is_picture?
        puts 'Error: file is not a picture.'
        return
      end
      if size < 0 && size > 6
        puts 'Error: size must be between 0 to 6.'
        return
      end

      "#{ENDPOINT}imgbnc.php/#{file.hash}#{size.to_s}g.jpg"
    end

    def image_rotation(file, rotation)
      raise NeedLogin unless is_loggedin?

      unless file.is_picture?
        puts "Error: file is not a picture."
        return
      end

      unless rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270
        puts "Error: rotation need 0 or 90 or 180 or 270"
        return
      end

      query = []
      query << "imgkey=#{file.hash}"
      query << "newrotation=#{rotation.to_s}"
      query << "nocache=#{rand.to_s}"

      get("dynamic/imagerotation.php?#{query.join('&')}")
      return true
    end

    def update(dest, src)
      raise NeedLogin unless is_loggedin?

      query = base_query
      query << "r=#{r(4)}"
      query << "from_quickkey=#{src.key}"
      query << "to_quickkey=#{dest.key}"
      query << "quickkey=#{src.key}"

      response = get("api/file/update_file.php?#{query.join('&')}")
      if JSON.parse(response.body)['response']['result'] == 'Success'
        true
      else
        false
      end
    end

    def save_file_to_my_account(quickkey)
      raise NeedLogin unless is_loggedin?

      response = get("dynamic/savefile.php?qk=#{quickkey}")
      if response.body.match(/et ?= ?15;/)
        true
      else
        false
      end
    end

    def dropbox_setup(folder, status)
      raise NeedLogin unless is_loggedin?

      options = {
        :dbx_status_enable => status ? 1 : 0,
        :dbx_silent_return => 0,
        :dbx_status_id => folder.key,
      }
      response = post('dropbox/dosetupdropbox.php', options)
      if response.body.match(/et ?= ?15[012];/)
        return true unless status
      else
        return false
      end

      if dropbox_setup_option(folder)
        return true
      else
        return false
      end
    end

    # return Dropbox ID
    def dropbox_setup_option(folder, options={})
      raise NeedLogin unless is_loggedin?

      response = post('dropbox/dosetupdropbox.php', {:dbx_folderid => folder.key})
      folder_options = eval("[#{response.body.match(/parent.Bl\((.*?)\);break;/)[1]}]")

      allow_add_description = options[:allow_add_description] ? 1 : 0
      multiple_upload = options[:multiple_upload] ? 1 : 0
      email_notification = options[:email_notification] ? 1 : 0
      form_options = {
        :dbx_folder => folder.key,
        :dbx_text1 => options[:header] || folder_options[2],
        :dbx_text2 => options[:message] || folder_options[3],
        :dbx_text3 => options[:completion_message] || folder_options[4],
        :dbx_color1 => options[:background_color] || folder_options[5],
        :dbx_color2 => options[:header_background_color] || folder_options[6],
        :dbx_color3 => options[:header_text_color] || folder_options[7],
        :dbx_color4 => options[:text_color] || folder_options[8],
        :dbx_color5 => options[:link_color] || folder_options[9],
        :dbx_sharing => nil,
        :dbx_descrip => allow_add_description || folder_options[10],
        :dbx_multi => multiple_upload || folder_options[11],
        :dbx_width => options[:width] || folder_options[12],
        :dbx_email => email_notification || folder_options[13],
      }
      response = post('dropbox/dosetupdropbox.php', form_options)
      if response.body.match(/et ?= ?200;/)
        folder_options[0]
      else
        nil
      end
    end

    def dropbox_upload(filepath, dropbox_id)
      keys = {}
      filename = File.basename(filepath)
      response = get("dropbox/dropboxcfg.php?key=#{dropbox_id}")
      doc = Nokogiri::XML(response.body)
      doc.xpath('//mediafire/config').each do |c|
        keys[:user] = c.xpath('./user').text
        keys[:ukey] = c.xpath('./ukey').text
        keys[:upload_session] = c.xpath('./upload_session').text
        keys[:trackkey] = c.xpath('./trackkey').text
      end

      query = []
      query << "type=basic"
      query << "track=#{keys[:trackkey]}"
      query << "dropbox=1"
      query << "ukey=#{keys[:ukey]}"
      query << "user=#{keys[:user]}"
      query << "uploadkey=#{dropbox_id}"
      query << "upload=0"
      response = File.open(filepath) do |f|
        options = {:Filedata => UploadIO.new(f, 'application/octet-stream', filename)}
        post("douploadtoapi?#{query.join('&')}", options)
      end
      doc = Nokogiri::XML(response.body)
      keys[:filekey] = doc.xpath('//response/doupload/key').text

      if keys[:filekey] == ''
        puts "Error: upload failed."
        return nil
      end

      keys[:quickkey] = nil
      query = "key=#{keys[:filekey]}&dropbox=#{dropbox_id}"
      while keys[:quickkey] == nil || keys[:quickkey] == ''
        response = get("dropbox/pollupload.php?#{query}")
        doc = Nokogiri::XML(response.body)
        keys[:quickkey] = doc.xpath('//response/doupload/quickkey').text
        keys[:size] = doc.xpath('//response/doupload/size').text
        sleep 0.5
      end

      puts "#{ENDPOINT}?#{keys[:quickkey]}"
    end

    def revision(folder_key="myfiles", recursive=false)
      query = base_query
      query << "r=#{r(4)}"
      query << "recursive=#{recursive ? 'yes' : 'no'}"
      query << "folder_key=#{folder_key}"

      response = get("api/folder/get_revision.php?#{query.join('&')}").body
      JSON.parse(response)['response']['revision']
    end

    def is_loggedin?
      @loggedin
    end

    private

    # Low level APIs

    def toppage
      get('')
    end

    # @param token     session token
    # @param recursive [true|false]
    # @param filter    ['folder']
    def myfiles(recursive=false, filter=nil)
      query = base_query
      query << "r=#{r(4)}"
      query << "recursive=#{recursive ? 'yes' : 'no'}" unless recursive.nil?
      query << "content_filter=#{filter}" unless filter.nil?

      response = get("api/user/myfiles.php?#{query.join('&')}").body
      JSON.parse(response)['response']['myfiles']
    end

    def info(folder_keys, recursive=false)
      if folder_keys.is_a?(String)
        folder_keys = [folder_keys]
      end

      query = base_query
      query << "r=#{r(4)}"
      query << "folder_key=#{folder_keys.join(',')}"
      query << "recursive=#{recursive ? 'yes' : 'no'}"

      response = get("api/folder/get_info.php?#{query.join('&')}").body
      response = JSON.parse(response)['response']

      if response.key?('folder_info')
        return response['folder_info']
      elsif response.key?('folder_infos')
        return response['folder_infos']
      end
    end

    def file_update(file, options={})
      if options.key?('password')
        return password_update(file, options['password'])
      end

      query = base_query
      query << "filename=#{options['filename']}" if options.key?('filename')
      query << "description=#{options['description']}" if options.key?('description')
      if options.key?('privacy')
        query << "privacy=#{options['privacy']}"
        query << "r=#{r(4)}"
      end
      if !file.is_folder? && options.key?('privacy_recursive')
        query << "privacy_recursive=#{options['privacy_recursive']}"
      end
      query << "quick_key=#{file.key}"
      
      if file.is_folder?
        response = get("api/folder/update.php?#{query.join('&')}")
      else
        response = get("api/file/update.php?#{query.join('&')}")
      end

      return false if response.code.to_i == 400
      if JSON.parse(response.body)['response']['result'] == 'Success'
        return true
      else
        return false
      end
    end

    def password_update(file, password)
      query = base_query
      query << "r=#{r(4)}"
      query << "quick_key=#{file.key}"
      query << "password=#{password}"

      if file.is_folder?
        response = get("api/folder/update_password.php?#{query.join('&')}")
      else
        response = get("api/file/update_password.php?#{query.join('&')}")
      end

      return false if response.code.to_i == 400
      if JSON.parse(response.body)['response']['result'] == 'Success'
        return true
      else
        return false
      end
    end

    def delete_files(files)
      options = base_query(true)
      options[:quick_key] = quick_keys(files).join(',')

      response = post('api/file/delete.php', options)
      if JSON.parse(response.body)['response']['result'] == 'Success'
        true
      else
        false
      end
    end

    def delete_folders(folders)
      options = base_query(true)
      options[:folder_key] = quick_keys(folders).join(',')

      response = post('api/folder/delete.php', options)
      if JSON.parse(response.body)['response']['result'] == 'Success'
        true
      else
        false
      end
    end

    def move_files(files, dest)
      options = base_query(true)
      options[:quick_key] = quick_keys(files).join(',')
      options[:folder_key] = dest.key

      response = post('api/file/move.php', options)
      if JSON.parse(response.body)['response']['result'] == 'Success'
        true
      else
        false
      end
    end

    def move_folders(folders, dest)
      options = base_query(true)
      options[:folder_key_src] = quick_keys(folders).join(',')
      options[:folder_key_dst] = dest.key

      response = post('api/folder/move.php', options)
      if JSON.parse(response.body)['response']['result'] == 'Success'
        true
      else
        false
      end
    end

    # Utilities

    def session_token
      if defined?(@token)
        return @token
      end

      response = get('myfiles.php')
      @token = /[0-9a-f]{144}/.match(response.body)[0]
      return @token
    end

    def create_list(files)
      f = files
      f = [f] unless f.is_a?(Array)
      f.map {|n| "#{n.is_folder? ? '2' : '1'}:#{n.key}"}.join(';')
    end

    def separate_store_object(objs)
      files = []
      folders = []

      objs = [objs] unless objs.is_a?(Array)
      objs.each do |obj|
        files << obj if obj.is_a?(StoreFile)
        folders << obj if obj.is_a?(StoreFolder)
      end

      return {
        :files => files,
        :folders => folders,
      }
    end

    def r(len)
      r = ''
      while (len > 0)
        r << (((rand * 1000).to_i % 26) + 97).chr
        len -= 1
      end
      return r
    end

    def base_query(hash=false)
      if hash
        return {
          :session_token => session_token,
          :response_format => 'json',
          :version => 1,
        }
      else
        return [
          "session_token=#{session_token}",
          "response_format=json",
          "version=1",
        ]
      end
    end

    def quick_keys(files)
      return [files.key] unless files.is_a?(Array)

      quick_keys = []
      files.each do |f|
        quick_keys << f.key
      end

      quick_keys
    end

    def pick_object(key, type, folder=nil)
      if folder.nil?
        datas = myfiles
        if type == 'file' and datas.key?('files')
          datas['files'].each {|f| return StoreFile.new(f) if f['quickkey'] == key}
        elsif type == 'folder' and datas.key?('folders')
          datas['folders'].each {|f| return StoreFolder.new(f) if f['folderkey'] == key}
        else
          return nil
        end

      else
        sf = StoreFolder.new(info(folder.key))
        if type == 'file'
          objs = sf.files
        elsif type == 'folder'
          objs = sf.folders
        else
          return nil
        end

        objs.each {|f| return f if f.key == key}
      end
    end

    def filesize_to_readable_filesize(size)
      b = 10 ** 2
      s = size
      return [s.to_s, "B"] if s / 1024 == 0
      s = ((s / 1024.0) * b).ceil / b
      return [s.to_s, "KB"] if s / 1024 == 0
      s = ((s / 1024.0) * b).ceil / b
      return [s.to_s, "MB"] if s / 1024 == 0
      s = ((s / 1024.0) * b).ceil / b
      return [s.to_s, "GB"]
    end

    def find_encrypt_string_and_decrypt(body)
      b = body
      c = b.match(/for.*;/).to_a[0]
      return unless c

      d = c.match(/i<(.*?);/).to_a[1]
      e = c.match(/parseInt\((.*?)\./).to_a[1]
      return unless d or e

      f = b.match(/#{d} ?= ?([\d]*);/).to_a[1].to_i
      g = b.match(/#{e} ?= ?unescape\(\\?'(.*?)\\?'\);/).to_a[1]
      h = c.match(/\)(\^.*?)\)/).to_a[1]
      return unless f or g or h

      i = ''
      f.times {|n| i+=eval("(g.slice(n*2, 2).to_i(16)#{h}).chr")}
      return i
    end
  end
end
