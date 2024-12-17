#!/bin/sh
#

dir=`dirname $0`
cd $dir  ||  exit 1

export BASE="$PWD"
PATH="$BASE:$PATH"

export HOME=/home/$USER

# This is the effective user.
USERNAME=pi

# Set a unique key for this run.
export SESSION_KEY=`date +'%Y%m%d-%H%M%S'`


# Redirect all script/program output into
# a logfile for later inspection (and removal).
progname=`basename $0 .sh`
if ! tty -s; then
    LOG=$progname-"$SESSION_KEY".log
    exec >$LOG 2>&1
    chown $USERNAME $LOG
fi


# Keep all logfiles from today plus 6 older logs and
# remove the others.  "Today" is difficult if the raspi
# runs without network but you should have access to the
# relevant log in case of an issue.  Even with network
# date and time may be not correct because setting time
# happens usually early after the system startup.
LIST=`ls -1r $progname-*.log |
	awk '/./ {
		split($0, x, "-");
		if (NR == 1)
			today = x[2];
		else if (x[2] == today)
			;
		else if (n < 6)
			n++;
		else
			print $0
		}'`
if [ "$LIST" != "" ]; then
    rm $LIST
fi


{ date; pwd; whoami;
  echo;
  env | sort;
  echo; }



# Configure the MTP gadget
./activate-gadget


# If the have a USB serial start a getty.
test -c /dev/ttyGS0  &&  systemctl start getty@ttyGS0.service


# Network or MTP?
if ip addr | awk '$0 ~ /^[0-9]+: usb0: / { f = 1 } END { exit (f == 1? 0: 1) }';
then
	touch udhcpd.leases
	# This is an ethernet device.  Provide a DHCP server.
	cat <<-EOF |
		interface     usb0
		start         169.254.1.20
		end           169.254.1.254
		pidfile       udhcpd.pid
		lease_file    udhcpd.leases
		EOF
	exec busybox udhcpd -f -S /dev/stdin
else
	# This is for MTP.
	#
	# umtprd requires a parameter that changes with the Raspberry model.
	# This script updates the configuration file.  It checks if the
	# device name is different first.
	export CONF="./umtprd.conf"

	/usr/bin/awk 'BEGIN {
		# This is the config file.
		CONF = ENVIRON["CONF"];

		# Get the USB device.
		cmd = "ls -1 /dev/gadget/*.usb";
		cmd | getline dev;  close (cmd);
		if (dev == "") {
			printf ("-ERR: USB device not found\n") >>"/dev/stderr";
			exit (1);
			}

		# Read the configuration.
		while (getline line <CONF > 0) {
			if (match(line, /^ *usb_dev_path +"/) > 0) {
				p = substr(line, RLENGTH + 1);
				sub(/".*$/, "", p);
				if (p == dev) {
					printf ("device already configured: %s\n", dev);
					exit (0);
					}

				printf ("replacing %s with %s\n", p, dev);
				line = sprintf ("usb_dev_path \"%s\"", dev);
				}

			D = D line "\n";
			}

		close (CONF);

		printf ("%s", D) >CONF;
		close (CONF);

		exit (0);
		}'

	# This would make a similar job but change the config file
	# every time.
	#DEV=$(ls -1 /sys/class/udc)
	#sed -i~ -E "s|^ *usb_dev_path +.*\$|usb_dev_path \"$DEV\"|" umtprd.conf


	# Start the server.
	exec /usr/bin/umtprd -conf "$CONF"
fi

exit 1

