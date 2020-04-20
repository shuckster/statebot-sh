# Cloud Connect

This is a shell-script that helps automate connecting to public wifi hotspots that sit behind a captive-portal (ie; the ones where you need an account.)

It needs `plugins` to work. Two are bundled: An example that demonstrates how to write a plugin, and another that works with `BTWifi-with-FON` hotspots (so long as you have a valid and active account! :)

To use it, just pop it in your `crontab`...

```sh
# Every 10th minute, check the connection using the bt-fon plugin
*/10 * * * * /root/statebot/examples/cloud-connect/cloud-connect.sh bt-fon check
```

...and maybe your `hotplug.d/iface` folder, too:

```sh
#!/bin/sh
export DEVICE
export ACTION
/root/statebot/examples/cloud-connect/hotplug.sh
```

Check the status of it like this:

```sh
./cloud-connect.sh bt-fon

Specified plugin: [bt-fon]
Loading plugin: ./plugins/bt-fon/api.sh
Checking Wifi connected to: BTWifi-with-FON
. :
| |  Statebot :: cloud-connect
| |  Current state: [online]
|_|________________________________________ _ _ _  _  _
```

You can also `pause` Cloud Connect without needing to remove it from crontab or hotplug:

```sh
./cloud-connect.sh bt-fon pause # or resume

Specified plugin: [bt-fon]
Loading plugin: ./plugins/bt-fon/api.sh
Checking Wifi connected to: BTWifi-with-FON
. :
| |  Statebot :: cloud-connect
| |  Current state: [online]
|_|________________________________________ _ _ _  _  _

INFO: <eId:1> Handling event: pause, from state [online]
INFO: <eId:1> Changing state: online->paused
INFO: <eId:1> No on_transitions() function: Skipping transition handlers
```

Here's what a plugin looks like:

```sh
#!/bin/sh

# At this point, PLUGIN_PATH is available for you to import
# credentials and configuration from other files, if you like!

# source $PLUGIN_PATH/.secrets
# source $PLUGIN_PATH/config.sh

is_valid_network () {
  log "Are we on the right network to do this?"
  return 0 # 1 = nope!
}

is_logged_in () {
  # Just ping Google for this demo...
  ping -t 3 google.com
  return $? # 1 = error
}

login () {
  sleep 3
  return 0 # 1 = error
}

is_reboot_allowed () {
  return 0 # 1 = allow
}

report_online_status () {
  echo "Maybe POST to a URL so you can graph your connection-status!"
}
```

**Cloud Connect** implements [Statebot-sh](https://github.com/shuckster/statebot-sh/):

<img src="../../logo-small.png" width="75" />

## License

Cloud Connect is bundled with Statebot-sh, and both are [ISC licensed](./LICENSE).
