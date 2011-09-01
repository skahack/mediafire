module Mediafire
  class StoreObject
    L = {
      # ??? => 0,
      :objecttype => 1,
      :filetype => 2,
      :quickkey => 3,
      :folderkey => 4,
      :filename => 5,
      :filesize => 6,
      :readable_filesize => 7,
      :readable_filesize_unit => 8,
      :downloads => 9,
      :upload_date => 10,
      :access_type => 11,
      :tags => 12,
      :description => 13,
      :password => 14,
      :imagekey => 15, :folder_quickkey => 15,
      :dropbox_enabled => 16,
      :image_rotation => 17, :custom_url => 17,
      # ??? => 0,
      :note_subject => 19,
      :note_description => 20,
    }

    def initialize(d)
      data(d)
    end

    def data(d)
      if d.is_a?(Array) && d.size == 21
        @data = d
      end
    end

    def objecttype
      @data[L[:objecttype]]
    end

    def is_folder?
      if objecttype == '2'
        return true
      end
      return false
    end

    def filetype
      # 1 : picture
      # 9 : compress file
      # 0 : other
      @data[L[:filetype]]
    end

    def is_picture?
      if filetype == '1'
        return true
      end
      return false
    end

    def quickkey
      @data[L[:quickkey]]
    end

    def folderkey
      @data[L[:folderkey]]
    end

    def name
      @data[L[:filename]]
    end

    def size
      "#{@data[L[:readable_filesize]]}#{@data[L[:readable_filesize_unit]]}"
    end

    def downloads
      @data[L[:downloads]].to_i
    end

    def date
      @data[L[:upload_date]]
    end

    def tags
      @data[L[:tags]]
    end

    def description
      @data[L[:description]]
    end

    def password
      @data[L[:password]]
    end

    def imagekey
      @data[L[:imagekey]]
    end

    def folder_quickkey
      @data[L[:folder_quickkey]]
    end

    def dropbox_enabled
      if @data[L[:dropbox_enabled]] == '1'
        return true
      end
      return false
    end

    def access_type
      @data[L[:access_type]]
    end

    def is_public?
      if access_type == '0'
        return true
      end
      return false
    end

    def image_rotation
      # 0
      # 90
      # 180
      # 270
      @data[L[:image_rotation]]
    end

    def folder_quickkey
      @data[L[:folder_quickkey]]
    end

    def note_subject
      @data[L[:note_subject]]
    end

    def note_description
      @data[L[:note_description]]
    end
  end
end
