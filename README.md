WifiWatch
=========

Native macOS app that registers itself to WiFi network changes and executes either `~/.wifiConnected` or `~/.wifiDisconnected` scripts.
Two example scripts, connecting and disconnecting from VPN configurations respectively, are included.

This app is built to be added to your startup items and just keep running in the background.
The icon will **not** show up in the Dock, use _Activity Montior_ to shut it down if needed.
A build & signed binary is available [in the releases](https://github.com/p2/WifiWatch/releases).


## Scripts

Place these scripts in your home folder (`~`) and make them executable:

    $ chmod g+x ~/.wifi*

### .wifiConnected

- 1st arg: SSID of the connected network
- 2nd arg: SSID of the previously connected network, if any. May be the same.

### .wifiDisconnected

- 1st arg: SSID of the previously connected network, if any


## License

See [LICENSE](./LICENSE).
