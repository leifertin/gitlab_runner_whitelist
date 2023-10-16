# GitLab Runner Whitelist
Fetches GitLab Runner IPs for use in SSH whitelist and adds them to `ufw`

Requires JQ
https://jqlang.github.io/jq/download/

Type --help for options

Note: because this runs `ufw` you need to run as root or use sudo
