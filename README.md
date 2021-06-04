# monomash
hack scripts for making monorepos. various parts ripped from:

- https://github.com/hraban/tomono/
- https://github.com/gigamonkey/monorepoize

# Configuration
```
export MONOREPO_NAME=<resulting-monorepo-name, defaults  to core>
export DEBUGSH=1
```

# Merging branches in the monorepo afterwards
Use the `teleport.sh` script, like:

```
gteleport.sh ~/pete/oldrepo myfeature develop ~/pete/monorepo main ~/pete/monorepo/oldrepo
```

# Full history
```
git log --follow
```


