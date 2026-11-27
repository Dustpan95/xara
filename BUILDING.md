# building

the standard build command is this:

    cargo install --locked --git https://github.com/x0rro/xara xara

the rest of the doc covers platform-specific deps and setup quirks.

## linux

on debian/ubuntu:

    sudo apt install libpulse-dev libasound2-dev

on fedora:

    sudo dnf install pulseaudio-lib-devel alsa-lib-devel

then build the usual way. the README covers all the main options for
linux.

### DXBerry-Pi and VarAC 17.1.7

DXBerry-Pi reports that its native VarAC 17.1.7 client disconnects when
Xara advertises HF 4.9.0. The optional `varac-17` build feature reports
`VERSION VARA HF v4.9.3` on the TCP command port. This is a client
version handshake option. The executable and installer still identify
the Xara release as usual. The 4.9.3 changelog describes backward
compatibility without specifying the modem changes, so full 4.9.3
interoperability has yet to be verified.
[DXBerry-Pi report](https://github.com/Dustpan95/DXBerry-Pi/pull/49) ·
[VARA release announcement](https://rosmodem.wordpress.com/)

On 64-bit Raspberry Pi OS or DXBerry-Pi, install the Linux prerequisites
above, plus a C linker, `pkg-config`, and Python 3. From the Xara checkout
with Rust and Cargo on your PATH, run:

    bash scripts/dxberry_kit.sh

Copy `target/dxberry/xara.zip` to
`/var/lib/dxberry/installers/xara.zip` and select **Programs → Install**
in DXBerry-Pi. Start Xara before connecting VarAC. Use modem host
`127.0.0.1`, command port `8300`, data port `8301`, and KISS port
`8100` when using the standard DXBerry-Pi ports. A `VERSION` command
terminated with a carriage return on port 8300 should return
`VERSION VARA HF v4.9.3`.

The stock DXBerry-Pi Xara launcher discards playback. To conduct a QSO,
launch VarAC from DXBerry-Pi and run the installed Xara separately,
with your station's capture, playback, and PTT settings:

    /opt/dxberry-apps/xara/xara --config /path/to/station.conf

See the README for Xara's config keys and radio options.

## macOS

no additional deps. audio goes through CoreAudio. devices are named by
CoreAudio UID or exact name:

    xara --list-devices
    xara --call YOURCALL --hf 2300 \
         --capture "USB Audio CODEC" --playback "USB Audio CODEC" \
         --radio --ptt rts:/dev/cu.usbserial-0001

without `--radio`, playback only goes into a virtual device such as
[BlackHole](https://github.com/ExistentialAudio/BlackHole).

you will need to grant `xara` microphone access on the first run.

### ptt

serial ports are `/dev/cu.*`. cm108 PTT only works by USB id, e.g.,
`cm108:1209:7388` for an AIOC.

to start xara at login, copy the launchd agent, replace YOU in it with your
login name, then load it:

    cp dist/launchd/xara.plist ~/Library/LaunchAgents/
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/xara.plist

to stop it (a plain kill gets it restarted):

    launchctl bootout gui/$(id -u)/io.github.x0rro.xara

it will ask for microphone access on first launch and on every reinstall.

## freebsd

install the deps:

    pkg install rust pkgconf alsa-lib alsa-plugins pulseaudio

then build the usual way. pulse and alsa are both supported. to use
`--radio` with alsa, pin a PCM in `~/.asoundrc`:

    pcm.digirig {
        type plug
        slave.pcm { type oss device "/dev/dsp5" }
    }

then use `--audio alsa --capture digirig --playback digirig`.

### ptt

cm108 PTT needs `hidraw(4)`, not `uhid(4)`: put `hidraw_load="YES"` and
`hw.usb.usbhid.enable="1"` in `/boot/loader.conf`. normally root-only,
to grant the `operator` group access: put the following in
`/etc/devfs.rules` and set `devfs_system_ruleset="xara"` in
`/etc/rc.conf`.

    [xara=10]
    add path 'hidraw*' mode 0660 group operator

serial PTT uses the `/dev/cuaU*` devices.
