import 'package:flutter/material.dart';
import 'package:project_btl/repositories/manga_repository.dart';
import '../model/manga.dart';
import '../bloc/history_reading_bloc.dart';
import 'manga/manga_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final MangaRepository _mangaRepository = MangaRepository();
  final HistoryReadingBloc _historyBloc = HistoryReadingBloc();

  List<Manga> _searchResults = [];
  List<Manga> _allMangas = [];
  bool _isLoading = true;
  String? _error;

  // Danh sách thể loại
  final List<String> _categories = [
    'Tất cả',
    'Manga',
    'Comedy',
    'Action',
    'Romance',
    'Fantasy',
    'Adventure',
    'Supernatural'
  ];
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _fetchAllMangas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _historyBloc.dispose();
    super.dispose();
  }

  Future<void> _fetchAllMangas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _mangaRepository.getMangas(page: 1, limit: 100);
      setState(() {
        _allMangas = result['mangas'];
        _searchResults = _allMangas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải danh sách truyện: $e';
        _isLoading = false;
      });
    }
  }

  void _filterMangas(String query, String category) {
    setState(() {
      _searchResults = _allMangas.where((manga) {
        final matchesQuery = query.isEmpty ||
            manga.title.toLowerCase().contains(query.toLowerCase()) ||
            manga.author.toLowerCase().contains(query.toLowerCase());

        final matchesCategory =
            category == 'Tất cả' || manga.categories.contains(category);

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tìm kiếm',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên truyện, tác giả...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterMangas('', _selectedCategory);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                _filterMangas(value, _selectedCategory);
              },
            ),
          ),

          // Danh sách thể loại
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: _selectedCategory == _categories[index],
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = _categories[index];
                        _filterMangas(
                            _searchController.text, _selectedCategory);
                      });
                    },
                    selectedColor: Colors.brown.shade100,
                    backgroundColor: Colors.grey.shade200,
                  ),
                );
              },
            ),
          ),

          // Danh sách truyện
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Không có kết quả. Hãy thử từ khóa khác.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final manga = _searchResults[index];
                              return _buildSearchResultItem(manga);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Manga manga) {
    return InkWell(
      onTap: () {
        // Thêm vào lịch sử
        _historyBloc.addToHistory(manga);

        // Chuyển đến trang chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailPage(manga: manga),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(manga.coverUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: manga.isHot
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manga.author,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (String category in manga.categories.take(3))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: Colors.brown.shade800,
                              fontSize: 12,
                            ),
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
}
