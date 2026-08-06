package com.ithingtalk.zhome;
import android.util.Log;

public class PlayerState {
    public final boolean isPlaying;
    public final String trackName;
    public final long timeNow;
    public final long timeTotal;

    public PlayerState(boolean isPlaying, String trackName, long timeNow, long timeTotal) {
        //Log.e("", "PlayerState: " + isPlaying + ", " + trackName + ", " + timeNow + ", " + timeTotal);
        this.isPlaying = isPlaying;
        this.trackName = trackName;
        this.timeNow = timeNow;
        this.timeTotal = timeTotal;
    }
}
