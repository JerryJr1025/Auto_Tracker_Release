# Trinovation Auto Count Tracker v0.1.21 R2

This folder contains only the approved **v0.1.21 Revision 2** installation files copied from:

- Source repository: JerryJr1025/Auto_Tracker_Repository
- Source branch: Tracker_v0.1.21_R2_Deployment_Hardening
- Source commit: 155e3510622e49f7b942ec88f816e86d60b862e8

Do not mix these files with v0.1.22 or older 0.0.x packages.

## Windows
Use the files inside `Windows/`.
Start with `Auto_Tracker.bat` and follow `INSTALL_WINDOWS.md`.

## Linux
Use the files inside `Linux/`.
Run `chmod +x Auto_Tracker.sh`, then `./Auto_Tracker.sh`, and follow `INSTALL_LINUX.md`.

## macOS
Use the files inside `macOS/`.
Run `chmod +x Auto_Tracker_macOS.command` if required, then open/run it and follow `INSTALL_MACOS.md`.

## Shared rules
Each OS package contains the exact R2 controller, matching R2 Tampermonkey userscript, and the same locked npm dependency files. The Windows package also includes the Trinovation icon asset.

See `Documentation/` for the R2 package guide and deployment-hardening notes.
