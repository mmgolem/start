# start

The first step of a new Golem machine. On a fresh Ubuntu 24.04+ or Debian 13+ server, as root:

```bash
curl -fsSL https://raw.githubusercontent.com/mmgolem/start/main/start.sh | bash
```

`start.sh` makes the user `golem`, installs git and gh, signs in to GitHub, clones the private setup
repo and runs its install script. Everything else lives there; this repo holds nothing secret.
