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


~samples_path = File.realpath(thisProcess.nowExecutingPath.dirname +/+ "../samples/");


if (~samples_path.isNil) {
    "samples folder does not exist, the folder structure should be:".postln;
    "".postln;
    "project/ollie-sellwood-piano-nudes/piano-nudes.scd".postln;
    "project/samples/sample-0001.wav (etc)".postln;
    0.exit;
} {
    "samples folder exists".postln;
};

(
~max_sample_duration_s = 0.0;
PathName(~samples_path).files.do {|pathName|
    var soundfile = SoundFile.openRead(pathName.fullPath);

    ~max_sample_duration_s = ~max_sample_duration_s.max(soundfile.duration);
};

("max sample duration: " + ~max_sample_duration_s).postln;

)