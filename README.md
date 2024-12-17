
## mtp-device

The files configure a Raspberry Pi with OTG support as MTP storage or
USB ethernet device.  _systemd_ service installation is supported.

The gadget's compatibility matrix is

  | Type   |  Linux  |  Windows |
  | ------ | ------- | -------- |
  | eth    |   yes   |    no    |
  | rndis  |   yes   |    yes   |
  | mtp    |   yes   |    yes   |

so effectiveliy rndis is the safe solution for USB network.  Ubuntu
22.04, Rasbian/11 and Windows 10 were used as host OS.  Raspberry Pi
Zero and Zero 2 running bullseye/11 (umtprd/1.3.10) and bookworm/12
(umtprd/1.6.2) Raspbian were used for the gadget.


### Configuration

The gadget mode is configured inside the script _activate-gadget_:

    MODE=mtp

Change the value from `mtp` to `rndis` or `eth` to select USB netorking
instead of MTP storage.

 - MTP: _umtprd_ exports _/home/pi_.  Edit _umtprd.conf_ to change or
   add other directories.
 
 - Networking: _activate-gadget_ configures the gadget's IP address to
   169.254.233.90/16.  _start.sh_ starts a DHCP server to assign an IP
   in the range from 169.254.233.90 - .254 to the USB host.

### Installation

 1. Store the files in a directory of your choice.
 2. For MTP usage: Install _umtprd_: `sudo apt-get install
    umtp-responder`.
 3. Add `dtoverlay=dwc2` to the system's _config.txt_.
 4. Run `sudo ./systemd-service install` to install the _systemd_
    service.  `./systemd-service show` displays the unit file.
 5. Reboot.
 6. Be patient if you have a Raspberry Zero.  mtp-device needs approx.
    36 seconds from power-on to the MTP device appearing on the host.
    It's about 16 seconds on a Raspberry Zero 2.

Raspbian's version of _umtprd_ is old and lacks options to control the
file ownership.  Effectively all files created are owned by root.  A
newer version is available on [Github][1], which implements appropriate
options but needs to be compiled by yourself.

`sudo ./start.sh` starts the gadget ad-hoc without installing it as
service.

_activate-gadget_ will not switch to gadget mode if it finds any devices
on the USB bus.  Furthermore, it does not reset any existing
configuration; only a reboot will do this.

 [1]: https://github.com/viveris/uMTP-Responder


### Files

 - activate-gadget configures the gadget.
 - start.sh is the _systemd_'s unit executable.
 - systemd-service installs and uninstalls the service unit.
 - umtprd.conf is _umtprd_'s configuration file.


