import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Полноэкранный просмотрщик фото с перелистыванием (свайпом) между
/// несколькими картинками и приближением (pinch-to-zoom) на каждой.
/// Используется одинаково везде, где в приложении есть фото — новости,
/// объявления, афиша, организации — чтобы поведение было единым.
class FullscreenGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenGalleryViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  static void open(BuildContext context, List<String> images,
      {int initialIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FullscreenGalleryViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  /// Тег для Hero-анимации между экраном-источником и просмотрщиком.
  /// Комбинирует URL с позицией в списке: одного URL недостаточно — если
  /// в галерее (например, объявления) случайно встречаются два одинаковых
  /// изображения, несколько Hero с одинаковым тегом в одном дереве виджетов
  /// приводят к падению приложения ("multiple heroes that share the same
  /// tag"). Экраны-источники должны использовать этот же метод для тега
  /// своих превью, иначе анимация перелёта просто не сработает.
  static String heroTag(String url, int index) => '$url#$index';

  @override
  State<FullscreenGalleryViewer> createState() =>
      _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<FullscreenGalleryViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final url = widget.images[index];
              return Center(
                child: Hero(
                  tag: FullscreenGalleryViewer.heroTag(url, index),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (widget.images.length > 1)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
