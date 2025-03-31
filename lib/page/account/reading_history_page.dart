import 'package:flutter/material.dart';
import '../../bloc/history_reading_bloc.dart';
import '../manga/manga_detail_page.dart';

class ReadingHistoryPage extends StatefulWidget {
  const ReadingHistoryPage({super.key});

  @override
  State<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends State<ReadingHistoryPage> {
  final HistoryReadingBloc _historyBloc = HistoryReadingBloc();

  @override
  void initState() {
    super.initState();
    _historyBloc.event.add(HistoryEvent.fetch);
  }

  @override
  void dispose() {
    _historyBloc.dispose();
    super.dispose();
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Lịch Sử Đọc'),
        content:
            const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử đọc truyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _historyBloc.event.add(HistoryEvent.clear);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _removeFromHistory(String mangaId) {
    _historyBloc.removeFromHistory(mangaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Đọc Truyện'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever,
                color: Colors.red), // Thêm màu đỏ
            onPressed: _clearHistory,
            tooltip: 'Xóa toàn bộ lịch sử',
          ),
        ],
      ),
      body: StreamBuilder<HistoryState>(
        stream: _historyBloc.state,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final history = snapshot.data!.history;

          if (history.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa đọc truyện nào',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final historyItem = history[index];
              final manga = historyItem.manga;

              return Dismissible(
                key: Key(manga.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeFromHistory(manga.id);
                },
                child: ListTile(
                  leading: Image.network(
                    manga.coverUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 70,
                        color: Colors.grey,
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                  title: Text(manga.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(manga.author),
                      Text(
                        _formatDate(historyItem.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeFromHistory(manga.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaDetailPage(manga: manga),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
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
