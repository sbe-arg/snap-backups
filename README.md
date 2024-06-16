# snap-backups

A very basic tool for taking, moving and restoring snap apps backups.

```bash
# backup
sudo ./snap-backup.sh --apps app1,app2,app2 --dest /some/location/folder
# restore
sudo ./snap-restore.sh --app appname --source /some/location/of/file
```

Example:
```bash
sudo crontab -e
0 2 * * * /path/to/snap-backup.sh --apps app1,app2 --dest /backup/snaps

# to restore run
sudo /path/to/snap-restore.sh --app app1 --source /backup/snaps/902-nextcloud-2023-12-12-033055
```

NOTE: Some snaps run as services, they will be stopped when the backup is taken. They will be started again when the restore is done. This is done to ensure the backup is consistent. But it may cause some downtime.

If snap saved appname finds more than 1 snapshot. It will try to grab the latest one but might behave unexpectedly. Do your due diligence and cleanup your environment using snap saved, snap forget commands.

## disclaimer

You are running this at your own risk. I am not responsible for any data loss or any other issues that may arise from using this tool.
It needs to run as sudo because by default /var/lib/snapd/snapshots/ is armored and because stopping and starting services on snaps requires it. Make sure you understand what you are doing before running this.

I have personally been running this to backup my nextcloud snap both to an external drive and over an automount remote network drive for a while as cron root, and it has been working fine for me. But I can't guarantee it will work for you.

If you run this as normal user it will ask for sudo password several times when needed. On each start,stop,save,export,import operation.
