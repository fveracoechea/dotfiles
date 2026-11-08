# Thin hosts with focused modules

Host configurations select reusable modules and supply machine-specific settings.
Reusable configuration lives in focused modules under `modules/{nixos,home-manager}/`.

Home Manager modules configure the user environment, while System Modules configure NixOS.
This favors reuse over self-contained host files.
To understand a host, read its enabled modules and their configuration.
