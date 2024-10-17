import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:symphony_desktop/data/models/song_model.dart';
import 'package:symphony_desktop/data/repositories/player_service_repository.dart';

class PlayerService extends GetxService {
  final PlayerServiceRepository repository;

  late final Player _player;

  final Rx<List<SongModel>?> _queue = Rx(null);
  final Rx<List<SongModel>?> _playlist = Rx(null);
  final Rx<SongModel?> _currentSong = Rx(null);
  final Rx<Duration> _duration = Rx(Duration.zero);
  final Rx<Duration> _position = Rx(Duration.zero);
  final Rx<Duration> _buffer = Rx(Duration.zero);
  final Rx<double> _volume = Rx(1.0);
  final Rx<bool> _isRepeat = Rx(false);
  final Rx<bool> _isShuffle = Rx(false);
  final Rx<bool> _isPlaying = Rx(false);

  //getters
  List<SongModel>? get getQueue => _queue.value;
  SongModel? get getCurrentSong => _currentSong.value;
  Duration get getDuration => _duration.value;
  Duration get getPosition => _position.value;
  Duration get getBuffer => _buffer.value;
  double get getVolume => _volume.value;
  bool get getIsRepeat => _isRepeat.value;
  bool get getIsShuffle => _isShuffle.value;
  bool get getIsPlaying => _isPlaying.value;

  @override
  void onInit() {
    super.onInit();
    _player = Player();

    _player.stream.playing.listen((bool playing) {
      _isPlaying.value = playing;
    });
    _player.stream.position.listen((Duration position) {
      _position.value = position;
    });
    _player.stream.duration.listen((Duration duration) {
      _buffer.value = duration;
    });
    _player.stream.playlist.listen((Playlist playlist) {
      if (playlist.isBlank == false && _queue.value != null) {
        _currentSong.value = _queue.value![playlist.index];
      }
    });
    _player.stream.volume.listen((double volume) {
      _volume.value = volume;
    });
  }

  @override
  void onClose() {
    super.onClose();
    _player.dispose();
  }

  PlayerService({required this.repository});

  void play({
    required List<SongModel>? songs,
    required int index,
  }) async {
    if (const IterableEquality().equals(_queue.value, songs) == false) {
      _playlist.value = songs?.toList();

      final List<Uri?> urls = await Future.wait(
        [for (SongModel song in songs ?? []) repository.getStreamUrl(song)],
      );

      final Playlist playlist = Playlist(
        [for (Uri? url in urls) Media(url.toString())],
      );

      _player.open(playlist, play: false);
    }

    if (_playlist.value != null) {
      _queue.value = _playlist.value?.toList();
    }

    _player.play();
    _player.jump(index);
  }

  void playOrPause() {
    _player.playOrPause();
  }

  void next() {
    _player.next();
  }

  void previous() {
    _player.previous();
  }

  void seek(Duration duration) {
    _player.seek(duration);
  }

  void repeat() {
    if (_isRepeat.value == true) {
      _player.setPlaylistMode(PlaylistMode.loop);
    } else {
      _player.setPlaylistMode(PlaylistMode.single);
    }

    _isRepeat.value = !_isRepeat.value;
  }

  void shuffle() {
    _isShuffle.value = !_isShuffle.value;
  }

  void muteOrUnmute() {
    if (_volume.value == 0) {
      _volume.value = 1;
      _player.setVolume(_volume.value);
    } else {
      _volume.value = 0;
      _player.setVolume(_volume.value);
    }
  }

  void setVolume(double volume) {
    _player.setVolume(volume);
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final SongModel? song = _queue.value?.removeAt(oldIndex);
    if (song != null) {
      _queue.value?.insert(newIndex, song);
      _player.move(oldIndex, newIndex);
    }
  }
}
