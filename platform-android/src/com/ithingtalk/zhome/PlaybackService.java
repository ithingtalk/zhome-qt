package com.ithingtalk.zhome;

import android.annotation.SuppressLint;
import android.util.Log;
import java.net.Authenticator;
import java.net.PasswordAuthentication;
import java.security.cert.X509Certificate;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import androidx.annotation.OptIn;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.MediaSession;
import androidx.media3.session.MediaSessionService;

public class PlaybackService extends MediaSessionService {
    private MediaSession mediaSession = null;
    private static String AUTH_USER = "";
    private static String AUTH_PASSWORD = "";

    @OptIn(markerClass = UnstableApi.class) public void onCreate() {
        super.onCreate();

        HttpsURLConnection.setDefaultSSLSocketFactory(getUnsafeSSLSocketFactory());
        HttpsURLConnection.setDefaultHostnameVerifier((hostname, session) -> true);

        Authenticator.setDefault(new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                //Log.e("=================> ", "set auth = " + AUTH_USER + ", " + AUTH_PASSWORD);
                return new PasswordAuthentication(AUTH_USER, AUTH_PASSWORD.toCharArray());
            }
        });

        ExoPlayer player = new ExoPlayer.Builder(this).build();
        player.setRepeatMode(Player.REPEAT_MODE_ALL);
        mediaSession = new MediaSession.Builder(this, player).build();
    }

    public static void setAuthCredentials(String user, String password) {
        AUTH_USER = user;
        AUTH_PASSWORD = password;
    }

    @Override
    public MediaSession onGetSession(MediaSession.ControllerInfo controllerInfo) {
        return mediaSession;
    }

    @Override
    public void onDestroy() {
        mediaSession.getPlayer().release();
        mediaSession.release();
        mediaSession = null;
        super.onDestroy();
    }

    @SuppressLint("CustomX509TrustManager")
    public SSLSocketFactory getUnsafeSSLSocketFactory() {
        try {
            TrustManager[] trustAllCerts = new TrustManager[]{
                    new X509TrustManager() {
                        @SuppressLint("TrustAllX509TrustManager")
                        public void checkClientTrusted(X509Certificate[] chain, String authType) {}
                        @SuppressLint("TrustAllX509TrustManager")
                        public void checkServerTrusted(X509Certificate[] chain, String authType) {}
                        public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
                    }
            };

            SSLContext sslContext = SSLContext.getInstance("SSL");
            sslContext.init(null, trustAllCerts, new java.security.SecureRandom());
            return sslContext.getSocketFactory();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}