import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../model/manga.dart';
import '../../bloc/history_reading_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'bottom_navigation_bar_page.dart';

class ReadChapterMangaPage extends StatefulWidget {
  final Manga manga;
  final Chapter chapter;

  const ReadChapterMangaPage({
    super.key,
    required this.manga,
    required this.chapter,
  });

  @override
  State<ReadChapterMangaPage> createState() => _ReadChapterMangaPageState();
}

class _ReadChapterMangaPageState extends State<ReadChapterMangaPage> {
  final ScrollController _scrollController = ScrollController();
  final HistoryReadingBloc _historyBloc = HistoryReadingBloc();

  List<String> _chapterImages = [];
  bool _isLoading = true;
  bool _isAtBottom = false;

  Chapter? _previousChapter;
  Chapter? _nextChapter;

  @override
  void initState() {
    super.initState();
    _loadChapterImages();
    _historyBloc.addToHistory(widget.manga, chapterId: widget.chapter.id);
    _determineAdjacentChapters();

    _scrollController.addListener(() {
      // Kiểm tra khi cuộn đến cuối trang
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _isAtBottom = true;
        });
      } else {
        setState(() {
          _isAtBottom = false;
        });
      }
    });
  }

  void _determineAdjacentChapters() {
    final chapters = widget.manga.chapters;
    final currentIndex =
        chapters.indexWhere((ch) => ch.id == widget.chapter.id);

    if (currentIndex > 0) {
      _previousChapter = chapters[currentIndex - 1];
    }

    if (currentIndex < chapters.length - 1) {
      _nextChapter = chapters[currentIndex + 1];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _historyBloc.dispose();
    super.dispose();
  }

  Future<void> _loadChapterImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://657fc7106ae0629a3f53a003.mockapi.io/chapters/${widget.chapter.id}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['images'] != null) {
          setState(() {
            _chapterImages = List<String>.from(data['images']);
            _isLoading = false;
          });
        } else {
          _useMockImages();
        }
      } else {
        _useMockImages();
      }
    } catch (e) {
      print('Lỗi khi tải hình ảnh chương: $e');
      _useMockImages();
    }
  }

  void _useMockImages() {
    _chapterImages = List.generate(
      10,
      (index) =>
          'https://via.placeholder.com/600x${800 + (index * 50)}?text=Chương_${widget.chapter.number}_Trang_${index + 1}',
    );
    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToChapter(Chapter chapter) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReadChapterMangaPage(
          manga: widget.manga,
          chapter: chapter,
        ),
      ),
    );
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: widget.manga.chapters.length,
          itemBuilder: (context, index) {
            final chapter = widget.manga.chapters[index];
            return ListTile(
              title: Text('Chương ${chapter.number}: ${chapter.title}'),
              selected: chapter.id == widget.chapter.id,
              onTap: () {
                Navigator.pop(context);
                _navigateToChapter(chapter);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const BottomNavigationBarPage(),
              ),
              (route) => false,
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.manga.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Chương ${widget.chapter.number}: ${widget.chapter.title}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          // Nút chương trước
          if (_previousChapter != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => _navigateToChapter(_previousChapter!),
            ),

          // Nút chương sau
          if (_nextChapter != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: () => _navigateToChapter(_nextChapter!),
            ),

          // Nút danh sách chương
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: _showChapterList,
          ),
        ],
        backgroundColor: Colors.brown,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: _chapterImages.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: _chapterImages[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        height: 300,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        alignment: Alignment.center,
                        child: Text('Không thể tải ảnh trang ${index + 1}'),
                      ),
                    );
                  },
                ),
                // Điều hướng giữa các chương khi cuộn đến cuối
                if (_isAtBottom) ...[
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_previousChapter != null)
                          ElevatedButton(
                            onPressed: () =>
                                _navigateToChapter(_previousChapter!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Chương trước'),
                          ),
                        const SizedBox(width: 20),
                        if (_nextChapter != null)
                          ElevatedButton(
                            onPressed: () => _navigateToChapter(_nextChapter!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Chương sau'),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
