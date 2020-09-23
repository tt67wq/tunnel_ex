#! /bin/bash
rsync -avP --compress /home/manjaro/Projects/tunnel_ex/* box0:/home/vagrant/tunnel_ex --exclude-from='./exclude.txt'