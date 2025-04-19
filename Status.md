# Status

The goal of this page is to keep track of the issues faced when building the image and getting (or tryong) to get minarca working

### Issues

- Issue when installing the minarca-server.deb on the final container - FIXED
```
dpkg: error processing archive /tmp/apt-dpkg-install-8t4Xzo/44-minarca-server.deb (--unpack):
 unable to move aside './opt/minarca-server/minarca-server' to install new version: Invalid cross-device link
dpkg-deb: error: paste subprocess was killed by signal (Broken pipe)
```

- The first step of the `start.sh` get's stuck. Running manually the command `su nobody -s /bin/sh -c "unshare --user --net"` returns the error
```
sh: 0: can't access tty; job control turned off
```