import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project_btl/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../bloc/manga_bloc.dart';
import '../../bloc/history_reading_bloc.dart';
import '../../model/manga.dart';
import '../../model/history.dart';
import 'manga_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MangaBloc _mangaBloc = MangaBloc();
  final HistoryReadingBloc _historyBloc = HistoryReadingBloc();
  bool _isExpanded = false; // Biến điều khiển việc mở rộng danh sách

  @override
  void initState() {
    super.initState();
    _mangaBloc.event.add(MangaEvent.fetchHotMangas);
    _mangaBloc.event.add(MangaEvent.fetchMangas);
    _historyBloc.event.add(HistoryEvent.fetch);
  }

  @override
  void dispose() {
    _mangaBloc.dispose();
    _historyBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MangaZ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _mangaBloc.event.add(MangaEvent.refresh);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reading history section
              StreamBuilder<HistoryState>(
                stream: _historyBloc.state,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final state = snapshot.data!;
                  final history = state.history;

                  if (history.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Lịch sử đọc truyện',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: history.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemBuilder: (context, index) {
                            return _buildHistoryItem(history[index]);
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),

              // Hot manga section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Truyện Hot mỗi ngày',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StreamBuilder<MangaState>(
                stream: _mangaBloc.state,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final state = snapshot.data!;

                  if (state.isLoading && state.hotMangas.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state.hotMangas.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('Không tìm thấy truyện hot'),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.hotMangas.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (context, index) {
                        return _buildMangaCard(state.hotMangas[index]);
                      },
                    ),
                  );
                },
              ),
              const Divider(),

              // All manga section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Danh sách truyện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StreamBuilder<MangaState>(
                stream: _mangaBloc.state,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final state = snapshot.data!;

                  if (state.isLoading && state.mangas.isEmpty) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state.mangas.isEmpty) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Text('Không tìm thấy truyện nào'),
                      ),
                    );
                  }

                  // Xác định số lượng truyện hiển thị
                  final displayMangas = _isExpanded
                      ? state.mangas
                      : state.mangas.take(6).toList();

                  return Column(
                    children: [
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayMangas.length,
                        itemBuilder: (context, index) {
                          // Nếu là mục cuối cùng và có thể tải thêm
                          if (index == displayMangas.length - 1 &&
                              state.hasMore &&
                              !state.isLoading) {
                            _mangaBloc.event.add(MangaEvent.loadMore);
                          }
                          return _buildMangaGridItem(displayMangas[index]);
                        },
                      ),

                      // Nút mở rộng/thu gọn
                      if (state.mangas.length > 6)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _isExpanded ? 'Thu gọn' : 'Xem thêm',
                                    style: TextStyle(
                                      color: Colors.brown.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    _isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.brown.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (state.isLoading && state.mangas.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  );
                },
              ),

              // Pagination info
              StreamBuilder<MangaState>(
                stream: _mangaBloc.state,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.mangas.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final state = snapshot.data!;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Trang ${state.currentPage}/${state.totalPages}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32), // Khoảng cách dưới cùng
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ReadingHistory history) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailPage(manga: history.manga),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: history.manga.coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              history.manga.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Đọc: ${_formatDate(history.timestamp)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMangaCard(Manga manga) {
    return InkWell(
      onTap: () {
        _historyBloc.addToHistory(manga);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailPage(manga: manga),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: manga.coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              manga.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              manga.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMangaGridItem(Manga manga) {
    return InkWell(
      onTap: () {
        _historyBloc.addToHistory(manga);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailPage(manga: manga),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: manga.coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.remove_red_eye,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        manga.viewCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
