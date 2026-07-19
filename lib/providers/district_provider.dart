import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/district_model.dart';
import '../repositories/district_repository.dart';
import '../services/local_storage_service.dart';
import '../services/fcm_service.dart';

final districtRepositoryProvider = Provider((ref) => DistrictRepository());
final localStorageServiceProvider = Provider((ref) => LocalStorageService());
final fcmServiceProvider = Provider((ref) => FcmService());

/// Результат выбора района, возвращаемый экраном District Selection, когда
/// он открыт в режиме смены района (из "Настроек") через context.pop(result).
typedef DistrictPickResult = ({String id, String name});

/// Список всех активных районов (для экрана выбора района).
final districtsListProvider = FutureProvider<List<DistrictModel>>((ref) async {
  final repo = ref.watch(districtRepositoryProvider);
    return repo.getDistricts();
    });

    /// Состояние выбранного пользователем района.
    /// null означает "район ещё не выбран или не загружен".
    class SelectedDistrictState {
      final String? id;
        final String? name;
          final bool isLoading;

            const SelectedDistrictState({this.id, this.name, this.isLoading = true});

              bool get hasSelection => id != null && id!.isNotEmpty;

                SelectedDistrictState copyWith({String? id, String? name, bool? isLoading}) {
                    return SelectedDistrictState(
                          id: id ?? this.id,
                                name: name ?? this.name,
                                      isLoading: isLoading ?? this.isLoading,
                                          );
                                            }
                                            }

                                            class SelectedDistrictNotifier extends StateNotifier<SelectedDistrictState> {
                                              final LocalStorageService _storage;
                                                final FcmService _fcm;

                                                  SelectedDistrictNotifier(this._storage, this._fcm)
                                                        : super(const SelectedDistrictState()) {
                                                            _loadPersisted();
                                                              }

                                                                Future<void> _loadPersisted() async {
                                                                    final id = await _storage.getSelectedDistrictId();
                                                                        final name = await _storage.getSelectedDistrictName();
                                                                            state = SelectedDistrictState(id: id, name: name, isLoading: false);

                                                                                // Если район уже выбран ранее — гарантируем подписку на push этого района
                                                                                    // (например, после переустановки приложения без сброса локального хранилища
                                                                                        // на новом устройстве это не сработает, но для обычного запуска — надёжно).
                                                                                            if (id != null) {
                                                                                                  await _fcm.subscribeToDistrict(id);
                                                                                                      }
                                                                                                        }

                                                                                                          /// Сохраняет выбор района НАВСЕГДА и подписывает на push-уведомления района.
                                                                                                            /// Используется при первом выборе (экран District Selection при первом запуске).
                                                                                                              Future<void> selectDistrict(String id, String name) async {
                                                                                                                  await _storage.saveSelectedDistrict(districtId: id, districtName: name);
                                                                                                                      await _fcm.subscribeToDistrict(id);
                                                                                                                          state = SelectedDistrictState(id: id, name: name, isLoading: false);
                                                                                                                            }

                                                                                                                              /// Меняет ранее выбранный район на новый (экран "Настройки").
                                                                                                                                /// В отличие от [selectDistrict], здесь важно сначала отписаться от push
                                                                                                                                  /// старого района — иначе пользователь продолжит получать уведомления
                                                                                                                                    /// (например, об аварийном отключении воды) района, в котором больше не живёт.
                                                                                                                                      Future<void> changeDistrict(String newId, String newName) async {
                                                                                                                                          final previousId = state.id;
                                                                                                                                              if (previousId != null && previousId != newId) {
                                                                                                                                                    await _fcm.unsubscribeFromDistrict(previousId);
                                                                                                                                                        }
                                                                                                                                                            await _storage.saveSelectedDistrict(districtId: newId, districtName: newName);
                                                                                                                                                                await _fcm.subscribeToDistrict(newId);
                                                                                                                                                                    state = SelectedDistrictState(id: newId, name: newName, isLoading: false);
                                                                                                                                                                      }
                                                                                                                                                                      }

                                                                                                                                                                      final selectedDistrictProvider =
                                                                                                                                                                          StateNotifierProvider<SelectedDistrictNotifier, SelectedDistrictState>((ref) {
                                                                                                                                                                            return SelectedDistrictNotifier(
                                                                                                                                                                                ref.watch(localStorageServiceProvider),
                                                                                                                                                                                    ref.watch(fcmServiceProvider),
                                                                                                                                                                                      );
                                                                                                                                                                                      });
