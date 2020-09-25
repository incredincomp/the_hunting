# Building Digital Ocean Image

There is a [Packer](https:/github.com/hashicorp/packer) template available that will build a DigitalOcean image and store it as `the_thunting-{{timestamp}}`. This can be used for development and testing.

## Setup Environment

The only requirement is that `$DIGITALOCEAN_ACCESS_TOKEN` is properly set in the environment. If you have `yq` installed it is quite simple.

MacOS

```bash
export DIGITALOCEAN_ACCESS_TOKEN="$(yq r "${HOME}/Library/Application Support/doctl/config.yaml" access-token)
```

Linux

```bash
export DIGITALOCEAN_ACCESS_TOKEN="$(yq r "${HOME}/.config/doctl/config.yaml" access-token)
```

or you can use `awk`

MacOS

```bash
export DIGITALOCEAN_ACCESS_TOKEN="$(awk '/access-token/ {print $2}' "${HOME}/Library/Application Support/doctl/config.yaml")"
```

Linux

```bash
export DIGITALOCEAN_ACCESS_TOKEN="$(awk '/access-token/ {print $2}' "${HOME}/Library/Application Support/doctl/config.yaml")"
```

## Building Image

Simply run the `build` make target.

```bash
make build
```
