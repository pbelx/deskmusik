import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:deskmusik/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(800, 600);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Radio',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const RadioPlayerPage(),
    );
  }
}

class RadioPlayerPage extends StatefulWidget {
  const RadioPlayerPage({Key? key}) : super(key: key);

  @override
  _RadioPlayerPageState createState() => _RadioPlayerPageState();
}

class _RadioPlayerPageState extends State<RadioPlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _stations = [];
  String? _currentStation;
  bool _isPlaying = false;
  bool _isLoading = true;
  double _volume = 0.5;

  // Image carousel related
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  int _currentImageIndex = 0;
  List<String> _imageList = [];

  final List<String> _imageBaseUrls = [
    'https://picsum.photos/400/300?image=1',
    'https://picsum.photos/400/300?image=2',
    'https://picsum.photos/400/300?image=3',
    'https://picsum.photos/400/300?image=4',
    'https://picsum.photos/400/300?image=5',
    'https://picsum.photos/400/300?image=6',
  ];

  String _apiEndpoint = ''; // Store the API endpoint

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadApiEndpoint().then((_) => _fetchStations());

    // Set initial volume
    _audioPlayer.setVolume(_volume);

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.playing) {
        setState(() {
          _isPlaying = true;
        });
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _loadApiEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiEndpoint = prefs.getString('api_endpoint') ?? '';
    });
  }

  Future<void> _fetchStations() async {
    if (_apiEndpoint.isEmpty) {
      _showErrorSnackBar(
          'API endpoint is not set. Please configure it in settings.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(_apiEndpoint));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _stations = data
              .map<Map<String, dynamic>>((item) => {
                    'name': item['name'],
                    'url': item['url'],
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load stations. Server error.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Network error: $e');
    }
  }

  void _loadImages() {
    // Generate unique URLs by adding a random query parameter for each image
    _imageList = _imageBaseUrls
        .map((url) =>
            '$url&random=${DateTime.now().millisecondsSinceEpoch + _imageBaseUrls.indexOf(url)}')
        .toList();

    // Start carousel timer after a short delay to allow widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCarouselTimer();
    });
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_imageList.isNotEmpty && _pageController.hasClients) {
        _currentImageIndex = (_currentImageIndex + 1) % _imageList.length;
        _pageController.animateToPage(
          _currentImageIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _playStation(String stationName, String stationUrl) async {
    setState(() {
      _currentStation = stationName;
    });

    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(stationUrl));
  }

  void _togglePlayPause() async {
    if (_currentStation == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _decreaseVolume() {
    setState(() {
      _volume = max(0.0, _volume - 0.1);
    });
    _audioPlayer.setVolume(_volume);
  }

  void _increaseVolume() {
    setState(() {
      _volume = min(1.0, _volume + 0.1);
    });
    _audioPlayer.setVolume(_volume);
  }

  void _nextStation() {
    if (_stations.isEmpty || _currentStation == null) return;

    final currentIndex =
        _stations.indexWhere((station) => station['name'] == _currentStation);
    if (currentIndex >= 0 && currentIndex < _stations.length - 1) {
      final nextStation = _stations[currentIndex + 1];
      _playStation(nextStation['name'], nextStation['url']);
    } else if (_stations.isNotEmpty) {
      // Wrap around to the first station
      final firstStation = _stations[0];
      _playStation(firstStation['name'], firstStation['url']);
    }
  }

  void _previousStation() {
    if (_stations.isEmpty || _currentStation == null) return;

    final currentIndex =
        _stations.indexWhere((station) => station['name'] == _currentStation);
    if (currentIndex > 0) {
      final prevStation = _stations[currentIndex - 1];
      _playStation(prevStation['name'], prevStation['url']);
    } else if (_stations.isNotEmpty) {
      // Wrap around to the last station
      final lastStation = _stations[_stations.length - 1];
      _playStation(lastStation['name'], lastStation['url']);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTitleBar(),
          Expanded(
            child: Row(
              children: [
                _buildStationsList(),
                _buildPlayerSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ).then((_) {
            // Reload the API endpoint and stations when returning from settings
            _loadApiEndpoint().then((_) => _fetchStations());
          });
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildTitleBar() {
    return WindowTitleBarBox(
      child: Container(
        color: const Color(0xFF8B0000),
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Online Radio",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            MinimizeWindowButton(
                colors: WindowButtonColors(iconNormal: Colors.white)),
            MaximizeWindowButton(
                colors: WindowButtonColors(iconNormal: Colors.white)),
            CloseWindowButton(
                colors: WindowButtonColors(iconNormal: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStationsList() {
    return Container(
      width: 250,
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchStations,
                  tooltip: 'Refresh stations',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      final isSelected = station['name'] == _currentStation;

                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(station['name']),
                        selected: isSelected,
                        selectedTileColor: Colors.red.withOpacity(0.3),
                        textColor: isSelected ? Colors.white : Colors.grey,
                        onTap: () =>
                            _playStation(station['name'], station['url']),
                        trailing: isSelected && _isPlaying
                            ? const Icon(Icons.volume_up, color: Colors.white)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Expanded(
      child: Container(
        color: const Color(0xFF2D2D2D),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image Carousel
            if (_imageList.isNotEmpty)
              Container(
                width: 300,
                height: 300,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _imageList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        _imageList[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            // Carousel Indicator
            if (_imageList.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _imageList.length; i++)
                    Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == i
                            ? Colors.red
                            : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                ],
              ),

            if (_currentStation != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  _currentStation!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_down),
                  onPressed: _decreaseVolume,
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: _previousStation,
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                  iconSize: 48,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: _nextStation,
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: _increaseVolume,
                  iconSize: 32,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Volume indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: Row(
                children: [
                  const Text("Volume: "),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (newVolume) {
                        setState(() {
                          _volume = newVolume;
                        });
                        _audioPlayer.setVolume(_volume);
                      },
                      activeColor: Colors.red,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                  Text("${(_volume * 100).toInt()}%"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
