#!/bin/bash
#sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
nix run home-manager/master -- init --switch
