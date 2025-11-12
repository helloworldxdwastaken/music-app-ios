//
//  AudioPlayerManager.swift
//  Music Stream
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

extension Notification.Name {
    static let previewPlaybackDidStart = Notification.Name("previewPlaybackDidStart")
    static let audioPlaybackDidStart = Notification.Name("audioPlaybackDidStart")
}

class AudioPlayerManager: NSObject, ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Double = 0.7
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    var apiService: APIService?
    var offlineManager: OfflineManager?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var currentPlayerItem: AVPlayerItem?
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreviewPlaybackStart), name: .previewPlaybackDidStart, object: nil)
    }
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        // Remove time observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Clean up player
        player?.pause()
        player = nil
        currentPlayerItem = nil
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: event.positionTime)
            return .success
        }
    }
    
    // MARK: - Playback Controls
    func play(song: Song) {
        currentSong = song
        queue = [song]
        currentIndex = 0
        playCurrentSong()
    }
    
    func playQueue(songs: [Song], startAt: Int = 0) {
        queue = songs
        currentIndex = startAt
        currentSong = songs[startAt]
        playCurrentSong()
    }
    
    func configure(with service: APIService, offlineManager: OfflineManager? = nil) {
        self.apiService = service
        self.offlineManager = offlineManager
    }
    
    private func playCurrentSong() {
        guard let song = currentSong,
              let streamURL = streamURL(for: song) else {
            print("Cannot get stream URL for song")
            return
        }

        NotificationCenter.default.post(name: .audioPlaybackDidStart, object: nil)
        
        print("Playing: \(song.title) from \(streamURL)")
        
        // Clean up previous player and observers
        cleanupPreviousPlayer()
        
        // Create new player item
        let playerItem = AVPlayerItem(url: streamURL)
        currentPlayerItem = playerItem
        
        // Create new player
        player = AVPlayer(playerItem: playerItem)
        player?.volume = Float(volume)
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let duration = self.player?.currentItem?.duration.seconds, !duration.isNaN {
                self.duration = duration
            }
            self.updateNowPlayingPlaybackState()
        }
        
        // Observe end of playback
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        player?.play()
        isPlaying = true
        
        updateNowPlayingInfo()
        updateNowPlayingPlaybackState()
    }

    @objc private func handlePreviewPlaybackStart() {
        if isPlaying {
            pause()
        }
    }
    
    private func cleanupPreviousPlayer() {
        // Remove time observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Remove notification observer for previous player item
        if let previousItem = currentPlayerItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: previousItem
            )
        }
        
        // Pause and clean up previous player
        player?.pause()
        player = nil
        currentPlayerItem = nil
        
        // Reset time
        currentTime = 0
        duration = 0
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingPlaybackState()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func nextTrack() {
        guard currentIndex < queue.count - 1 else {
            // End of queue
            return
        }
        currentIndex += 1
        currentSong = queue[currentIndex]
        playCurrentSong()
    }
    
    func previousTrack() {
        if currentTime > 3 {
            // If more than 3 seconds played, restart current song
            seek(to: 0)
        } else if currentIndex > 0 {
            currentIndex -= 1
            currentSong = queue[currentIndex]
            playCurrentSong()
        } else {
            // Restart current song
            seek(to: 0)
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        // Auto-play next track
        nextTrack()
    }
    
    private func streamURL(for song: Song) -> URL? {
        if let offlineURL = offlineManager?.localURL(for: song) {
            return offlineURL
        }
        if let url = apiService?.getStreamURL(for: song) {
            return url
        }
        let base = UserDefaults.standard.string(forKey: "serverURL") ?? "https://stream.noxamusic.com"
        return URL(string: "\(base)/api/library/stream/\(song.id)")
    }
    
    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = song.album ?? ""
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Load artwork asynchronously
        if let artworkURL = song.albumArtURL, let url = URL(string: artworkURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }.resume()
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateNowPlayingPlaybackState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
