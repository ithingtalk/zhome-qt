package com.ithingtalk.zhome;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.MoreExecutors;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.FutureTask;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import androidx.media3.ui.PlayerView;

public class AndroidAudioPlayer {
    ListenableFuture<MediaController> controllerFuture = null;
    Context gContext;
    PlayerView gPlayerView;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private <T> T runOnMainThread(Callable<T> callable) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            try {
                return callable.call();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }

        final FutureTask<T> task = new FutureTask<>(callable);
        mainHandler.post(task);
        try {
            return task.get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public AndroidAudioPlayer(Context context) {
        this(context, null);
    }

    public AndroidAudioPlayer(Context context, PlayerView playerView) {
        gContext = context.getApplicationContext();
        gPlayerView = playerView;
    }

    public void load(String[] strUrls) {
        SessionToken sessionToken = new SessionToken(gContext, new ComponentName(gContext, PlaybackService.class));
        controllerFuture = new MediaController.Builder(gContext, sessionToken).buildAsync();
        controllerFuture.addListener(() -> {
            // Call controllerFuture.get() to retrieve the MediaController.
            // MediaController implements the Player interface, so it can be
            // attached to the PlayerView UI component.
            try {
                MediaController controller = controllerFuture.get();

                // costum control view
                if(gPlayerView != null) {
                    gPlayerView.setPlayer(controller); // 2 initPlayer()
                }
                //1 PlayerView playerView = findViewById(R.id.player_view); // onCreate()

                List<MediaItem> mediaItems = new ArrayList<>();
                for (String url : strUrls) {
                    Uri uri = Uri.parse(url);
                    if (uri.getUserInfo() != null) {
                        String[] credentials = uri.getUserInfo().split(":");
                        PlaybackService.setAuthCredentials(credentials[0], credentials[1]);
                        Uri cleanUri = uri.buildUpon().encodedAuthority(uri.getHost() + ":" + uri.getPort()).build();
                        mediaItems.add(MediaItem.fromUri(cleanUri));
                    }
                }

                controller.setMediaItems(mediaItems);
                controller.prepare();
                controller.play();
            } catch (ExecutionException | InterruptedException e) {
                //throw new RuntimeException(e);
                Log.e("AndroidAudioPlayer error: ", e.toString());
            }
        }, MoreExecutors.directExecutor());
    }

    public void play() {
        runOnMainThread(() -> {
            try {
                MediaController controller = controllerFuture.get();
                if (controller.isPlaying()) {
                    controller.pause();
                } else {
                    controller.play();
                }
            } catch (ExecutionException | InterruptedException e) {
                //throw new RuntimeException(e);
                Log.e("AndroidAudioPlayer error: ", e.toString());
            }
            return null;
        });
    }

    public void next() {
        runOnMainThread(() -> {
            try {
                MediaController controller = controllerFuture.get();
                controller.seekToNextMediaItem();
            } catch (ExecutionException | InterruptedException e) {
                //throw new RuntimeException(e);
                Log.e("AndroidAudioPlayer error: ", e.toString());
            }
            return null;
        });
    }

    public void prev() {
        runOnMainThread(() -> {
            try {
                MediaController controller = controllerFuture.get();
                controller.seekToPreviousMediaItem();
            } catch (ExecutionException | InterruptedException e) {
                //throw new RuntimeException(e);
                Log.e("AndroidAudioPlayer error: ", e.toString());
            }
            return null;
        });
    }

    public void seek(long iSeconds) {
        runOnMainThread(() -> {
            try {
                MediaController controller = controllerFuture.get();
                controller.seekTo(iSeconds * 1000);
            } catch (ExecutionException | InterruptedException e) {
                //throw new RuntimeException(e);
                Log.e("AndroidAudioPlayer error: ", e.toString());
            }
            return null;
        });
    }

    public void repeatMode(int iMode) { // 0, 1, 2: off, one, all
        runOnMainThread(() -> {
            try {
                //Log.e("", "==================> AndroidAudioPlayer.java: repeatMode = " + iMode);
                MediaController controller = controllerFuture.get();
                //Log.e("", "==================> AndroidAudioPlayer.java: repeatMode org = " + controller.getRepeatMode());
                controller.setRepeatMode(iMode);
                //Log.e("", "==================> AndroidAudioPlayer.java: repeatMode new = " + controller.getRepeatMode());
            } catch (ExecutionException | InterruptedException e) {
                //throw new RuntimeException(e);
                Log.e("AndroidAudioPlayer.java, error: ", e.toString());
            }
            return null;
        });
    }

    private String _getTrackName() {
        try {
            MediaController controller = controllerFuture.get();
            MediaMetadata item = controller.getMediaMetadata();
            return item.title.toString() + " - " + item.artist.toString();
        } catch (Exception e) {
            Log.e("AndroidAudioPlayer error: ", e.toString());
        }
        return "";
    }

    public PlayerState getPlayerState() {
        return runOnMainThread(() -> {
            try {
                MediaController controller = controllerFuture.get();
                //Log.e("", "==============> AndroidAudioPlayer.java, getPlayerState: ");
                return new PlayerState(
                        controller.isPlaying(),
                        _getTrackName(),
                        controller.getCurrentPosition() / 1000,
                        controller.getDuration() / 1000
                );
            } catch (Exception e) {
                Log.e("AndroidAudioPlayer error: ", e.toString());
                return new PlayerState(false, "", 0, 0);
            }
        });
    }

    public void exitPlayer() {
        runOnMainThread(() -> {
            if (controllerFuture != null) {
                Log.e("", "==================> AndroidAudioPlayer: exitPlayer");
                MediaController.releaseFuture(controllerFuture);
                controllerFuture = null;
                Intent serviceIntent = new Intent(gContext, PlaybackService.class);
                gContext.stopService(serviceIntent);
            }
            return null;
        });
    }
}
