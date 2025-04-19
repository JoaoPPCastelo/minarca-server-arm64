# Status

The goal of this page is to keep track of the issues faced when building the image and getting (or tryong) to get minarca working

## Issues

**Issue:** Error installing minarca-server.deb with apt

**Status:** Fixed

**Description:**
```
dpkg: error processing archive /tmp/apt-dpkg-install-8t4Xzo/44-minarca-server.deb (--unpack):
 unable to move aside './opt/minarca-server/minarca-server' to install new version: Invalid cross-device link
dpkg-deb: error: paste subprocess was killed by signal (Broken pipe)
```

---

**Issue:** start.sh stuck on the first step

**Status:** Fixed

**Description:**

The first step of the `start.sh` get's stuck. Running manually the command `su nobody -s /bin/sh -c "unshare --user --net"` returns the error
```
sh: 0: can't access tty; job control turned off
``` 

Seems to be an issue when running `docker run -it ...`. Without the `-it` it works fine.

---

**Issue:** Can't start minarca-server from start.sh

**Status:** Fixed

**Description:** When running the script, the step to start minarca-server using the minarca user fails with `/opt/minarca-server/minarca-server: /opt/minarca-server/minarca-server: cannot execute binary file`