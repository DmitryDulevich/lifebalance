# App Store Connect / TestFlight checklist

## Уже подготовлено в проекте

- [x] Bundle ID: `com.dds.lifebalance`
- [x] Версия `1.0`, build `1`
- [x] Deployment target iOS 17.0
- [x] Automatic signing
- [x] Export compliance key: `ITSAppUsesNonExemptEncryption = NO`
- [x] App Icon
- [x] `PrivacyInfo.xcprivacy`
- [x] Черновик публичной политики: `docs/privacy-policy.html`
- [x] Черновик русских метаданных: `release/AppStoreMetadata.ru.md`
- [x] Английские метаданные: `release/AppStoreMetadata.en.md`
- [x] Русская и английская версии Privacy Policy
- [x] Русская и английская локализации приложения

## Перед первой загрузкой

- [ ] Устранить блокировку Xcode Accounts: у текущей учётной записи нет App Store Connect provider
- [ ] Создать или загрузить App Store distribution provisioning profile для `com.dds.lifebalance`
- [ ] Включить GitHub Pages для каталога `/docs` и проверить публичный Privacy Policy URL
- [ ] Опубликовать Support URL с реальными контактными данными
- [ ] Создать приложение в App Store Connect с Bundle ID `com.dds.lifebalance`
- [ ] Проверить, что SKU и внутреннее имя выбраны окончательно
- [ ] Заполнить App Privacy: Tracking — No; Data Collection — No
- [ ] Заполнить возрастной рейтинг
- [x] Указать отсутствие non-exempt encryption в генерируемом `Info.plist`
- [ ] Подготовить скриншоты для обязательных размеров устройств
- [ ] Проверить интерфейс и скриншоты отдельно на русском и английском
- [ ] Проверить контактные данные для App Review и TestFlight
- [ ] Увеличить build number, если build `1` уже когда-либо загружался

## Загрузка и TestFlight

- [x] Создать новый Release Archive и проверить его локальную подпись
- [ ] Выполнить Validate App в Xcode Organizer
- [ ] Выполнить Distribute App → App Store Connect → Upload
- [ ] Дождаться обработки build в App Store Connect
- [ ] Заполнить Beta App Description, What to Test и Feedback Email
- [ ] Сначала включить Internal Testing
- [ ] После smoke-теста создать External Testing group и отправить build на TestFlight App Review

## Перед отправкой в App Review

- [ ] Финальная проверка метаданных и скриншотов
- [ ] Проверка политики и Support URL с внешнего устройства
- [ ] Проверка fresh install, upgrade и восстановления после перезапуска
- [ ] Выбор обработанного build для версии 1.0
- [ ] Заполнение Review Notes, если поведение приложения требует пояснений
