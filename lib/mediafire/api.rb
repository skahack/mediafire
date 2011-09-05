module Mediafire
  module API
    include Mediafire::Connection

    def toppage
      get('')
    end

    def login(account, password)
      @cookie = {}
      toppage
      unless is_loggedin?
        options = {
          :login_email => account,
          :login_pass => password,
          :login_remember => 'on',
          "submit_login.x" => 0,
          "submit_login.y" => 0,
        }
        post("dynamic/login.php", options)
      end
      if @cookie.key?('user')
        @loggedin = true
      end
    end

    def list
      raise NeedLogin unless is_loggedin?

      datas = []
      response = get(myfiles_path)
      key = response.body.match(/var eU ?= ?'(.*?)';/)[1]
      response.body.scan(/es\[\d+\]=Array\((.*?)\);/).each do |n|
        data = eval("[#{n[0]}]")
        datas.push StoreObject.new(data)
      end
      root_folder = ['1', '2', '0', key, key, 'myfiles', '0'].fill('', 7..20)
      @root_folder = StoreObject.new(root_folder)
      return datas
    end

    def delete(files)
      raise NeedLogin unless is_loggedin?

      form_option = {
        :form_todolist1 => create_list(files),
        :form_todolist2 => '',
        :form_todotype => 1,
        :form_todoparent => '',
        :form_todoconfirm => '',
      }
      options = api_options[:doselected].merge(form_option)
      response = post('dynamic/doselected.php', options)

      if response.body.match(/et ?= ?15;/)
        true
      else
        false
      end
    end

    def move(files, folder)
      raise NeedLogin unless is_loggedin?

      form_option = {
        :move_dest_navbar_filelist => folder.quickkey,
        :move_list => create_list(files),
        :Move => 'Move To Folder',
      }
      options = api_options[:move2folder].merge(form_option)
      response = post('dynamic/move2folder.php', options)
      if response.body.match(/et ?= ?15;/)
        true
      else
        false
      end
    end

    # @param options {:filename, :description, :tags, :password}
    def edit_fileoption(file, options)
      raise NeedLogin unless is_loggedin?

      new_options = {
        :todotype => file.objecttype,
        :todoquickkey => file.quickkey,
        :todofilename => file.name,
        :filename => options[:filename] || file.name,
        :desc => options[:description] || file.description,
        :tags => options[:tags] || file.tags,
        :password => options[:password] || file.password,
      }

      if new_options[:desc].size > 200
        puts 'Error: description too long'
        return
      end

      if new_options[:tags].size > 100
        puts 'Error: tags too long'
        return
      end

      response = post('dynamic/dofileoptions.php', new_options)
      if response.body.match(/et ?= ?15;/)
        true
      else
        false
      end
    end

    # @param note {:subject, :description}
    def edit_note(file, note)
      raise NeedLogin unless is_loggedin?

      options = {
        :subject => note[:subject] || file.note_subject,
        :description => note[:description] || file.note_description,
      }
      if options[:description].length > 10000
        puts "Error: description too long"
        return
      end
      type = file.is_folder? ? 'folder' : 'file'
      post("dynamic/editfilenotes.php?quickkey=#{file.quickkey}&t=#{type}", options)
      return true
    end

    def create_folder(name, folder)
      raise NeedLogin unless is_loggedin?

      options = {
        :new_folder_parent => folder.folderkey,
        :new_folder_name => name,
      }
      response = post("dynamic/createfolder.php", options)
      unless response.body.match(/et ?= ?15;/)
        return nil
      end

      quickkey = response.body.match(/var ia='(.*?)';/)[1]
      date = Time.now.gmtime.strftime("%m/%d/%Y")
      fquickkey = response.body.match(/var mO='(.*?)';/)[1]

      data = ['1', '2', 0, quickkey, folder.folderkey, name, '0', '', '',
              '', date, '0', '', '', '', fquickkey, '0', '0', '', '', '']
      StoreObject.new(data)
    end

    def toggle_acl(file, recursive=false)
      raise NeedLogin unless is_loggedin?

      if file.access_type == '0'
        access_type = '1'
      else
        access_type = '0'
      end
      query = "quickkey=#{file.quickkey}&acl=#{access_type}&type=#{file.objecttype}"
      if recursive && file.is_folder?
        query << "&recursive=1"
      end
      response = get("dynamic/doaclchange.php?#{query}")
      if response.body.match(/et ?= ?15;/)
        true
      else
        false
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
          keys[:folderkey] = folder.folder_quickkey
        end
      end
      keys[:mful_config] = doc.xpath('//mediafire/MFULConfig').text

      query = "type=basic"
      query << "&ukey=#{keys[:ukey]}&user=#{keys[:user]}"
      query << "&uploadkey=#{keys[:folderkey]}"
      query << "&filenum=0&uploader=0"
      query << "&MFULConfig=#{keys[:mful_config]}"
      response = File.open(filepath) do |f|
        options = {:Filedata => UploadIO.new(f, 'application/octet-stream', filename)}
        post("douploadtoapi?#{query}", options)
      end
      doc = Nokogiri::XML(response.body)
      keys[:filekey] = doc.xpath('//response/doupload/key').text

      if keys[:filekey] == ''
        puts "Error: upload failed."
        return nil
      end

      keys[:quickkey] = nil
      query = "key=#{keys[:filekey]}&MFULConfig=#{keys[:mful_config]}"
      while keys[:quickkey] == nil || keys[:quickkey] == ''
        response = get("basicapi/pollupload.php?#{query}")
        doc = Nokogiri::XML(response.body)
        keys[:quickkey] = doc.xpath('//response/doupload/quickkey').text
        keys[:size] = doc.xpath('//response/doupload/size').text
        sleep 0.5
      end

      options = {
        :filename => filename,
        :quickkey => keys[:quickkey],
      }
      response = post("basicapi/getfiletype.php?MFULConfig=#{keys[:mful_config]}", options)
      doc = Nokogiri::XML(response.body)
      keys[:filetype] = doc.xpath('//response/file/filetype').text
      keys[:sharekey] = doc.xpath('//response/file/sharekey').text
      keys[:r_size], keys[:r_sizeunit] = filesize_to_readable_filesize(keys[:size].to_i)

      data = ['1', '1', keys[:filetype], keys[:quickkey], '', filename, keys[:size], 
              keys[:r_size], keys[:r_sizeunit], '0', Time.now.gmtime.strftime("%m/%d/%Y"),
              '0', '', '', '', keys[:sharekey], '0', '0', '', '', '']
      StoreObject.new(data)
    end

    #def webupload(url, folder)
    #end

    def download(file)
      if file.is_a?(Array)
        return downloads(file)
      end

      response = get("?#{file.quickkey}")
      if response.code.to_i == 302
        return response['Location']
      end

      body = response.body
      funcbody = body.scan(/ function .*?for.*?eval/)
      functions = funcbody.map {|n| n.match(/function (.*?)\(/).to_a[1]}
      decrypt_str = funcbody.map {|n| find_encrypt_string_and_decrypt(n)}

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

      response = get("imgbnc.php/#{file.imagekey}#{size.to_s}g.jpg")
      response['Location']
    end

    def update(src, dest)
      raise NeedLogin unless is_loggedin?

      option = {
        "file_a" => src.quickkey,
        "file_b" => dest.quickkey,
      }
      response = post('dynamic/updatefile.php', option)
      if response.body.match(/et ?= ?15;/)
        true
      else
        false
      end
    end

    def image_rotation(file, rotation)
      raise NeedLogin unless is_loggedin?

      unless file.is_picture?
        puts "Error: file is not a picture."
        return
      end

      unless ratation == 0 || ratation == 90 || ratation == 180 || ratation == 270
        puts "Error: rotation need 0 or 90 or 180 or 270"
        return
      end

      get("dynamic/imagerotation.php?imgkey=#{file.imagekey}&newrotation=#{ratation.to_s}&nocache=#{rand.to_s}")
      return true
    end

    def save_file_to_my_account(quickkey)
      raise NeedLogin unless is_loggedin?

      response = get("dynamic/savefile.php?qk=#{quickkey}&status=statusmessage")
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
        :dbx_status_id => folder.folder_quickkey,
      }
      response = post('dropbox/dosetupdropbox.php', options)
      if response.body.match(/et ?= ?15[012];/)
        true
      else
        false
      end
    end

    # return Dropbox ID
    def dropbox_setup_option(folder, options)
      raise NeedLogin unless is_loggedin?

      response = post('dropbox/dosetupdropbox.php', {:dbx_folderid => folder.folder_quickkey})
      folder_options = eval("[#{response.body.match(/parent.Bl\((.*?)\);break;/)[1]}]")

      allow_add_description = options[:allow_add_description] ? 1 : 0
      multiple_upload = options[:multiple_upload] ? 1 : 0
      email_notification = options[:email_notification] ? 1 : 0
      form_options = {
        :dbx_folder => folder.folder_quickkey,
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

      query = "type=basic"
      query << "&track=#{keys[:trackkey]}&dropbox=1"
      query << "&ukey=#{keys[:ukey]}&user=#{keys[:user]}"
      query << "&uploadkey=#{dropbox_id}&upload=0"
      response = File.open(filepath) do |f|
        options = {:Filedata => UploadIO.new(f, 'application/octet-stream', filename)}
        post("douploadtoapi?#{query}", options)
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

    def is_loggedin?
      @loggedin
    end

    private

    def create_list(files)
      f = files
      f = [f] unless f.is_a?(Array)
      f.map {|n| "#{n.objecttype}:#{n.quickkey}"}.join(';')
    end

    def myfiles_path
      response = get('myfiles.php')
      '' + /js\/myfiles.php.[^"]*/.match(response.body)[0]
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
