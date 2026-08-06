#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#include <QStringList>
#include <QVariantMap>
#include <QString>


NSArray *QStringListToNSArray(const QStringList &list) {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:list.size()];
    for (const QString &str : list) {
        [array addObject:str.toNSString()];
    }
    return [array copy];
}

@interface AudioPlayerManager : NSObject <AVAudioPlayerDelegate, NSURLSessionDelegate>

@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, assign) NSInteger currentTrackIndex;
@property (nonatomic, strong) NSArray<NSString *> *tracks;
@property (nonatomic, strong) NSTimer *playbackTimer;
@property (nonatomic, assign) NSInteger repeatMode;

- (void)load:(QStringList)tracks;
- (void)loadAudioAsync;
- (void)playAudio;
- (void)stopAudio;
- (void)startAudio;
- (void)playNext;
- (void)playPrevious;
- (void)setupNowPlaying;
- (void)startPlaybackTimer;
- (void)updateNowPlaying:(BOOL)isPlaying;
- (BOOL)isPlaying;
- (BOOL)configureAudioSession:(BOOL)isActive;
- (QString)trackName;
- (double)getDuration;
- (double)getCurrentTime;
- (void)setPosition:(NSTimeInterval)currentPos;
@end

@implementation AudioPlayerManager

- (void)load:(QStringList)tracks {
    _tracks = QStringListToNSArray(tracks);
    _currentTrackIndex = 0;
    _repeatMode = 2;
    [self loadAudioAsync];
    [self setupNowPlaying];
}

- (QString)trackName {
  NSString *trackName = self.tracks[self.currentTrackIndex];
  return QString::fromNSString(trackName);
}

- (double)getDuration {
  return self.player.duration; // seconds
}

- (double)getCurrentTime {
  return self.player.currentTime; // seconds
}

- (void)loadAudioAsync {
    if (self.currentTrackIndex >= self.tracks.count) {
        NSLog(@"Invalid track index");
        return;
    }

    NSString *trackURLString = self.tracks[self.currentTrackIndex];
    NSURL *url = [NSURL URLWithString:trackURLString];
    if (!url) {
        NSLog(@"Invalid URL");
        return;
    }

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to download audio: %@", error);
            return;
        }

        if (!data) {
            NSLog(@"No data received");
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *playerError;
            self.player = [[AVAudioPlayer alloc] initWithData:data error:&playerError];
            if (playerError) {
                NSLog(@"Failed to initialize audio player: %@", playerError);
                return;
            }

            [self.player prepareToPlay];
            self.player.delegate = self;
            [self updateNowPlaying:NO];
            [self.player play];
            [self updateNowPlaying:YES];
            [self startPlaybackTimer];
        });
    }];
    [task resume];
}

- (void)playAudio {
    if (!self.player) {
        NSLog(@"Player is not initialized");
        return;
    }

    if (!self.player.isPlaying) {
        [self.player play];
    } else {
        [self.player pause];
    }
    [self updateNowPlaying:self.player.isPlaying];
}

- (void)stopAudio {
    if (self.player.isPlaying) {
        [self.player stop];
        [self updateNowPlaying:NO];
    }
}

- (void)startAudio {
    if (!self.player.isPlaying) {
        [self.player play];
        [self updateNowPlaying:YES];
    }
}

- (void)playNext {
    [self stopAudio];
    self.currentTrackIndex = (self.currentTrackIndex + 1) % self.tracks.count;
    [self loadAudioAsync];
}

- (void)playPrevious {
    [self stopAudio];
    self.currentTrackIndex = (self.currentTrackIndex - 1 + self.tracks.count) % self.tracks.count;
    [self loadAudioAsync];
}

- (void)setupNowPlaying {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player play];
        [self updateNowPlaying:YES];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player pause];
        [self updateNowPlaying:NO];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self playNext];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self playPrevious];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        MPChangePlaybackPositionCommandEvent *positionEvent = (MPChangePlaybackPositionCommandEvent *)event;
        self.player.currentTime = positionEvent.positionTime;
        [self updateNowPlaying:self.player.isPlaying];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [self updateNowPlaying:NO];
}

- (void)setPosition:(NSTimeInterval)currentPos {
    self.player.currentTime = currentPos;
    [self updateNowPlaying:self.player.isPlaying];
}

