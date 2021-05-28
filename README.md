# monomash
hack scripts for making monorepos. various parts ripped from:

- https://github.com/hraban/tomono/
- https://github.com/gigamonkey/monorepoize

# Configuration
```
export MONOREPO_NAME=<resulting-monorepo-name, defaults  to core>
export DEBUGSH=1
```
# Using the script
pass <repository url> <remote name> <destination directory> on stdin

Can also be `source`d

# Merging branches in the monorepo afterwards
Use the `teleport.sh` script, like:

```
teleport.sh ~/pete/oldrepo myfeature ~/pete/monorepo main
```

# Full history
```
git log --follow
```


