import 'package:flutter_test/flutter_test.dart';
import 'package:omsk_region_info/models/announcement_model.dart';

AnnouncementModel _announcement({DateTime? promotedUntil}) {
  return AnnouncementModel(
    id: 'a1',
    title: 'Заголовок',
    description: 'Текст',
    districtId: 'district1',
    createdAt: DateTime.now(),
    promotedUntil: promotedUntil,
  );
}

void main() {
  group('AnnouncementModel.isPromoted', () {
    test('без promotedUntil объявление не платное', () {
      expect(_announcement().isPromoted, isFalse);
    });

    test('promotedUntil в будущем — объявление платное', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(_announcement(promotedUntil: future).isPromoted, isTrue);
    });

    test('promotedUntil в прошлом — продвижение истекло', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(_announcement(promotedUntil: past).isPromoted, isFalse);
    });
  });
}
