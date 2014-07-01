# Original from https://github.com/zroger/jekyll-less

require 'less'

module Jekyll
  class LessCssFile < StaticFile
    attr_accessor :compress

    # Obtain destination path.
    #   +dest+ is the String path to the destination dir
    #
    # Returns destination file path.
    def destination(dest)
      File.join(dest, @dir, @name.sub(/less$/, 'css'))
    end

    # Convert the less file into a css file.
    #   +dest+ is the String path to the destination dir
    #
    # Returns false if the file was not modified since last time (no-op).
    def write(dest)
      dest_path = destination(dest)

      return false if File.exist? dest_path and !modified?
      @@mtimes[path] = mtime

      FileUtils.mkdir_p(File.dirname(dest_path))
      begin
        content = File.read(path)
        content = ::Less::Parser.new({:paths => [File.dirname(path)]}).parse(content).to_css :compress => compress
        File.open(dest_path, 'w') do |f|
          f.write(content)
        end
      rescue => e
        STDERR.puts "Less Exception: #{e.message}"
      end

      true
    end
  end

  class LessCssGenerator < Generator
    safe true

    # Initialize options from site config.
    def initialize(config = {})
      @options = {"compress" => true}.merge(config["less"] ||= {})
    end

    # remove already added .less files from static files and readd
    # main.less again (but with instructions to compile it with less)
    def generate(site)
      site.static_files.clone.each do |sf|
        if sf.kind_of?(Jekyll::StaticFile) && sf.path =~ /\.less$/
          # remove less file from static files
          #site.static_files.delete(sf)

          # create less static file only for main.less
          if sf.path =~ /main\.less$/
            name = File.basename(sf.path)
            destination = File.dirname(sf.path).sub(site.source, '')
            less_file = LessCssFile.new(site, site.source, destination, name)
            less_file.compress = @options["compress"]
            site.static_files << less_file
          end
        end
      end
    end
  end
end
