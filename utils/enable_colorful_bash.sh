#!/bin/bash
# force enable colors
sed -i '/#force_color_prompt=yes/c\force_color_prompt=yes' ~/.bashrc
# remove old color scheme
sed -i '/if \[ "\$color_prompt" = yes \]; then/{n;d}' ~/.bashrc
# add new color scheme
sed -i '/if \[ "\$color_prompt" = yes \]; then/a PS1="\${debian_chroot:+(\$debian_chroot)}\\\[\\033\[01;31m\\\]\\u\\\[\\033\[01;33m\\\]@\\\[\\033\[01;36m\\\]\\h \\\[\\033[01;33m\\\]\\w \\\[\\033\[01;35m\\\]\\\$ \\\[\\033\[00m\\\]"' ~/.bashrc
# read .bashrc on login
echo "source .bashrc" >> ~/.bash_profile
# read new config in current session
source ~/.bashrc