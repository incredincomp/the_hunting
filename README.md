# the_hunting
a *cheap* vuln finding robot

# Requirements

* Axiom https://github.com/pry0cc/axiom
* DigitalOcean Account
* Some API keys if you want good results for subdomain enum

# Commands
## Axiom
Start your axiom droplet

`axiom-init`

Connect to your axiom droplet

`axiom-ssh <instance> --tmux`

## Set up `the_hunting`
`git pull https://github.com/incredincomp/the_hunting`

`cd ~/the_hunting`

`chmod +x install.sh the_hunting.sh`

need sudo for program installs with apt

`sudo ./install.sh`
