module Defile
  module Backend
    class FileSystem
      def initialize(directory, max_size: nil, hasher: Defile::RandomHasher.new)
        @hasher = hasher
        @directory = directory
        @max_size = max_size

        FileUtils.mkdir_p(@directory)
      end

      def upload(uploadable)
        Defile.verify_uploadable(uploadable, @max_size)

        id = @hasher.hash(uploadable)

        if uploadable.respond_to?(:path) and ::File.exist?(uploadable.path)
          FileUtils.cp(uploadable.path, path(id))
        else
          ::File.open(path(id), "wb") do |file|
            buffer = "" # reuse the same buffer
            until uploadable.eof?
              uploadable.read(Defile.read_chunk_size, buffer)
              file.write(buffer)
            end
            uploadable.close
          end
        end

        Defile::File.new(self, id)
      end

      def get(id)
        Defile::File.new(self, id)
      end

      def delete(id)
        FileUtils.rm(path(id)) if exists?(id)
      end

      def open(id)
        ::File.open(path(id), "rb")
      end

      def read(id)
        ::File.read(path(id)) if exists?(id)
      end

      def size(id)
        ::File.size(path(id)) if exists?(id)
      end

      def exists?(id)
        ::File.exists?(path(id))
      end

      def clear!(confirm = nil)
        raise ArgumentError, "are you sure? this will remove all files in the backend, call as `clear!(:confirm)` if you're sure you want to do this" unless confirm == :confirm
        FileUtils.rm_rf(@directory)
        FileUtils.mkdir_p(@directory)
      end

      def path(id)
        ::File.join(@directory, id)
      end
    end
  end
end
