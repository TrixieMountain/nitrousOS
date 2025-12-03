{ config, pkgs, ... }:
  
{
imports =
    [ 
       ./hardware.nix
       ./network.nix
       ./software.nix
       ./system-base.nix 
    ];
}
