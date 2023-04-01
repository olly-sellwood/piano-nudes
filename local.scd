(
File.realpath(thisProcess.nowExecutingPath.dirname +/+ "_main.scd").load;

~debugClickButton = {|index|
    var values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    if (index < values.size) {

        values[index] = 1.0;
        ~buttonListenerSynth.set(\t_values, values);
    } {
        ("pin index out of range. Pin:"+ index ++ "," + "Max:" + values.lastIndex).postln;
    }
};
);

~debugClickButton.(0); // click button 0, (play next sample)
~debugClickButton.(1); // click button 1, (reset to first rehearsal mark)
