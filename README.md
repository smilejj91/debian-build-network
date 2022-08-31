# debian-build-network

1. wanna-build
 - wanna-build is build network's master node
 - pre-condition : DAK (https://github.com/smilejj91/dak-setting)

2. buildd
 - buildd is build network's slave node
 - pre-condition : wanna-build, DAK, dupload
  - dupload : modify uploadqueue address in /etc/dupload.conf
