# Cdek

Минималистичный Ruby/Rails-клиент для CDEK API v2.

Никаких внешних рантайм-зависимостей — только стандартная библиотека
(`net/http`, `json`, `uri`). Автоматически управляет OAuth2-токеном
(`grant_type=client_credentials`), кэширует и обновляет его, ретраит запрос
один раз при `401`.

## Установка

В `Gemfile` вашего Rails-приложения:

```ruby
gem "cdek"
```

Затем:

```bash
bundle install
bin/rails generate cdek:install
```

Генератор создаст `config/initializers/cdek.rb` со всеми ключами для
настройки.

## Конфигурация

```ruby
# config/initializers/cdek.rb
Cdek.configure do |config|
  config.account         = ENV["CDEK_ACCOUNT"]
  config.secure_password = ENV["CDEK_SECURE_PASSWORD"]

  if Rails.env.production?
    config.production_mode!  # https://api.cdek.ru/v2
  else
    config.test_mode!        # https://api.edu.cdek.ru/v2
  end

  # Опционально:
  # config.timeout      = 15
  # config.open_timeout = 5
  # config.user_agent   = "MyApp/1.0"
  # config.logger       = Rails.logger
end
```

Для быстрой проверки в песочнице можно подставить публичные тестовые креды
CDEK:

```ruby
config.use_sandbox_credentials!
```

## Использование

`Cdek.client` — потокобезопасный шареный клиент. Все методы принимают
относительный путь к API; токен подставляется автоматически.

```ruby
# Расчёт тарифа
Cdek.client.post(
  "/calculator/tariff",
  body: {
    tariff_code:   137,
    from_location: { code: 270 },
    to_location:   { code: 44 },
    packages:      [{ weight: 1000, length: 10, width: 10, height: 10 }]
  }
)

# Список городов
Cdek.client.get("/location/cities", params: { country_codes: "RU", size: 10 })

# Создание заказа
Cdek.client.post("/orders", body: order_payload)

# Получение заказа по UUID
Cdek.client.get("/orders/#{uuid}")
```

Ответ — распарсенный `Hash` из JSON-тела.

Высокоуровневые обёртки (`Cdek::Resources::Calculator`, `::Orders`,
`::Locations`, `::Offices`, `::Webhooks`) появятся в следующей итерации.

## Ошибки

Все ошибки наследуются от `Cdek::Error`:

| Класс | Когда возникает |
|-------|-----------------|
| `Cdek::ConfigurationError` | не заданы `account` / `secure_password` |
| `Cdek::AuthenticationError` | `401` после повторной попытки |
| `Cdek::BadRequestError` | `400` — невалидный payload |
| `Cdek::NotFoundError` | `404` |
| `Cdek::RateLimitError` | `429` |
| `Cdek::ServerError` | `5xx` |
| `Cdek::ApiError` | прочие неуспешные статусы |
| `Cdek::ConnectionError` | сетевая ошибка |
| `Cdek::TimeoutError` | таймаут |

У `ApiError` доступны `#status`, `#body`, `#errors`:

```ruby
begin
  Cdek.client.post("/orders", body: payload)
rescue Cdek::BadRequestError => e
  Rails.logger.warn(e.errors) # массив ошибок от CDEK
end
```

## Сброс состояния

```ruby
Cdek.client.reset_token! # принудительно перевыпустить токен
Cdek.reset_client!       # пересоздать клиента (после смены конфигурации)
Cdek.reset!              # сброс и конфигурации, и клиента
```

## Лицензия

MIT.
