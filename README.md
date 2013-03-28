swiftrotate
===========

Adventures in Logrotate and swift.

* prerotate.py - Utility script which datestamps a collection of files that have been logrotated, but were rotated without dateext.
* swiftrotate.sh - Script to add to to logrotate.conf postrotate.
* .swiftrotate.example - Contains example configuration values required by swiftrotate.sh

Just add the full path to swiftrotate.sh to the postrotate directive.

Example logrotate configuration for fail2ban:

	/var/log/fail2ban.log {
        daily
        rotate 4
        dateext
        compress

        delaycompress
        missingok
        postrotate
            fail2ban-client set logtarget /var/log/fail2ban.log >/dev/null
            /usr/local/bin/swiftrotate.sh
        endscript
        create 640 root adm
        }

Force logrotate:

		sudo /usr/sbin/logrotate -dv --force /etc/logrotate.conf