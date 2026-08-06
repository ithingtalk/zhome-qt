package com.ithingtalk.zhome;

import android.content.Context;
import android.util.Log;

public class QtAudioBridge {
    private static AndroidAudioPlayer mPlayer = null;

    public static void initialize(Context context) {
        mPlayer = new AndroidAudioPlayer(context);
    }

    public static void load(String[] urls) {
        if (mPlayer != null) mPlayer.load(urls);
    }
    
    public static void play() {
        if (mPlayer != null) mPlayer.play();
    }
    
    public static void next() {
        if (mPlayer != null) mPlayer.next();
    }
    
    public static void prev() {
        if (mPlayer != null) mPlayer.prev();
    }

    public static void seekTo(long seconds) {
        if (mPlayer != null) mPlayer.seek(seconds);
    }

    public static void repeatMode(int mode) {
        if (mPlayer != null) mPlayer.repeatMode(mode);
    }

    public static PlayerState getPlayerState() {
        synchronized (QtAudioBridge.class) {
            //Log.e("", "QtQudioBridge.java, getPlayerState");
            return mPlayer != null ? mPlayer.getPlayerState() : new PlayerState(false, "", 0, 0);
        }
    }

    public static void release() {
        if (mPlayer != null) {
            Log.e("", "===========================> QtAudioBridge.java release !!!");
            mPlayer.exitPlayer();
            mPlayer = null;
        }
    }
}
