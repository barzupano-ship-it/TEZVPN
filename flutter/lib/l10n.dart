import 'config.dart';

class L10n {
  L10n(this.code);
  final String code;
  bool get en => code == 'en';
  bool get apple => ShopConfig.appleStore;
  String pick(String ru, String en) => this.en ? en : ru;

  String get accessTitle => pick('Доступ к VPN', 'VPN access');
  String get accessNone => pick(
        'У вашего аккаунта пока нет доступа к VPN. Отправьте запрос — администратор свяжется с вами и откроет доступ.',
        'Your account does not have VPN access yet. Send a request and the administrator will contact you and open access.',
      );
  String get accessRequest => pick('Отправить запрос', 'Send request');
  String get accessRequested => pick(
        'Запрос отправлен. Администратор свяжется с вами, после подтверждения VPN включится сам.',
        'Request sent. The administrator will contact you; VPN turns on by itself after confirmation.',
      );
  String accessActive(String until) => until.isEmpty
      ? pick('Доступ открыт.', 'Access is active.')
      : pick('Доступ открыт до $until.', 'Access is active until $until.');
  String get accessRejected => pick(
        'Запрос отклонён. Можно отправить новый запрос или написать в поддержку.',
        'The request was declined. You can send a new request or contact support.',
      );
  String get accessSignIn => pick('Чтобы отправить запрос, войдите в аккаунт.', 'Sign in to send a request.');
  String get deleteAccount => pick('Удалить аккаунт', 'Delete account');
  String get deleteAccountBody => pick(
        'Аккаунт, доступ к VPN, сообщения в поддержку и все данные будут удалены без возможности восстановления.',
        'Your account, VPN access, support messages and all data will be permanently deleted.',
      );
  String get deleteAccountYes => pick('Удалить', 'Delete');
  String get cancel => pick('Отмена', 'Cancel');
  String get accountDeleted => pick('Аккаунт удалён.', 'Account deleted.');

