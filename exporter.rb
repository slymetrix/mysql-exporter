#!/usr/bin/env ruby
require 'mysql2'
require 'csv'
require 'optparse'
require 'io/console'

@options = {
    :database_timezone => :utc,
    :application_timezone => :utc
}

OptionParser.new do |opts|
    @opts = opts

    opts.banner = 'Usage exporter.rb <options> <query>'

    opts.on('-HHOST', '--host=HOST', 'Hostname') do |n|
        @options[:host] = n
    end

    opts.on('-uUSER', '--user=USER', 'Username') do |n|
        @options[:username] = n
    end

    opts.on('-dNAME', '--database=NAME', 'Database name') do |n|
        @options[:database] = n
    end

    opts.on('-pPORT', '--port=PORT', 'Port number') do |n|
        @options[:port] = n.to_i
    end

    opts.on('-sPATH', '--socket=PATH', 'Path to unix socket') do |n|
        @options[:socket] = n
    end

    opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
    end
end.parse!

if ARGV.size != 1
    puts @opts
    exit 1
end

@query = ARGV[0]

@options[:password] = STDIN.getpass('Password: ')

client = Mysql2::Client.new(**@options)
result = client.query(@query, :stream => true)

CSV($stdout) do |csv|
    fields = result.fields
    csv << fields

    result.each do |row|
        values = fields.map do |field|
            if row[field].is_a? Time
                row[field].strftime('%Y-%m-%d %H:%M:%S')
            elsif row[field].is_a? Date
                row[field].strftime('%Y-%m-%d')
            elsif row[field].is_a? BigDecimal
                '%f' % row[field]
            else
                row[field]
            end
        end

        csv << values
    end
end
