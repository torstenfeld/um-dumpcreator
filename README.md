# Dump configurator for Windows

Provides an easy to use GUI for user and kernel mode dumps

## Planning Board

https://trello.com/board/dev-usermode-dump-creator/501f9039d4fe3721757fa651

## Features
* Set registry settings on Windows Vista and above for automatic creation of process dumps
* Create dumps for hanging or crashing processes manually
* Monitoring processes with creation of dumps on crash / exit
* Creation of dumps for x86 and x64 dumps depending on process architecture (eg. x86 process on x64 OS)

## Known issues
* none so far

## Changelog
### 1.2.0.16
* added logging to %temp%\dumpconfigurator\dc-debug.log
* renamed variable for 'extended' button from $ButtonAvira to $ButtonExtended
* changed ini key from WdtPath to WdtPath64 / WdtPath86 depending on os and process architecture

### 1.1.0.14
* added support for x86 dump creation on x64 OS depending on process architecture

### 1.0.0.12
* renamed buttons for automatic process dump configuration
* some GUI changes
* added process selection through clicking on corresponding window
* Debugging Tools for Windows are downloaded and installed automatically