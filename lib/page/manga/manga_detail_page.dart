import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_btl/repositories/manga_repository.dart';
import '../../model/manga.dart';
import '../../bloc/history_reading_bloc.dart';
import 'read_chapter_manga_page.dart';

class MangaDetailPage extends StatefulWidget {
  final Manga manga;

  const MangaDetailPage({
    super.key,
    required this.manga,
  });

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  final HistoryReadingBloc _historyBloc = HistoryReadingBloc();
  bool _isFavorite = false;
  bool _isLoading = true;
  late Manga _manga;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _manga = widget.manga;
    // Thêm vào lịch sử khi mở trang chi tiết
    _historyBloc.addToHistory(_manga);
    _checkFavoriteStatus();
    _loadMangaDetails();
  }

  @override
  void dispose() {
    _historyBloc.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMangas = prefs.getStringList('favorite_mangas') ?? [];

    setState(() {
      _isFavorite = favoriteMangas.contains(_manga.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteMangas = prefs.getStringList('favorite_mangas') ?? [];

    setState(() {
      if (_isFavorite) {
        // Xóa khỏi danh sách yêu thích
        favoriteMangas.remove(_manga.id);
        _isFavorite = false;
      } else {
        // Thêm vào danh sách yêu thích
        favoriteMangas.add(_manga.id);
        _isFavorite = true;
      }
    });

    // Lưu danh sách yêu thích
    await prefs.setStringList('favorite_mangas', favoriteMangas);

    // Hiển thị thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? 'Đã thêm vào truyện yêu thích'
              : 'Đã xóa khỏi truyện yêu thích',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _loadMangaDetails() async {
    if (_manga.chapters.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final repository = MangaRepository();
        final detailedManga = await repository.getMangaDetails(_manga.slug);

        setState(() {
          _manga = detailedManga;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải chi tiết truyện: $e';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _manga.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _manga.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 50, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Nút yêu thích
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              // Nút chia sẻ
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang phát triển'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          // Nội dung chi tiết truyện
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin tác giả
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Tác giả: ${_manga.author}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Thể loại
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _manga.categories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề giới thiệu
                    const Text(
                      'Giới thiệu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Nội dung giới thiệu
                    Text(
                      _manga.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thông tin lượt xem
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_manga.viewCount} lượt xem',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        if (_manga.isHot)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'HOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Tiêu đề danh sách chương
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Danh sách chương',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_manga.chapters.length} chương',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Danh sách chương
          if (_manga.chapters.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('Không có chương nào'),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = _manga.chapters[index];
                  return ListTile(
                    title: Text(
                      'Chương ${chapter.number}: ${chapter.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Cập nhật: ${_formatDate(chapter.uploadDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Mở trang đọc truyện
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadChapterMangaPage(
                            manga: _manga,
                            chapter: chapter,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: _manga.chapters.length,
              ),
            ),
        ],
      ),
      floatingActionButton: !_isLoading && _manga.chapters.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Mở chương đầu tiên
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadChapterMangaPage(
                      manga: _manga,
                      chapter: _manga.chapters.first,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.brown,
              icon: const Icon(Icons.book),
              label: const Text('Đọc ngay'),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
