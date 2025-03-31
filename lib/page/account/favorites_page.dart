import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/manga.dart';
import '../manga/manga_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> _favoriteIds = [];
  List<Manga> _favoriteMangas = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = prefs.getStringList('favorite_mangas') ?? [];
    });

    // Danh sách truyện mẫu
    final allMangas = [
      Manga(
        id: '65581a2510dc9c0a7e2cedbe',
        title: 'Doraemon (chế) - Dota2VNBetGroup',
        author: 'Không rõ',
        description: 'Tuyển tập các mẩu truyện chế về Doraemon',
        coverUrl:
            'https://sv1.otruyencdn.com/uploads/20231118/912dd0642b1eaea2fec46b62b180f834/chapter_1/page_1.jpg',
        categories: ['Comedy'],
        viewCount: 5000,
        isHot: true,
        slug: 'doraemon-che-dota2vnbetgroup',
      ),
      Manga(
        id: 'tong-hop-vua-cuop-bien-anh-mau-chinh-goc',
        title: 'Tổng hợp Vua Cướp Biển ảnh màu chính gốc',
        author: 'Eiichiro Oda',
        description: 'Tập hợp các bức ảnh màu chính gốc của series One Piece',
        coverUrl:
            'https://sv1.otruyencdn.com/uploads/20231008/52db95737f664fe48e54958a6b481dc7/chapter_1/page_1.jpg',
        categories: ['Manga', 'Action', 'Adventure'],
        viewCount: 25000,
        isHot: true,
        slug: 'tong-hop-vua-cuop-bien-anh-mau-chinh-goc',
      ),
      Manga(
          id: "the-gioi-ngoc-rong-tuyen-tap-hai-huoc",
          title: "Dragonball Comedy",
          author: "Update",
          description: "Tuyen tap nhung mau truyen hai huoc ve dragonball",
          coverUrl:
              "https://img.otruyenapi.com/uploads/comics/the-gioi-ngoc-rong-tuyen-tap-hai-huoc-thumb.jpg",
          categories: ["Comedy", "Fantasy"],
          viewCount: 15000,
          isHot: false,
          slug: "the-gioi-ngoc-rong-tuyen-tap-hai-huoc"),
      Manga(
        id: 'cuu-vi-ho-ly-doujinshi-ve-cac-cap-doi',
        title: 'Cửu Vĩ Hồ Ly - Doujinshi Về Các Cặp Đôi',
        author: 'Không rõ',
        description: 'Tuyển tập doujinshi về các cặp đôi',
        coverUrl:
            'https://sv1.otruyencdn.com/uploads/20231116/64414ee8b2a47c712ddd7fdd5dccf416/chapter_1/page_1.jpg',
        categories: ['Romance', 'Doujinshi'],
        viewCount: 8000,
        isHot: false,
        slug: 'cuu-vi-ho-ly-doujinshi-ve-cac-cap-doi',
      ),
      Manga(
          id: "thanh-guom-diet-quy-rengoku-kyoujurou-gaiden",
          title: "Thanh guom diet quy - Rengoku",
          author: "Update",
          description:
              "Cau chuyen ve Rengoky, mot viem tru dieu khien lua manh nhat.",
          coverUrl:
              "https://img.otruyenapi.com/uploads/comics/thanh-guom-diet-quy-rengoku-kyoujurou-gaiden-thumb.jpg",
          categories: ["Action", "Fantasy", "Supernatural"],
          viewCount: 50000,
          isHot: true,
          slug: "thanh guom diet quy - Rengoku"),
      Manga(
        id: 'doraemon-color',
        title: 'Doraemon Color',
        author: 'Fujiko F. Fujio',
        description: 'Bộ truyện Doraemon phiên bản màu',
        coverUrl:
            'https://img.otruyenapi.com/uploads/comics/doraemon-color-thumb.jpg',
        categories: ['Comedy', 'Adventure', 'Kids'],
        viewCount: 50000,
        isHot: true,
        slug: 'doraemon-color',
      ),
      Manga(
          id: "657309aa-a7b870682dc3bb52",
          title: "Usui Hon-Shuu No Suru Pokemon",
          author: "Unknown",
          description: "Manga about Pokemon",
          coverUrl:
              "https://img.otruyenapi.com/uploads/comics/usui-hon-shuu-no-suru-pokemon-thumb.jpg",
          categories: ["Manga", "Pokémon"],
          viewCount: 1000,
          isHot: false,
          slug: "usui-hon-shuu-no-suru-pokemon"),
      Manga(
          id: "654e029c-19227e32c83cc522",
          title: "Yugi Oh - Transcend Game",
          author: "Unknown",
          description: "Manga about Yugi Oh - Transcend Game",
          coverUrl:
              "https://img.otruyenapi.com/uploads/comics/yugi-oh-r-thumb.jpg",
          categories: ["Manga", "Game", "Adventure"],
          viewCount: 1000,
          isHot: false,
          slug: "yugi-oh-r"),
      Manga(
          id: "6514502e-474e7dd8243f850c",
          title: "Special shinosuke",
          author: "unknow",
          description:
              "Cau chuyen ke ve shinosuke - cau be tinh nghich ma rat tinh kam :3",
          coverUrl:
              "https://img.otruyenapi.com/uploads/comics/shin-cau-be-but-chi-dac-biet-thumb.jpg",
          categories: ["Comedy", "Slice of Life", "Kids"],
          viewCount: 5000,
          isHot: true,
          slug: "shin-cau-be-but-chi-dac-biet")
    ];

    // Lọc các truyện yêu thích
    _favoriteMangas =
        allMangas.where((manga) => _favoriteIds.contains(manga.id)).toList();
  }

  Future<void> _toggleFavorite(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (_favoriteIds.contains(mangaId)) {
        _favoriteIds.remove(mangaId);
      } else {
        _favoriteIds.add(mangaId);
      }
    });

    // Lưu danh sách yêu thích
    await prefs.setStringList('favorite_mangas', _favoriteIds);

    // Cập nhật danh sách truyện yêu thích
    _favoriteMangas = _favoriteMangas
        .where((manga) => _favoriteIds.contains(manga.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truyện Yêu Thích'),
        backgroundColor: Colors.brown,
      ),
      body: _favoriteMangas.isEmpty
          ? const Center(
              child: Text(
                'Bạn chưa có truyện yêu thích',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _favoriteMangas.length,
              itemBuilder: (context, index) {
                final manga = _favoriteMangas[index];
                return ListTile(
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
                  subtitle: Text(manga.author),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _toggleFavorite(manga.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaDetailPage(manga: manga),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
