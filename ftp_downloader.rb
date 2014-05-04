require 'net/ftp'
require 'optparse'
require 'git'
require 'logger'

class FtpDownloader < Net::FTP
  attr_reader :options, :curr_connect

  def initialize
    @options = {}
    @connection_opts = {
      full_sb: {
        host: 'my_host.com',
        user: 'i',
        pwd: '***'
      },
      prod: {
        host: 'my_host_prod.com',
        user: 'she',
        pwd: '*****'
      }
    }
    @default_opts = {
      verbose: false,
      env: :full_sb
    }
    @options.merge!(@default_opts)
    @curr_connect = @connection_opts[@options[:env]]
    @products = ['klacid', 'ontime', 'irs']
    @specialities = ['gi', 'ge']
    super(@curr_connect[:host], @curr_connect[:user], @curr_connect[:pwd])
  end

  def load_packs(*args)
    args.each do |pack|
      if @products.include? pack
        chdir('products')
        pull(pack)
      else
        chdir('speciality')
      end
      build("", zip: false)
      put(pack)
      puts "file #{pack} was downloaded to the server"
    end
  end

  def pull(dir, branch = "master")
    # g = Git.open(pack, log: Logger.new(STDOUT))
    g.pull(dir, branch)
  end

  def build(names, opts = {})
    opts.merge!(zip: 'pack')
    `python builder.py #{opts[:zip]} names=#{names}`
    puts "file(s) #{names} was builded"
  end

end

ftp_downloader = FtpDownloader.new
puts ftp_downloader.options