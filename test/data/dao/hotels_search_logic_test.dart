import 'package:flutter_test/flutter_test.dart';
import 'package:psn.hotels.hub/data/models/entities_database/hotel_model.dart';

void main() {
  group('Hotels Search Logic Test (Cyrillic & iOS Workaround)', () {
    // Имитируем данные из БД, как они приходят в mapListAllHotels
    final List<Map<String, dynamic>> mockDbData = [
      {
        'id': 1,
        'name': 'Отель Весна',
        'lat': 55.0,
        'long': 37.0,
        'country': 'Россия',
        'resort': 'Сочи',
        'active': 1,
        'cid': '123'
      },
      {
        'id': 2,
        'name': 'гостиница Алмаз',
        'lat': 55.1,
        'long': 37.1,
        'country': 'Россия',
        'resort': 'Москва',
        'active': 1,
        'cid': '124'
      },
      {
        'id': 3,
        'name': 'Зелёный бор',
        'lat': 55.2,
        'long': 37.2,
        'country': 'Беларусь',
        'resort': 'Минск',
        'active': 1,
        'cid': '125'
      },
      {
        'id': 4,
        'name': 'Grand Hotel',
        'lat': 40.0,
        'long': 20.0,
        'country': 'Turkey',
        'resort': 'Antalya',
        'active': 1,
        'cid': '126'
      },
    ];

    test('Should find hotel with different case (LOWER/UPPER)', () {
      const searchText = 'ОТЕЛЬ';
      final searchWords = searchText.trim().toLowerCase().split(RegExp(r'\s+'));

      final filtered = mockDbData.where((hotelMap) {
        String name = (hotelMap['name'] ?? "").toString().toLowerCase();
        return searchWords.every((word) => name.contains(word));
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first['name'], 'Отель Весна');
    });

    test('Should find hotel with "ё" character', () {
      // В реальности мы ищем точное совпадение или заменяем е/ё.
      // Наш текущий код в DAO ищет name.contains(word).
      // Чтобы "зеленый" находил "Зелёный", обычно нужна нормализация,
      // но проверим как работает текущая логика с буквой "ё" в запросе.

      const searchTextWithYo = 'Зелёный';
      final wordsYo =
          searchTextWithYo.trim().toLowerCase().split(RegExp(r'\s+'));

      final filtered = mockDbData.where((hotelMap) {
        String name = (hotelMap['name'] ?? "").toString().toLowerCase();
        return wordsYo.every((word) => name.contains(word));
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first['name'], 'Зелёный бор');
    });

    test('Should find by multiple words', () {
      const searchText = 'гостиница алмаз';
      final searchWords = searchText.trim().toLowerCase().split(RegExp(r'\s+'));

      final filtered = mockDbData.where((hotelMap) {
        String name = (hotelMap['name'] ?? "").toString().toLowerCase();
        return searchWords.every((word) => name.contains(word));
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first['id'], 2);
    });

    test('Should return empty list if nothing found', () {
      const searchText = 'Несуществующий';
      final searchWords = searchText.trim().toLowerCase().split(RegExp(r'\s+'));

      final filtered = mockDbData.where((hotelMap) {
        String name = (hotelMap['name'] ?? "").toString().toLowerCase();
        return searchWords.every((word) => name.contains(word));
      }).toList();

      expect(filtered, isEmpty);
    });

    test('Model creation from mock data should not fail', () {
      // Это проверка на ту самую ошибку Null is not a subtype of String
      final map = mockDbData.first;
      expect(() => HotelModel.fromMap(map), returnsNormally);

      final hotel = HotelModel.fromMap(map);
      expect(hotel.name, 'Отель Весна');
      expect(hotel.active, true);
    });
  });
}
