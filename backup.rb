#!/usr/bin/ruby

require 'optparse'
require 'ostruct'
require 'time'
require 'fileutils'

opts = OpenStruct.new
parser = nil

rest = OptionParser.new do |o|
  parser = o

  o.banner = "Usage: #{File.basename($0)} [options] [command]"
  o.on('-s', '--src PATH', "What to backup") { |v| opts.src = v }
  o.on('-d', '--dst PATH', "Where to backup") { |v| opts.dst = v }
  o.on('-c', '--config FILENAME', 'Config file') {|v| opts.config = v}
  o.on('-h') { puts parser; exit }

  o.separator ""
  o.separator "Commands:"
  o.separator "    du       Show destination space usage"
  o.separator "    diff     Show diff between source and distination"
end.parse!

if opts.config
  $config = OpenStruct.new
  require_relative opts.config
  opts = OpenStruct.new($config.to_h.merge(opts.to_h))
end

if cmd = rest.first
  opts.cmd = cmd
end

puts opts

if opts.dst.nil? || opts.dst.empty?
  puts parser
  raise "You must specify destination path"
end

if opts.cmd == "du"
  system("du -h -c -d 1 #{opts.dst}")
  exit $?.exitstatus
elsif opts.cmd == "diff"
  system("rsync --archive --dry-run --verbose --one-file-system #{opts.src} --delete #{opts.dst}/latest/")
  exit $?.exitstatus
elsif opts.cmd
  raise "there is no command #{opts.cmd}"
end

if opts.src.nil? || opts.src.empty?
  puts parser
  raise "You must specify source path"
end

unless File.exist?("#{opts.dst}")
	raise "there is no destination: #{opts.dst}"
end

#lastreplica = Dir["#{opts.dst}/*"].map{ |f| File.mtime(f) }.sort.first rescue nil
lastreplica = File.mtime("#{opts.dst}/latest/") rescue nil


if lastreplica && opts.nomore && (Time.now - lastreplica) < opts.nomore * 36000.0
  puts "skip by nomore option"
  exit 0
end

def execute cmd
  system cmd
  return $?.exitstatus == 0
end

def execute_or_fail cmd
  raise "Failed: #{cmd}" unless execute(cmd)
end

def sync opts
  execute_or_fail(opts.before) if opts.before

  execute_or_fail("mkdir -p #{opts.dst}/latest/")

  cmd = "rsync --archive --one-file-system -h --stats --info=progress2 #{opts.src} --delete #{opts.dst}/latest/"
  execute_or_fail(cmd)

  date = Time.now.strftime("%Y.%m.%d-%H%M%L")
  cmd = "cp --archive --link #{opts.dst}/latest/ #{opts.dst}/#{date}"
  execute_or_fail(cmd)

  execute_or_fail(opts.after) if opts.after
end

sync(opts)

exit 0

