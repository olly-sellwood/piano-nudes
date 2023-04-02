# Piano Nudes

Piano Nudes, by Olly Sellwood (https://www.ollysellwood.info)

SuperCollider https://supercollider.github.io patch for Bela (https://bela.io), by Arthur Carabott (https://www.arthurcarabott.com)

## TODO

-   add samples to repo, once finalised (mono?)
-   add toggle for logging
-   investigate stereo samples? (remove if mono)

## Installation

If using a fresh bela, the project can be setup by going to `http://bela.local` and running the following command in the console. (The Bela must connected to your machine via USB, and to the internet via Ethernet / wifi).

```sh
git clone https://github.com/olly-sellwood/piano-nudes.git /root/Bela/projects/piano-nudes
```

See here for more info on using the console: https://learn.bela.io/the-ide/meet-the-ide/#the-console

To set the project to start automatically when Bela boots run

```sh
/root/Bela/scripts/set_startup.sh piano-nudes
```

To stop running the project at startup run

```sh
/root/Bela/scripts/set_startup.sh nostartup piano-nudes
```

See here for more info starting automatically https://learn.bela.io/using-bela/technical-explainers/scripts/#set_startupsh/

## Button Configuration

To configure buttons connected to the Bela, use the Dictionary at the top of `_main.scd` to create a mapping between pin numbers and actions. The numbers on the left correspond to the hardware pin number (see https://learn.bela.io/pin-diagram/).

The string `"trigger"` will play the current sample and move the playhead to the next sample. All other strings will move the playhead to that sample (e.g. `"sample-0646"`). This must match _exactly_ the name (without extension) of a file in the `samples` folder, e.g. `"sample-0646"` will move to `"/samples/sample-0646.wav"`.

```c++
~pinMapping = Dictionary.with(*[
    0 -> "trigger",
    1 -> "sample-0001",
    2 -> "sample-0074",
    3 -> "sample-0239",
    4 -> "sample-0269",
    5 -> "sample-0486",
    6 -> "sample-0579",
    7 -> "sample-0646",
    8 -> "sample-0719",
    9 -> "sample-0834",
    10 -> "sample-0912",
    11 -> "sample-0960",
    12 -> "sample-0983",
])
```

## Running locally

To run the project on a regular computer, open `local.scd` and execute the top block of code. You can use the `~debugClickButton` function to simulate clicking a button, e.g. `~debugClickButton.(0);` to click the first button (play next sample).

Note: for debugging purposes, this simulates receiving messages from the Bela rather than calling the functions directly.

### MIDI

The file `midi.scd` has example code is included to use MIDI input instead of buttons. Note that this can only be run locally. If you want to run it on the Bela, copy-paste everything except the first line into the top of `_main.scd`.

Do not copy line 1:

```
File.realpath(thisProcess.nowExecutingPath.dirname +/+ "_main.scd").load;
```

## Updating the project

The recommended workflow for making changes is:

1.  make changes on your machine within this repo
1.  commit the changes to git and push to github
1.  pull the latest changes on Bela with the following command

```sh
cd /root/Bela/projects/piano-nudes && git pull
```

If you encounter errors, you probably made changes to the code in the Bela IDE. You should then:

1.  copy the code from the IDE into your local version
1.  commit the changes and push to github
1.  run the following in the Bela IDE console

```sh
cd /root/Bela/projects/piano-nudes && git checkout -- . && git pull
```

(The details of git are beyond the scope of this document, but this is a good guide: https://docs.github.com/en/get-started/using-git/about-git)

## Bela Settings

Project settings (e.g. volume, block size etc) _are not_ stored in the git repository, to allow for modification without having to commit changes.
