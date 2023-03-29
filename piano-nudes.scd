/*
TODO

- server config
- server boot
- script booting override Main.run?
- load samples (memory constraints, DiskIn)
- triggering samples
- reset points
- hardware input
- bela autoboot

*/


~samples_folder = File.realpath(thisProcess.nowExecutingPath.dirname +/+ "../samples/");


if (~samples_folder == nil) {
    "samples folder does not exist, the folder structure should be:".postln;
    "".postln;
    "project/ollie-sellwood-piano-nudes/piano-nudes.scd".postln;
    "project/samples/sample-0001.wav (etc)".postln;
    0.exit;
} {
    "samples folder exists".postln;
};

"hello".postln;
