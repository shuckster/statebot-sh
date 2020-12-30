# Cloud Connect

```

  idle ->
    pinging -> (online | offline) ->
    pinging

  offline ->
    logging-in ->
    online | failure

  failure ->
    offline | rebooting

  // Go directly to [offline] on Hotplug "ifdown"
  online -> offline

  // Pause/resume functionality:
  (idle | pinging | online | offline | logging-in | failure) ->
    paused -> idle

```

This is a shell-script that helps automate connecting to public wifi hotspots that sit behind a captive-portal (ie; the ones where you need an account.)

It works using `plugins/`, and several are bundled: An example that demonstrates how to write a plugin, and three that work with `BTWi-fi` hotspots for Broadband, Business, and public Wi-fi (so long as you have a valid and active account! :)

BT used to support FON accounts, but since the [18th of June 2020](plugins/bt-wifi-with-fon/README.md) this is no longer the case. The FON plugin has been left for reference.

## Installation

Cloud Connect is bundled as a working example for the `Statebot-sh` library, so [download that](https://github.com/shuckster/statebot-sh#quick-start) to get it.

For the Quick Start instructions below we'll assume you've installed Statebot-sh into `/opt/statebot` using the `install.sh` helper.

Change to the Cloud Connect folder with:

```sh
cd /opt/statebot/examples/cloud-connect
```

## Quick Start

Cloud Connect has been tested and works on the following **GL-iNet devices: AR300M, MT300N-V2, and AR750S**, and this Quick Start assumes you're using one.

It might work on other OpenWRT devices, Raspberry Pi's etc. with a bit of bashing.

First of all, configure a plugin. Find its `dot-secrets` file in the corresponding `plugin/` folder and rename it to `.secrets`. Populate this file with your own credentials and save it.

`cloud-connect.sh` is the main script and is run like so:

```sh
./cloud-connect.sh bt-wifi check
#                  ^       ^
# plugin ----------+       |
#                          |
# event -------------------+
# - (check, resume, pause, reset)
```

> Note that "DNS rebind protection" is turned-on by default on GL-iNet devices. You'll need to turn it off so the script (and yourself) can access the captive-portal login-screen.

To help with installing Cloud Connect into your crontab/hotplug, you can use `cc.sh`, which takes its configuration from `_config.sh`:

```sh
./cc.sh check
#       ^- event only
#          (plugin is specified in _config.sh)

vi _config.sh
```

Then just pop Cloud Connect into your `crontab`:

#### File: `/etc/crontabs/root`

```sh
# Every 10th minute, check the connection:
*/10 * * * * /opt/statebot/examples/cloud-connect/cc.sh check
```

Be sure to enable and start `crontab` to enable this periodic check:

```sh
/etc/init.d/cron enable
/etc/init.d/cron restart
```

Maybe add Cloud Connect your `hotplug.d` too, in case the wifi connection flutters:

#### File: `/etc/hotplug.d/iface/99-captive-portal`

```sh
#!/bin/sh
export DEVICE
export ACTION
/opt/statebot/examples/cloud-connect/hotplug.sh
```

## General Usage

Check the status of Cloud Connect like this:

#### `CLI:`

```sh
./cloud-connect.sh bt-wifi

Specified plugin: [bt-wifi]
Loading plugin: ./plugins/bt-wifi/api.sh
Checking Wifi connected to: BTWi-fi
. :
| |  Statebot :: cloud-connect
| |  Current state: [online]
|_|________________________________________ _ _ _  _  _
```

You can also `pause` Cloud Connect without needing to remove it from crontab or hotplug:

#### `CLI:`

```sh
./cloud-connect.sh bt-wifi pause # or resume

Specified plugin: [bt-wifi]
Loading plugin: ./plugins/bt-wifi/api.sh
Checking Wifi connected to: BTWi-fi
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

Have a look in `plugins/` to see this example and another that works for BT Wifi, too.

## Credit

Props to [sscarduzio and other commenters in his Gist](https://gist.github.com/sscarduzio/05ed0b41d6234530d724) for starting me down this rabbit-hole, and [SpikeTheLobster](https://gist.github.com/sscarduzio/05ed0b41d6234530d724#gistcomment-3336485) for the BT OpenZone config settings.


## License

Cloud Connect is bundled with [Statebot-sh](https://github.com/shuckster/statebot-sh/) and both are [MIT licensed](https://github.com/shuckster/statebot-sh/blob/master/LICENSE).

<img src="../../logo-small.png" width="75" />