- (void)startPlaybackTimer {
    [self.playbackTimer invalidate];
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self updateNowPlaying:self.player.isPlaying];
    }];
}

- (void)updateNowPlaying:(BOOL)isPlaying {
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];

    NSString *trackURL = self.tracks[self.currentTrackIndex];
    NSString *fileName = [[NSURL URLWithString:trackURL] lastPathComponent] ?: [NSString stringWithFormat:@"Track %ld", (long)(self.currentTrackIndex + 1)];

    nowPlayingInfo[MPMediaItemPropertyTitle] = fileName;
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(isPlaying ? 1.0 : 0.0);

    if (self.player) {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.player.currentTime);
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(self.player.duration);
    }

    UIImage *image = [UIImage imageNamed:@"changpian.png"];
    if (image) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:image.size requestHandler:^UIImage * _Nonnull(CGSize size) {
            return image;
        }];
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork;
    }

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        if(self.repeatMode == 2)
          [self playNext];
        else if(self.repeatMode == 1)
          [self playAudio];
    }
}

- (BOOL)isPlaying {
    return self.player.isPlaying;
}

- (BOOL)configureAudioSession:(BOOL)isActive {
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"Audio session error: %@", error);
        return NO;
    }

    [[AVAudioSession sharedInstance] setActive:isActive error:&error];
    if (error) {
        NSLog(@"Audio session error: %@", error);
        return NO;
    }

    return YES;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end

// ========= audioPlayerManager api for C++ ===================================================================
extern "C" AudioPlayerManager* audioPlayerManager_new() { return [[AudioPlayerManager alloc] init]; }
extern "C" void audioPlayerManager_delete(AudioPlayerManager* m_player)
{
    if (m_player) {
        NSLog(@"AudioPlayerManager.mm: delete");
        [m_player stopAudio];
        if (m_player.player) {
            [m_player.player stop];
            m_player.player = nil;
        }
        if (m_player.playbackTimer) {
            [m_player.playbackTimer invalidate];
            m_player.playbackTimer = nil;
        }
        m_player.tracks = nil;
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
        [m_player configureAudioSession:FALSE];
    }
}
extern "C" void audioPlayerManager_load(AudioPlayerManager* m_player, QStringList &tracks) { [m_player load:tracks]; }
extern "C" void audioPlayerManager_playPause(AudioPlayerManager* m_player) { [m_player playAudio]; }
extern "C" void audioPlayerManager_playNext(AudioPlayerManager* m_player) { [m_player playNext]; }
extern "C" void audioPlayerManager_playPrevious(AudioPlayerManager* m_player) { [m_player playPrevious]; }
extern "C" bool audioPlayerManager_startDamon(AudioPlayerManager* m_player, bool isActive) { return [m_player configureAudioSession:isActive]; }
extern "C" void audioPlayerManager_setPosition(AudioPlayerManager* m_player, double lfPos) {[m_player setPosition:lfPos];}
extern "C" void audioPlayerManager_setRepeatMode(AudioPlayerManager* m_player, int iMode) {[m_player setRepeatMode:iMode];}
// status
extern "C" bool audioPlayerManager_isPlaying(AudioPlayerManager* m_player) { return m_player.player.isPlaying; }
extern "C" int audioPlayerManager_getDuration(AudioPlayerManager* m_player) { return m_player.player.duration; }
extern "C" int audioPlayerManager_getCurrentTime(AudioPlayerManager* m_player) { return m_player.player.currentTime; }
QString audioPlayerManager_getTrackName(AudioPlayerManager* m_player) { return [m_player trackName]; }
extern "C" void audioPlayerManager_forceLand(bool bLand)
{
  NSLog(@"set orientation: %d", bLand);
  UIWindowScene *scene = (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
  if (scene && [scene respondsToSelector:@selector(requestGeometryUpdateWithPreferences:errorHandler:)]) {
      UIInterfaceOrientationMask orientationMask = bLand ? UIInterfaceOrientationMaskLandscape : UIInterfaceOrientationMaskPortrait;
      UIWindowSceneGeometryPreferencesIOS *geometryPreferences = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:orientationMask];
      [scene requestGeometryUpdateWithPreferences:geometryPreferences errorHandler:^(NSError * _Nonnull error) {
          NSLog(@"Error updating orientation: %@", error);
      }];
  }
}
// =============================================================================================================
