[![Chat](https://img.shields.io/matrix/dtn7:matrix.org)](https://matrix.to/#/#dtn7:matrix.org)

# dtn7 showroom

This Docker image contains a virtual showroom and playground for various applications using [dtn7-rs](https://github.com/dtn7/dtn7-rs).
To play with the container docker on arm64 or x64 is needed as well as a VNC client.

Currently, the following example scenarios are included:

- [dtn dwd](https//github.com/stg-tud/dtn-dwd): delay-tolerant weather warnings
- [dtnchat](https://github.com/gh0st42/dtnchat): a simple text-based dtn chat including a chatbot
- [NNTP DTN](https://github.com/teschmitt/moNNT.py): a NNTP-to-DTN gateway for group discussions using thunderbard, pan, etc.
- [LoRaEMU](https://github.com/BigJk/LoRaEMU) + [LoRa dtn7 ecla](https://github.com/BigJk/dtn7-rs-lora-ecla): a LoRa simulator combined with a lora ecla for dtn7

## Running 

Only the `dtn7showroom.sh` script or docker itself are needed:
```
$ docker run --rm -it --name showroom -p 5901:5901 --privileged -v /tmp/shared:/shared gh0st42/dtn7-showroom

'########::'########:'##::: ##:'########::'######::'##::::'##::'#######::'##:::::'##:'########:::'#######:::'#######::'##::::'##:
 ##.... ##:... ##..:: ###:: ##: ##..  ##:'##... ##: ##:::: ##:'##.... ##: ##:'##: ##: ##.... ##:'##.... ##:'##.... ##: ###::'###:
 ##:::: ##:::: ##:::: ####: ##:..:: ##::: ##:::..:: ##:::: ##: ##:::: ##: ##: ##: ##: ##:::: ##: ##:::: ##: ##:::: ##: ####'####:
 ##:::: ##:::: ##:::: ## ## ##:::: ##::::. ######:: #########: ##:::: ##: ##: ##: ##: ########:: ##:::: ##: ##:::: ##: ## ### ##:
 ##:::: ##:::: ##:::: ##. ####::: ##::::::..... ##: ##.... ##: ##:::: ##: ##: ##: ##: ##.. ##::: ##:::: ##: ##:::: ##: ##. #: ##:
 ##:::: ##:::: ##:::: ##:. ###::: ##:::::'##::: ##: ##:::: ##: ##:::: ##: ##: ##: ##: ##::. ##:: ##:::: ##: ##:::: ##: ##:.:: ##:
 ########::::: ##:::: ##::. ##::: ##:::::. ######:: ##:::: ##:. #######::. ###. ###:: ##:::. ##:. #######::. #######:: ##:::: ##:
........::::::..:::::..::::..::::..:::::::......:::..:::::..:::.......::::...::...:::..:::::..:::.......::::.......:::..:::::..::

==> vnc://127.0.0.1:5901
==> password: sneakers

[...]
```

You can then connect with any VNC client to the local *dtn7 showroom* instance with the password `sneakers`.

*NOTE:* In case of weird connection problems within the showroom, please make sure that *ebtables* and *sch_netem* kernel modules are loaded!

## LoRaEMU

- LoRaEMU is accessible inside the container via the ``loraemu`` command
- Scenario runner and example scenarios are under ``/root/loraemu/scenarios``
- Scenarios can be run with ``./run.sh <scenario_name> <run_time>``
- Available scenarios
    - ``darmstadt``: Real world like scenario akin to Darmstadt
    - ``connected_grid``: Fully connected grid
    - ``line_collision``: 5 nodes in row to highlight collision behaviour

### Example: Darmstadt

Open a shell into the terminal. Run the command and open ``http://127.0.0.1:8291/`` in your webbrowser.

```
cd /root/loraemu/scenarios && ./run.sh darmstadt 20m
```

## Manually building the container

Just run `docker build -t dtn7-showroom .` and run it with `docker run --rm -it --name showroom -p 5901:5901 --privileged -v /tmp/shared:/shared dtn7-showroom`

