import 'config.dart';

class L10n {
  L10n(this.code);
  final String code;
  bool get en => code == 'en';
  String pick(String ru, String en) => this.en ? en : ru;

  String get appTitle => ShopConfig.appName;
  String get tagline => pick(
        'VPN включается в этом приложении сразу после оплаты',
        'VPN turns on in this app right after payment',
      );
  String get tabVpn => 'VPN';
  String get tabPlans => pick('Тарифы', 'Plans');
  String get tabPay => pick('Оплата', 'Pay');
  String get tabAccount => pick('Кабинет', 'Account');
  String get connecting => pick('Подключаем…', 'Connecting…');
  String get vpnOn => pick(
        'Интернет идёт через ${ShopConfig.appName}',
        'Internet is going through ${ShopConfig.appName}',
      );
  String get confReady => pick('Конфиг готов — нажмите, чтобы включить', 'Config is ready — tap to connect');
  String get waitingReview => pick('Чек на проверке. VPN включится сам.', 'Receipt is under review. VPN will turn on by itself.');
  String get buyFirst => pick(
        'Купите тариф — VPN подключится сразу после оплаты',
        'Buy a plan — VPN connects right after payment',
      );
  String get on => pick('ВКЛ', 'ON');
  String get turnOn => pick('ВКЛЮЧИТЬ', 'CONNECT');
  String get buy => pick('КУПИТЬ', 'BUY');
  String get plans => pick('Тарифы', 'Plans');
  String get plansFail => pick('Не загрузились тарифы. Проверьте интернет.', 'Plans did not load. Check the internet.');
  String get refresh => pick('Обновить', 'Refresh');
  String get devices => pick('устр.', 'dev.');
  String get buyBtn => pick('Купить', 'Buy');
  String get order => pick('Заказ', 'Order');
  String get noOrder => pick('Заказа нет. Выберите тариф.', 'No order. Choose a plan.');
  String get toPlans => pick('К тарифам', 'To plans');
  String get yourName => pick('Ваше имя', 'Your name');
  String get continueBtn => pick('Продолжить', 'Continue');
  String get payHint => pick(
        'Переведите по реквизитам и загрузите фото чека.',
        'Transfer using the details and upload a receipt photo.',
      );
  String get requisites => pick('Реквизиты', 'Payment details');
  String get uploadReceipt => pick('Загрузить чек', 'Upload receipt');
  String get waitAdmin => pick(
        'Ждём подтверждение администратора. VPN включится автоматически.',
        'Waiting for admin confirmation. VPN will turn on automatically.',
      );
  String get refreshStatus => pick('Обновить статус', 'Refresh status');
  String get readyVpn => pick('Готово. Можно включать VPN.', 'Ready. You can turn VPN on.');
  String get openVpn => pick('Открыть VPN', 'Open VPN');
  String get rejected => pick('Чек отклонён. Выберите тариф заново.', 'Receipt declined. Choose a plan again.');
  String get disabled => pick('Доступ отключён администратором.', 'Access was disabled by the admin.');
  String get pay => pick('Оплата', 'Payment');
  String get payee => pick('Получатель', 'Payee');
  String get loadingPay => pick('Реквизиты загружаются…', 'Loading payment details…');
  String get paidUpload => pick('Я оплатил — загрузить чек', 'I paid — upload receipt');
  String get account => pick('Кабинет', 'Account');
  String get accessCode => pick('Код доступа', 'Access code');
  String get inCabinet => pick('Вы в кабинете', 'You are in your cabinet');
  String cabinetReady(String code) => pick(
        'Кабинет создан, вы вошли. Код: $code',
        'Cabinet created, you are signed in. Code: $code',
      );
  String get saveCode => pick(
        'Сохраните код, чтобы войти с другого телефона.',
        'Save the code to sign in on another phone.',
      );
  String get otherPhone => pick('Войти с другого телефона', 'Sign in from another phone');
  String get continueOrder => pick('Продолжить заказ', 'Continue the order');
  String get loginByCode => pick('Войти по коду', 'Sign in with code');
  String get signIn => pick('Войти', 'Sign in');
  String get support => pick('Поддержка', 'Support');
  String get enterName => pick('Введите имя', 'Enter a name');
  String get sendingReceipt => pick('Отправляем чек…', 'Sending receipt…');
  String get receiptSent => pick(
        'Чек отправлен. Ждём подтверждение — VPN включится сам.',
        'Receipt sent. Waiting for confirmation — VPN will turn on by itself.',
      );
  String get loggedIn => pick('Вход выполнен', 'Signed in');
  String get vpnOff => pick('VPN выключен', 'VPN is off');
  String get buyPlanFirst => pick('Сначала купите тариф', 'Buy a plan first');
  String get allowVpn => pick(
        'Разрешите VPN в системе, затем нажмите ещё раз.',
        'Allow VPN in the system, then tap again.',
      );
  String get vpnEnabled => pick('VPN включён', 'VPN is on');
  String get paidConnecting => pick('Оплата принята. Подключаем VPN…', 'Payment accepted. Connecting VPN…');
  String get paidTap => pick(
        'Оплата принята. Нажмите кнопку и разрешите VPN.',
        'Payment accepted. Tap the button and allow VPN.',
      );
}
