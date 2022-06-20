# 02. Установка RSpec (Setting up RSpec)

В этой глеве мы решим следующие задачи:
- Используем [Bundler](https://bundler.io/) чтобы установить [RSpec](https://rubygems.org/gems/rspec/versions) и друге полезные gem'ы
- Мы проверим наличие тестовой базы данных и при необходимости установим ее.
- Настроим Конфиг RSpec что бы протестить то что мы хотим протестить(c)=)
- Настроим автоматическое создание файлов для написания тестов при добавлении новых фич.

Как переключится из `bash` на ветку второй главы:
```
git checkout -b 02_setup origin/02_setup
```
## Gemfile

Когда-то RSpec шел из коробки, но на данный момент его убрали. Поэтому добавим пару строк в наш `Gemfile` и с помощью `Bundler` установим необходимые зависимости:

```
group :development, :test do
  gem "rspec-rails", "~> 3.1.0"
  gem "factory_girl_rails", "~> 4.4.1"
end

group :test do
  gem "faker", "~> 1.4.3"
  gem "capybara", "~> 2.4.3"
  gem "database_cleaner", "~> 1.3.0"
  gem "launchy", "~> 2.4.2"
  gem "selenium-webdriver", "~> 2.43.0"
end
```

**Версии гемов соответствуют конфигу Spec 3.1/Rails 4.1!**

Если шо [вот](https://bundler.io/v2.3/#getting-started) избыточный гайд по `bundler`

## Почему установка идет в две разные группы?

`rspec-rails` и `factory_girl_rails` используются в двух средах:

| developement | test |
| ------------ | ---- |
| генераторы | остальной функционал |

Так же такая группировка нас уберегает от внезапного авто-создания кода и запуска тестов при деплое в продакшн.

Сбандлим это дело:
```
bundle install
```

Что мы установили?
- [_rspec-rails_](https://github.com/rspec/rspec-rails/tree/3-1-maintenance) включает в себя сам RSpec и некоторые спецефические особенности
- _factory_girl_rails_ заменяет дефолтные [фикстуры](https://api.rubyonrails.org/v3.1/classes/ActiveRecord/Fixtures.html) на более предпочтительные [фабрики](https://github.com/thoughtbot/factory_bot_rails#factory_bot_rails---)(да, теперь это `factory_bot` :robot:)
- [_faker_](https://github.com/faker-ruby/faker) генерит имена, email'ы, адресса и кучу всего другого. Очень удобно. Можно не только для тестов юзать, но и для заполнения нульцевого проекта, чтоб смотрелось.
- [_capybara_](http://teamcapybara.github.io/capybara/) делает простой програмную симуляцию взаимодействий пользователя через браузер с нашим приложением
- [_database_cleaner_](https://github.com/DatabaseCleaner/database_cleaner) c ним вы можете быть уверенны что каждый запуск тестов будет начинаться с чистого листа, такой чистильщик базы данных.
- [_launchy_](https://github.com/copiousfreetime/launchy) запускает ваш дефолтный браузер чтоб показать вам что рендерит ваш браузер. Очень полезно при дебаге.
- [_selenium-webdriver_](https://github.com/SeleniumHQ/selenium/) позволяет нам тестировать взаимодействия основанные на JavaScript при помощи Capybara

Более подробно поговорим про эти инструменты в след главах.

## Тестовая база данных

Если вы будете добавлять тесты в имеющееся Rails приложение, скорее всего у вас уже есть тестова БД(база данных). Если же нет, то вот как её добавить:

Открываем `config/database.yml` что бы увидеть с какой БД ваше приложение готово обмениватся данными. Если вы не вносили никаких изменений в этот файл там должно быть что то такое.

**Для SQLite:**

`config/database.yml`
```
test:
  adapter: sqlite3
  database: db/test.sqlite3
  pool: 5
  timeout: 5000
```

**Для MySQL:**

`config/database.yml`
```
test:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: contacts_test
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock
```

**Для PostgreSQL:**

`config/database.yml`
```
test:
  adapter: postgresql
  encoding: utf8
  database: contacts_test
  pool: 5
  username: root # or your system username
  password:
```
Не забудьте заменить значение `database:` на название соответствующее БД вашего приложения.

Что бы убедится что все работает запускаем:

```
bundle exec rake db:create:all
```
_создает все БД прописаные в config/database.yml._

## Настройка RSpec

Теперь мы можем спокойненько добавить `spec` директорию в наше приложение и добавить несколько базовых настроек в RSpec.

Установка RSpec в приложение:
```
rails generate rspec:install
```

Генератор покорно нам сообщит:
```
create .rspec
create spec
create spec/spec_helper.rb
create spec/rails_helper.rb
```

- `.rspec` — Конфигурационный файл RSpec
- `spec` — Директория для тестов
- `spec/spec_helper.rb` и `spec/rails_helper.rb` — хелперы для взаимодействия с кодом. В этих файлах куча закоменченного кода с обьясненем возможных кастомизаций. Не надо прямо сейчас сильно вчитыватся в них, но по мере того как RSpec будет становится нашим рабочим инструментом необходимо будет ознакомится с ними очень хорошо.


И поменяем дефолтный вывод информации о тестах в консоль на формат "_документа_". Это позволяет лучше видеть какие тесты упали а какие прошли. откроем файл _.rspec_ и добавим туда одну строчку:  

`.rspec`
```
--format documentation
```

## Генераторы

