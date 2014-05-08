require 'net/ftp'
require 'optparse'
require 'logger'
require 'yaml'

class FtpDownloader < Net::FTP
  attr_reader :options, :items

  def initialize
    @options = {}
    @env = :full_sb
    @folders = {
        full_sb: 'FullSandbox',
        prod: 'Production',
        product: 'Product',
        specialty: 'Specialty'
    }
    @connection = {
        host: '5.9.155.211',
        user: 'ftpuser',
        pwd: 'kdffgDjdfg978D'
    }

    parse_argv
    load_config
    super(@connection[:host], @connection[:user], @connection[:pwd])
  end

  def load_config
    begin
      @names = YAML.load_file('config.yml')
    rescue Errno::ENOENT => e
      puts 'no config file, please provide'
      exit
    end
    @names.each { |k, v| @names[k] = v.split ' ' }
  end

  def parse_argv
    option_parser = OptionParser.new do |opts|
      opts.on('--names [ARG]')  { |v| @items = v.split ',' }
      opts.on('--env [ARG]')    { |v| @env = :prod if v =~ /prod/ }
      opts.on('--build [ARG]')  { options[:build] = true }
      opts.on('-h', '--help') { puts 'tool for building abbot presentations'; exit }
    end
    begin
      option_parser.parse!(ARGV)
    rescue OptionParser::InvalidOption => e
      # puts 'shit!!!'
    end
  end

  def remote_path(type)
    puts "#{@folders[@env]}/#{@folders[type]}/"
  end
  private :remote_path

  def local_path(type, item = '')
    path = if type == :specialty
             "abbott_scenario_builder/"
           else
             ""
           end
    "#{path}packs/#{item}.zip"
  end
  private :local_path

  def load_packs
    @items.each do |item|
      item.slice! '.json'
      type = if is_product?(item)
               :product
             elsif is_specialty?(item)
               :specialty
             else
               puts 'there is no such product'
               nil
             end
      if type
        path_to_file = local_path(type, item)
        unless File.exist?(path_to_file)
          puts "no such zip #{path_to_file}"
          next
        end
        chdir "/#{remote_path(type)}"
        puts "downloaded #{path_to_file}"
        #put path_to_file
      end
    end

  end

  def is_product?(item)
    @names['product'].include?(item)
  end

  private :is_product?

  def is_specialty?(item)
    @names['specialty'].include?(item)
  end

  private :is_specialty?

  def build(names, opts = {})
    opts.merge!(zip: 'pack')
    `python builder.py #{opts[:zip]} names=#{names}`
    puts "file(s) #{names} was builded"
  end

end

ftp_downloader = FtpDownloader.new
ftp_downloader.load_packs
#puts ftp_downloader.closed?