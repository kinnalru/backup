$config.tap do |config|
  config.src = '/mnt/drives/data2/documents/photo/'
  config.dst = '/mnt/drives/backups/BackupDisk1/photo/'
  config.nomore = 24 * 7 # не чаще 1 раза в неделю
  config.before = 'mount /mnt/drives/backups/BackupDisk1 || echo ok'
end