  String get appTitle => ShopConfig.appName;
  String get tagline => apple
      ? pick('Быстрый и защищённый VPN', 'Fast and secure VPN')
      : pick(
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
  String get waitingReview => apple
      ? accessRequested
      : pick('Чек на проверке. VPN включится сам.', 'Receipt is under review. VPN will turn on by itself.');
  String get buyFirst => apple
      ? accessNone
      : pick(
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
  String get rejected => apple
      ? accessRejected
      : pick('Чек отклонён. Выберите тариф заново.', 'Receipt declined. Choose a plan again.');
  String get disabled => pick('Доступ отключён администратором.', 'Access was disabled by the admin.');
  String get subscriptionExpired => apple
      ? pick(
          'Срок доступа закончился. Отправьте запрос, чтобы снова включить VPN.',
          'Your access has ended. Send a request to turn VPN on again.',
        )
      : pick(
          'Срок подписки закончился. Купите тариф, чтобы снова включить VPN.',
          'Your subscription has ended. Buy a plan to turn VPN on again.',
        );
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
  String get registerTitle => pick('Регистрация', 'Create account');
  String get registerHint => pick(
        'Логин латиницей и пароль от 8 символов. Заказы и VPN останутся на этом аккаунте.',
        'A Latin login and a password of at least 8 characters. Orders and VPN stay on this account.',
      );
  String get loginLabel => pick('Логин', 'Login');
  String get passwordLabel => pick('Пароль', 'Password');
  String get passwordAgain => pick('Пароль ещё раз', 'Password again');
  String get createAccount => pick('Создать аккаунт', 'Create account');
  String get signInTitle => pick('Вход', 'Sign in');
  String get otherAccount => pick('Другой аккаунт', 'Another account');
  String get loginRules => pick(
        'Логин: латиница, цифры и _, от 3 до 24 символов.',
        'Login: Latin letters, digits and _, 3 to 24 characters.',
      );
  String get passwordRules => pick('Пароль: минимум 8 символов.', 'Password: at least 8 characters.');
  String get passwordMismatch => pick('Пароли не совпадают.', 'Passwords do not match.');
  String get registered => pick('Аккаунт создан. Вы вошли.', 'Account created. You are signed in.');
  String signedInAs(String login) => pick('Вы вошли как $login', 'Signed in as $login');
  String get attachLogin => pick(
        'Придумайте логин и пароль, чтобы входить без кода.',
        'Choose a login and password so you can sign in without the code.',
      );
  String get support => pick('Поддержка', 'Support');
  String get enterName => pick('Введите имя', 'Enter a name');
  String get sendingReceipt => pick('Отправляем чек…', 'Sending receipt…');
  String get receiptSent => pick(
        'Чек отправлен. Ждём подтверждение — VPN включится сам.',
        'Receipt sent. Waiting for confirmation — VPN will turn on by itself.',
      );
  String get loggedIn => pick('Вход выполнен', 'Signed in');
  String get vpnOff => pick('VPN выключен', 'VPN is off');
  String get buyPlanFirst => apple
      ? pick('Сначала нужен доступ к VPN', 'VPN access is needed first')
      : pick('Сначала купите тариф', 'Buy a plan first');
  String get allowVpn => pick(
        'Разрешите VPN в системе, затем нажмите ещё раз.',
        'Allow VPN in the system, then tap again.',
      );
  String get vpnEnabled => pick('VPN включён', 'VPN is on');
  String get paidConnecting => apple
      ? pick('Доступ открыт. Подключаем VPN…', 'Access is open. Connecting VPN…')
      : pick('Оплата принята. Подключаем VPN…', 'Payment accepted. Connecting VPN…');
  String get paidTap => apple
      ? pick('Доступ открыт. Нажмите кнопку и разрешите VPN.', 'Access is open. Tap the button and allow VPN.')
      : pick(
          'Оплата принята. Нажмите кнопку и разрешите VPN.',
          'Payment accepted. Tap the button and allow VPN.',
        );

  String get notConnected => pick('Нет подключения', 'Not Connected');
  String get connectedLabel => pick('Подключено', 'Connected');
  String get connectingDots => pick('Подключение...', 'Connecting...');
  String get disconnectingDots => pick('Отключение...', 'Disconnecting...');
  String get tapToConnect => pick('Нажмите, чтобы подключить', 'Tap to connect');
  String get tapToDisconnect => pick('Нажмите, чтобы отключить', 'Tap to disconnect');
  String get upload => pick('Отдача', 'Upload');
  String get download => pick('Загрузка', 'Download');
  String get unlockMore => pick('Больше интернета\nза меньшие деньги', 'Unlock more of the\ninternet for less');
  String get plansTitle => pick('Тарифы', 'Plans');
  String get choosePlan => pick('Выбрать', 'Select');
  String get currentPlan => pick('ТЕКУЩИЙ ТАРИФ', 'CURRENT PLAN');
  String get autoRenewOff => pick('Отключить автопродление', 'Turn off auto-renew');
  String get perMonth => pick('в месяц', 'per month');
  String get freeWord => pick('Бесплатно', 'Free');
  String periodMonths(int months) {
    switch (months) {
      case 1:
        return pick('1 месяц', '1 month');
      case 3:
        return pick('3 месяца', '3 months');
      case 6:
        return pick('6 месяцев', '6 months');
      case 12:
        return pick('12 месяцев', '12 months');
      default:
        return pick('$months мес.', '$months mo.');
    }
  }

  String planSubtitle(String id) {
    switch (id) {
      case 'standard':
        return pick('Обычный доступ', 'Basic access');
      case 'premium':
        return pick('Расширенная защита', 'Extended protection');
      case 'vip':
        return pick('Максимум возможностей', 'Full access');
      default:
        return '';
    }
  }

  String planFeature(String feature) {
    switch (feature) {
      case '3 устройства':
        return pick('3 устройства', '3 devices');
      default:
        return feature;
    }
  }

  String monthlyLine(String somoni, String yuan) => yuan.isEmpty
      ? pick('≈ $somoni смн в месяц', '≈ $somoni TJS per month')
      : pick('≈ $somoni смн · ¥$yuan в месяц', '≈ $somoni TJS · ¥$yuan per month');

  String get settingsAccount => pick('Кабинет', 'Account');
  String get settingsSignIn => pick('Войти', 'Sign in');
  String get settingsEmailOrPhone => pick('Почта или телефон', 'Email or phone');
  String get settingsOtherDevice => pick('Войти на другом устройстве', 'Sign in on another device');
  String get settingsFeatures => pick('Возможности', 'Features');
  String get settingsOff => pick('Выкл', 'Off');
  String get settingsSplit => pick('Раздельное туннелирование', 'Split tunneling');
  String get settingsKill => pick('Аварийное отключение', 'Kill switch');
  String get settingsConnection => pick('Подключение', 'Connection');
  String get settingsProtocol => pick('Протокол', 'Protocol');
  String get settingsAccelerator => pick('Ускорение VPN', 'VPN Accelerator');
  String get settingsAdvanced => pick('Дополнительно', 'Advanced settings');
  String get settingsGeneral => pick('Общие', 'General');
  String get settingsLanguage => pick('Язык', 'Language');
  String get settingsHelp => pick('Помощь и поддержка', 'Help and support');
  String get settingsPrivacy => pick('Конфиденциальность', 'Privacy');
  String get settingsPhone => pick('Телефон', 'Phone');
  String get logout => pick('Выйти', 'Log out');
  String get proRequired => apple
      ? pick('Эта функция недоступна для вашего доступа.', 'This feature is not included in your access.')
      : pick(
          'Нужен тариф Premium или VIP.',
          'This feature requires a Premium or VIP subscription.',
        );
  String get registerButton => pick('Регистрация', 'Register');
  String get loginButton => pick('Вход', 'Sign in');
  String get registerBlurb => pick(
        'Почта или телефон и пароль от 8 символов.',
        'Email or phone and a password of at least 8 characters.',
      );
  String get loginBlurb => pick('Введите почту или телефон и пароль.', 'Enter your email or phone and password.');
  String get legalPrefix => pick('Продолжая, вы соглашаетесь с ', 'By continuing, you agree to the ');
  String get legalTerms => pick('Условиями использования', 'Terms of Use');
  String get legalAnd => pick(' и ', ' and ');
  String get legalPrivacy => pick('Политикой конфиденциальности', 'Privacy Policy');
  String get otherDeviceBody => pick(
        'Откройте приложение на другом телефоне и войдите той же почтой или телефоном и паролем. Вход по QR-коду недоступен.',
        'Open the app on the other phone and sign in with the same email or phone and password. A QR sign-in session is not available.',
      );
  String get netshieldBody => pick(
        'NetShield выключен. Этот VPN не фильтрует рекламу и трекеры.',
        'NetShield is off. This VPN engine does not filter ads or trackers.',
      );
  String get splitBody => pick(
        'Раздельное туннелирование выключено. Нельзя выбрать, какие приложения идут через VPN.',
        'Split tunneling is off. This build cannot choose which apps use the VPN.',
      );
  String get killBody => pick(
        'Аварийное отключение выключено. Приложение не блокирует трафик, если туннель оборвался.',
        'Kill switch is off. This build does not block traffic when the tunnel drops.',
      );
  String get acceleratorBody => pick(
        'Ускорение VPN выключено. В движке нет отдельной функции ускорения.',
        'VPN Accelerator is off. There is no speed feature connected to the VPN engine.',
      );
  String get advancedBody => pick(
        'Протокол — AmneziaWG. Ниже открываются фильтр DNS, раздельный туннель, аварийное отключение и DNS 1.1.1.1.',
        'The protocol is AmneziaWG. The rows below open the DNS filter, split tunnel, kill switch, and DNS 1.1.1.1.',
      );
  String get protocolBody => pick(
        'AmneziaWG — единственный протокол в этом VPN.',
        'AmneziaWG is the only protocol in this VPN engine.',
      );
  String get privacyDraft => privacyPolicy;
  String get privacyPolicy => apple
      ? pick(
          'SULTAN VPN обрабатывает данные, нужные для аккаунта и VPN: почту или телефон, статус доступа, слоты устройств и сообщения в поддержку. VPN не записывает трафик, посещённые сайты и DNS-запросы. Мы не продаём эти данные и не используем их для рекламы. Аккаунт и все данные можно удалить в настройках. Трафик в туннеле шифруется протоколом AmneziaWG.',
          'SULTAN VPN processes data needed for the account and VPN: email or phone, access status, device slots and support messages. The VPN does not log traffic, visited sites or DNS queries. We do not sell this data or use it for ads. You can delete your account and all data in Settings. Tunnel traffic is encrypted with AmneziaWG.',
        )
      : pick(
        'SULTAN VPN обрабатывает данные, нужные для кабинета и VPN: логин, статус подписки, слоты устройств, сообщения в поддержку и фото чека, если вы его загружаете. Конфиг VPN выдаётся только после оплаты. Мы не продаём эти данные и не используем их для рекламы. Трафик в туннеле шифруется протоколом AmneziaWG. Вопросы: Telegram поддержки в приложении.',
        'SULTAN VPN processes data needed for the account and VPN: login, subscription status, device slots, support messages, and a receipt photo if you upload one. A VPN config is issued only after payment. We do not sell this data or use it for ads. Tunnel traffic is encrypted with AmneziaWG. Contact: in-app Telegram support.',
      );
  String get termsOfUse => apple
      ? pick(
          'SULTAN VPN работает, пока у аккаунта открыт доступ. После окончания срока туннель отключается. Сервис не обещает обход любых блокировок и не несёт ответственность за использование сети в нарушение закона вашей страны.',
          'SULTAN VPN works while the account has active access. When access ends, the tunnel stops. The service does not promise to bypass every block and is not responsible for unlawful use.',
        )
      : pick(
        'SULTAN VPN — платный сервис. VPN работает, пока активна оплаченная подписка. После окончания срока туннель отключается до новой оплаты. Сервис не обещает обход любых блокировок и не несёт ответственность за использование сети в нарушение закона вашей страны. Оплата и возврат — по правилам магазина в приложении.',
        'SULTAN VPN is a paid service. VPN works while a paid subscription is active. When it expires the tunnel stops until you pay again. The service does not promise to bypass every block and is not responsible for unlawful use. Payment and refunds follow the in-app shop rules.',
      );
  String get protocolActive => pick(
        'Переподключите VPN, чтобы продолжить с AmneziaWG.',
        'Reconnect the VPN to keep using AmneziaWG.',
      );
  String get protocolMissing => pick('Этот протокол недоступен.', 'This protocol is not available.');
}
