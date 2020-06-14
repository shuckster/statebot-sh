# Cloud Connect

```

  idle ->

  pinging -> (online | offline) -> pinging
  offline -> logging-in -> (online | failure)
  failure -> offline

  // Go directly to [offline] on Hotplug "ifdown"
  online -> offline

  // Pause/resume functionality:
  (idle|pinging|online|offline|logging-in|failure) ->
    paused -> idle

```

This is a shell-script that helps automate connecting to public wifi hotspots that sit behind a captive-portal (ie; the ones where you need an account.)

It works using `plugins/`, and two are bundled: An example that demonstrates how to write a plugin, and another that works with `BTWifi-with-FON` hotspots (so long as you have a valid and active account! :)

## Installation

Cloud Connect is bundled as a working example for the `Statebot-sh` library, so [download that](https://github.com/shuckster/statebot-sh) to get it.

Then just pop Cloud Connect into your `crontab`...

#### `/etc/crontabs/root`

```sh
# Every 10th minute, check the connection using the bt-fon plugin
*/10 * * * * /opt/statebot/examples/cloud-connect.sh bt-fon check
```

...and maybe your `hotplug.d/iface/` folder, too:

#### `/etc/hotplug.d/iface/99-captive-portal`

```sh
#!/bin/sh
export DEVICE
export ACTION
/opt/statebot/examples/cloud-connect/hotplug.sh
```

## Usage

Check the status of it like this:

#### `CLI:`

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

#### `CLI:`

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

## Plugins

Here's what a plugin looks like:

```sh
#!/bin/sh

# At this point, PLUGIN_PATH is available for you to import
# credentials and configuration from other files, if you like!

# . "${PLUGIN_PATH}/.secrets"
# . "${PLUGIN_PATH}/config.sh"

is_valid_network ()
{
  log "Are we on the right network to do this?"
  return 0 # Non-zero here means "nope!"
}

is_logged_in ()
{
  # Just ping Google for this demo...
  ping -t 3 google.com
  return $? # Non-zero here means an error occurred
}

login ()
{
  sleep 3
  return 0 # Non-zero here means an error occurred
}

is_reboot_allowed ()
{
  return 1 # Non-zero here means "nope!"
}

report_online_status ()
{
  echo "Maybe POST to a URL so you can graph your connection-status!"
}
```

Have a look in `plugins/` to see this example and another that works for BT Fon & OpenZone, too.

## Credit

Props to [sscarduzio and other commenters in his Gist](https://gist.github.com/sscarduzio/05ed0b41d6234530d724) for starting me down this rabbit-hole, and [SpikeTheLobster](https://gist.github.com/sscarduzio/05ed0b41d6234530d724#gistcomment-3336485) for the BT OpenZone config settings.


## License

Cloud Connect is bundled with [Statebot-sh](https://github.com/shuckster/statebot-sh/) and both are [ISC licensed](./LICENSE).

<img src="../../logo-small.png" width="75" />
