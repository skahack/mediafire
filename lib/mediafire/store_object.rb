module Mediafire
  class StoreObject
    def initialize(d)
      data(d)
    end

    def data(d)
      @created     = d['created'] || ''
      @tags        = d['tags']    || ''
      @description = d['desc']    || ''
      @privacy     = d['privacy'] || ''
    end

    def is_folder?
      if @data.key?('folder_key')
        true
      else
        false
      end
    end

    def date
      @created
    end

    def tags
      @tags
    end

    def description
      @description
    end

    def is_public?
      if @privacy == 'public'
        true
      else
        false
      end
    end
  end

  class StoreFolder < StoreObject
    def data(d)
      super(d)

      folders = []
      files = []

      if d.key?('folders')
        d['folders'].each do |f|
          folders << StoreFolder.new(f)
        end
      end

      if d.key?('files')
        d['files'].each do |f|
          files << StoreFile.new(f)
        end
      end

      @folders         = folders
      @files           = files

      @name            = d['name']            || ''
      @key             = d['folderkey']       || ''
      @dropbox_enabled = d['dropbox_enabled'] || ''
      @custom_url      = d['custom_url']      || ''
      @revision        = d['revision'].to_i
      @file_count      = d['file_count'].to_i
    end

    def is_folder?
      true
    end

    def folder_key
      @key
    end
    alias :folderkey :folder_key
    alias :key :folder_key

    def name
      @name
    end

    def dropbox_enabled?
      if @dropbox_enabled == 'yes'
        true
      else
        false
      end
    end

    def revision
      @revision
    end

    def file_count
      @file_count
    end

    def custom_url
      @custom_url
    end

    def folders
      @folders
    end

    def files
      @files
    end
  end

  class StoreFile < StoreObject
    def data(d)
      super(d)

      @filetype           = d['filetype']           || ''
      @key                = d['quickkey']           || ''
      @name               = d['filename']           || ''
      @password_protected = d['password_protected'] || ''
      @hash               = d['hash']               || ''
      @size               = d['size'].to_i
      @downloads          = d['downloads'].to_i
    end

    def filetype
      @filetype
    end

    def is_folder?
      false
    end

    def is_picture?
      if @filetype == 'image'
        true
      else
        false
      end
    end

    def quick_key
      @key
    end
    alias :quickkey :quick_key
    alias :key :quick_key

    def name
      @name
    end

    def size
      @size
    end

    def downloads
      @downloads
    end

    def protected?
      if @password_protected == 'yes'
        true
      else
        false
      end
    end

    def hash
      @hash
    end
    alias :imagekey :hash
  end
end
