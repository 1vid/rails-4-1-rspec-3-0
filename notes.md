# 04. Создание теcтовых данных при помощи фабрик

В прошлых главах мы использовали _старые добрые Ruby обьекты_ для создания временных данных в наших тестах. И наши тесты были не столь сложными. С усложнением сценариев, было круто упростить процесс создания данных, и сместить фокус на написание самих тестов. К счастью, уже есть библиотеки с которыми генерация данных становится проще простого. В этой главе мы рассмотрим `Factory Girl`([Factory Bot](https://github.com/thoughtbot/factory_bot)).

- Мы поговорим о плюсах и минусах использования фабрик относительно других методов
- Затем мы создадим базовую фабрику и подключим её к нашим спекам
- В процессе мы отредактируем наши фабрики и сделаем их еще более удобными
- Затем мы сделаем наши тестовые данные более реалистичными используя [gem Faker](https://github.com/faker-ruby/faker)
- Мы рассмотрим более продвинутые фабрики использующие асоциации [Active Record](https://guides.rubyonrails.org/association_basics.html)
- Упомянем про риск черезмерного внедрения фабрик в наше приложение

## Фабрики VS Фиксуры

В рельсах из коробки есть средство для создания тестовых данных — `fixtures`. По сути это YAML файлы. Например фикстура для модели `Contact` могла бы выглядеть так:

**contacts.yml**
```ruby
aaron:
  firstname: "Aaron"
  lastname: "Sumner"
  email: "aaron@everydayrails.com"

john:
  firstname: "John"
  lastname: "Doe"
  email: "johndoe@nobody.org"
```

Теперь если в тесте использовать `contacts(:aaron)` мы получим новый экземпляр модели `Contact`.

Фикстуры имеют право на существование. Но у них есть 2 больших минуса, которые уже много раз обсуждались сообществом.

- Данные в фикстурах могут быть очень хрупкими, а их поддержание будет занимать столько же времени сколько поддержание ваших тестов и основного кода приложения.

- Рельсы не смотрят на Active Record когда используют фикстуры, соответсвенно валидации игорируются, и это очень плохо!

Фабрики это простые и гибкие строительные блоки для создания тестовых данных. `Factory Girl` это простая в использовании, надежная библиотека, лишенная хрупкости фикстур. Конечно среди Rails разработчиков есть скептики относительно этой технологии и время от времени возникают [дебаты](https://groups.google.com/g/rubyonrails-core/c/_lcjRRgyhC0). Сложные асоциации которые подтягиваются в модели через актив рекорд сильно замедляют тесты. Но при этом они значительно облегчают жизнь разработчика и в целом со своей задачей справляются прекрасно.

## Создание фабрик в приложении

Вернемся директорию _spec_ и создадим поддерикторию _factories_ и создадим файл _categories.rb_:

**spec/factories/contacts.rb**
```ruby
FactoryGirl.define do
  factory :contact do
    firstname "John"
    lastname "Doe"
    sequence(:email) { |n| "johndoe#{n}@example.com"}
  end
end
```
Этот кусочек кода дает нам возможность использовать _фабрику_ в любом нашем спеке.
Теперь где бы мы не вызвали `FactoryGirl.create(:contact)`, мы получим экземпляр класса `Contact` с атрибуками указаными в фабрике(.name _John Doe_). А каждый раз при создании `email` при помощи `sequence` значение переменной `n` будет новым, например: johndoe1@example.com, johndoe2@example.com .... и т. д. `sequence` необходим для любой модели с валидацией `uniqueness: true` (чуть дяльше рассмотрим еще более матерый способ генерить такие вещи как _email_ при помощи гема `Faker`)

В примере приведенном выше все атрибуты являются "строками". Но можно указывать любые типы данных для атрибутов используя синтаксис руби (целые числа, числа с плавающей точкой, булевые значение и даты). Например десли бы у нашего контакта был бы атрибут "дата рождения" мы могли бы использовать `33.years.ago` или `Date.parse('1980-05-13')`.

Названия файлов для фабрик не так критичны как для спеков. Можно уложить хоть все фабрики в один файл. Тем не менее генератор "Factory Girl" создает файл по названию создаваемо модели во множественном числе, например _spec/factories/contacts.rb_ 

Давайте добавим нашу фабрику в _contact_spec.rb_:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'

describe Contact do
  it "has a valid factory" do
    expect(FactoryGirl.build(:contact)).to be_valid
  end
 
  ## more specs
end
```

`.build` создает экземпляр со всеми атрибутми указаными в фабрике, но не сохраняет его. В этом примере новый контакт валидный. Давайте сравним его с тем что мы делали в прошлой главе:

```ruby
it "is valid with a firstname, lastname and email" do
  contact = Contact.new(
    firstname: 'Aaron',
    lastname: 'Sumner',
    email: 'tester@example.com')
  expect(contact).to be_valid
end
```

Давайте вернемся к нашим спекам и оптимизируем тестовые данные при помощи `FactoryGirl`. В этот раз мы руками изменим некоторые атрибуты предоставленные нашей фабрикой:

**spec/models/contact_spec.rb**
```ruby
it "is invalid without a firstname" do
  contact = FactoryGirl.build(:contact, firstname: nil)
  contact.valid?
  expect(contact.errors[:firstname]).to include("can't be blank")
end

it "is invalid without a lastname" do
  contact = FactoryGirl.build(:contact, lastname: nil)
  contact.valid?
  expect(contact.errors[:lastname]).to include("can't be blank")
end

it "is invalid without an email address" do
  contact = FactoryGirl.build(:contact, email: nil)
  contact.valid?
  expect(contact.errors[:email]).to include("can't be blank")
end

it "returns a contact's full name as a string" do
  contact = FactoryGirl.build(:contact,
    firstname: "Jane",
    lastname: "Smith"
  )
  expect(contact.name).to eq 'Jane Smith'
end
```
Это простые примеры. Так же как и в предидущем примере все они используют метод `.build` для создания контакта(но при этом он не сохраняетя в базу). 
- В первом примере мы записываем в переменную `contact` экземпляр модели `Contact` с пустым(`nil`) атрибутом `firstname:`
- Во втором и третьем примере мы делаем то же самое с атрибутами `lastname:` и `email:`
Эти три теста предпологают ошибку валидации `"can't be blank"` которую мы ловим при помощи метода `include`. Так можно ловить и другие ошибки.

Четвертый спек немного отличается, но использует ту же базовую технику. В нем мы проверяем корректно ли работает метод `name` у экземпляра класса `Contact`, который мы записали в переменную `contact`.

Следующий тест будет отличатся:

**spec/models/contact_spec.rb**
```ruby
it "is invalid with a duplicate email address" do
  FactoryGirl.create(:contact, email: 'aaron@example.com')
  contact = FactoryGirl.build(:contact, email: 'aaron@example.com')
  contact.valid?
  expect(contact.errors[:email]).to include('has already been taken')
end
```

Здесь мы проверяем уникальность атрибута `email:` (валидацию `uniqueness: true`). Сначала мы обращаемся к фабрике с методом `.create`, и таким образом записываем контакт в тестовую базу. А потом уже создаем экземпляр методом `.build` и на нем уже пробуем наше предположение.

## :warning:

- `build` — сохраняет новый объект в памяти
- `create` — размещает атрибуты объекта в тестовой базе данных

## Упрощение синтаксиса

Большинство программистов терпеть не не могут писать больше кода чем нужно. Очень громоздко писать каждый раз `FactoryGirl.build(:contact)` когда нам нужно создаь контакт. Но к счастью `Factory girl` версии 3 и выше делает жизнь Rails разработчика чуть легче при помощи одной небольшой настройки. Надо добавить следующий код в файл `rails_helper.rb` внутри блока `RSpec.configure`:

**spec/rails_helper.rb**
```ruby
RSpec.configure do |config|
  # Include Factory Girl syntax to simplify calls to factories
  config.include FactoryGirl::Syntax::Methods

  # other configurations omitted ...
end
```

И сразу нужно удалить или закоментировать настройку `config.fixture_path`, теперь мы исользуем фабрики а не фикстуры!

Теперь мы в наших тестах можем использовать более короткий синтаксис без использования `FactoryGirl.` каждый раз:

- build(:contact)
- create(:contact)
- attributes_for(:contact)
- build_stubbed(:contact)

Давайте взглянем на наш обновленный и "похудевший" спек модели:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'

describe Contact do
  it "has a valid factory" do
    expect(build(:contact)).to be_valid
  end

  it "is invalid without a firstname" do
    contact = build(:contact, firstname: nil)
    contact.valid?
    expect(contact.errors[:firstname]).to include("can't be blank")
  end

  it "is invalid without a lastname" do
    contact = build(:contact, lastname: nil)
    contact.valid?
    expect(contact.errors[:lastname]).to include("can't be blank")
  end

  # remaining examples omitted ...
end
```

## Ассоциации и наследование в фабриках

Если мы напишем фабрику для нашей модели `Phone`, на данном этапе, она будет выглядеть вот так:

**spec/factories/phones.rb**
```ruby
FactoryGirl.define do
  factory :phone do
    association :contact
    phone '123-555-1234'
    phone_type 'home'
  end
end
```

В этом коде мы впервые встречаем метод `:association`, он сообщает `Factory girl` создать новый `Contact`. прямо "на лету", которому принадлежит этот номер. Исключением будет если мы явно передадим  ассоциированный `:contat` объект с его атрибутами методам `build` или `create`. 

Однако у контакта может быть три типа телефонов: домашний, офисный и мобильный. Если мы хотим указать в спеке не домашний телефон мы сделаем это следующим образом:

**spec/models/phone_spec.rb**
```ruby
it "allows two contacts to share a phone number" do
  create(:phone,
    phone_type: 'mobile',
    phone: "785-555-1234")
  expect(build(:phone,
    phone_type: 'mobile',
    phone: "785-555-1234")).to be_valid
end
```

Давайте сделаем небольшой рефакоринг. Factory Girl дает нам возможность создавать "_унаследованные_" фабрики, которые смогут перезаписывать атрибуты если это необходимо. Другими словами если мы хотим указать офисный телефон в тесте, мы должны будем написать `build(:office_phone)` или `FactoryGirl.build(:office_phone)` если вам так удобнее. Выглядеть это будет вот так:

**spec/factories/phones.rb**
```ruby
FactoryGirl.define do
  factory :phone do
    association :contact
    phone { Faker::PhoneNumber.phone_number }

    factory :home_phone do
      phone_type 'home'
    end

    factory :work_phone do
      phone_type 'work'
    end

    factory :mobile_phone do
      phone_type 'mobile'
    end
  end
end
```

И спек наш станет попроще:

**spec/models/phone_spec.rb**
```ruby
require 'rails_helper'

describe Phone do
  it "does not allow duplicate phone numbers per contact" do
    contact = create(:contact)
    create(:home_phone,
      contact: contact,
      phone: '785-555-1234'
    )
    mobile_phone = build(:mobile_phone,
      contact: contact,
      phone: '785-555-1234'
    )

    mobile_phone.valid?
    expect(mobile_phone.errors[:phone]).to include('has already been taken')
  end

  it "allows two contacts to share a phone number" do
    create(:mobile_phone,
      phone: '785-555-1234'
    )
    expect(build(:mobile_phone, phone: '785-555-1234')).to be_valid
  end
end
```

Эта техника нам очень пригодится в следующих главах где нам надо будет создавать разные типы пользователей (админы и не админы) для тестирования механизмов авторизации и аутентификации.

## Создание более реалистичных данных

Ранее в этой главе мы использовали `sequence` в фабрике `contacts` что бы быть атрибут `email` был уникален. Мы можем это улучшить предоставив более реалистичные данные нашему приложению, используя генератор "фейковых" данных **Faker**. 

- _Faker_ это Ruby порт к проверенной временем [Perl](https://www.youtube.com/watch?v=BXeNVjkfYOI) [библиотеке](https://metacpan.org/pod/Data::Faker) созданой для генерации фейковых имен, адресов, предложений, [и ещё бог знает чего](https://github.com/faker-ruby/faker#default)! Отлично подходит для тестирования!

Давайте добавим фейковых данных в нашу фабрику:

**spec/factories/contacts.rb**
```ruby
FactoryGirl.define do
  factory :contact do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    email { Faker::Internet.email }
  end
end
```

Отлично, теперь наши спеки будут использовать рандомные email адреса каждый раз когда будет использоватся фабрика с телефонами. После запуска тестов, в _log/test.log_ можно для себя посмотреть какие email'ы подставляются в базу данных для _contact_spec.rb_.


### спорный момент
Надо обратить внимание здеь на два важных момента:
- Первый: необходимо подключить `Faker` в первой строке моей фабрики 

- First, we’ve required the Faker library to load in the first line
of my factory

- Второй: мы передаем `Faker::Internet.email` в блок (`{}`) — Factory Girl будет воспринимать это как ["_lazy attribute_"](https://thoughtbot.com/blog/waiting-for-a-factory-bot#:~:text=Lazy%20attribute%20blocks%20are%20passed%20a%20proxy%20object%20that%20can%20be%20used%20to%0A%20%20%23%20generate%20associations%20lazily.%20The%20object%20generated%20will%20depend%20on%20which%0A%20%20%23%20build%20strategy%20you%27re%20using.%20For%20example%2C%20if%20you%20generate%20an%20unsaved%20post%2C%0A%20%20%23%20this%20will%20generate%20an%20unsaved%20user%20as%20well.)(противоположность статического) — будет добавлять атрибуты прописанные до вызова фабрики. То есть можно будет явно указывать их в спеках по необходимости.

- and second, that we pass the Faker::Internet.email method inside a
block–Factory Girl considers this a “lazy attribute” as opposed to the statically-added
string the factory previously had

Давайте вернемся к "телефонной фабрике" и поменяем дефолтный номер который мы указывали на случайный, реалистичный и уникальный:

**spec/factories/phones.rb**
```ruby
FactoryGirl.define do
  factory :phone do
    association :contact
    phone { Faker::PhoneNumber.phone_number }

  # child factories omitted ...
  end
end
```

Да конечно в этом нет сильной необходимости. Мы могли бы воспользоватся сиквенсами(`sequences`) и тесты бы проходили. Но Faker нам дает более реалистичные данные для тестирования(не говоря уже о том что фейкер генерит иногда очень смешные данные)

## :warning:
Есть и другие неплохие gem'ы для создания фейковыхданных:
- [forgery](https://github.com/sevenwire/forgery) — представляет тот же функционал что и Faker но с другим синтаксисом
- [ffaker](https://github.com/ffaker/ffaker) — переписаный Faker который работает в 20 раз быстрее оригинала

Эти гемы хороши не только для создания тестовых данных. [Вот например](https://everydayrails.com/2013/05/20/obfuscated-data-screenshots.html) в своем блоге автор книг показывает как можно использовать Faker для демонстрации клиентам и не светить реальные данные.

## Продвинутые асоциации

Тесты валидаций которые мы написали, по большей части, тестирвали относительно простые аспекты наших данных. Они не трбовали от нас смотреть ни на что кроме самих моделей — другими словами мы не проверяли что при создании контакта, создается еще 3 телефонных номера. Как нам протестировать это? И как нам сделать фабрику так что бы быть уверенными в реалистичности наших тестовых контактов?

Необходимо использовать коллбэки, всроенные в Factory Girl. Колбэки особенно важны для тестирования вложенных атрибутов, как в случае с нашим интерфейсом который позволяет юзеру вводить телефонные номера во время создания или редактирования контакта. Например следующая модификация будет использовать в нашей фабрике контактов колбек `after`, что бы точно при создании контакта фабрикой еще создавались по одному телефону каждого из трех типов:

**spec/factories/contacts.rb**
```ruby
FactoryGirl.define do
  factory :contact do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    email { Faker::Internet.email }

    after(:build) do |contact|
      [:home_phone, :work_phone, :mobile_phone].each do |phone|
        contact.phones << FactoryGirl.build(:phone,
          phone_type: phone,
          contact: contact
        )
      end
    end
  end
end
```

Отмеим что `after(:build)` это блок, в котором множество из трех типов телефона используется для создания _номеров_ телефона принадлежащих контакту. Мы можем убедится в этом запустив следующий тест:

**spec/models/contact_spec.rb**
```ruby
it "has three phone numbers" do
  expect(create(:contact).phones.count).to eq 3
end
```

Этот тест пройдет, и все остальные которые уже есть тоже пройдут. Изменение фабрики ничего не сломало в уже существующе работе(в данном случае, нефакт что в другом приложении не крешнется). Мы можем даже пойти дальше и добавить валидации в модель `Contact`:

**app/models/contact.rb**

```ruby
validates :phones, length: { is: 3 }
```

В качестве эксперимента попробуйте изменить значение этой валидаци на любую другую цифру. И сразу все тесты которые предпологают валидный контакт упадут. А еще попробуйте закоментировать `after` блок в телефонно фабрике и запустите тесты. Опять будет много красного.

:warning:
>Наш пример с использованием колбека очень спецефичен и отражает что у контакта есть три номера телефона. Но колбэки Factory Girl не ограничены только таким применением. Прочитайте [статью](https://thoughtbot.com/blog/get-your-callbacks-on-with-factory-bot-3-3) что бы получше ознакомится с возможностями этой фичи.

Этот пример может выглядеть надуманным, но он хорошо отражает ситуацию с которой вы рано или поздно сталкнетесь в реальном приложении. По факту, этот пример основан на системе которую автор однажды выстроил, на одной встрече созданной юзером должно быть двое приглашенных. Эта задача потребовала прилично времени потратить на копание в документации Factory Girl, коде и интернете в целом что бы заставить фабрики корректно работать с таким требованием. 

Мы использовали колбэк `after(:build)` - так эе мы можем использовать `before(:build)`, `before(:create)`, и `after(:create)`. Они работают примерно одинаково.

## Злоупотребление фабриками

Фабрики это круто, ровоно до тех пор, пока не получится наоборот)) Как и упоминалось в начале этой главы, некомпетентное использование фабрик может привести к сильному замедлению тестов, особенно в спешке, особенно в приложении со сложными ассоциациями. В нашем случае создание трех дополнительных обектов каждый раз при вызове нашей последней фабрики - но удобство вызова всех этих генераций за раз перевешивает вариант более быстрый но с большим количеством комманд.

Генерация ассоциаций на фабриках это простой способ наращивания тестов, и так же легко злоупотребить этой фичей. Очень часто фабрики становятся виновниками дико тормозяжих тестов. Когда такое случается, лучше избавится от ассоциаций на фабриках и создать тестовые данные руками. Так же можно вернутся к старым добрым руби обьектам, как мы делали это в 3 главе. Ну или гибридный подход комбинировать фабрики и обьекты.

Еслы вы просматривали другие ресурсы для тестирования в общем и RSpec в частности, вы обязателно должны были наткнутся на термины `stubs` и `mocks`. Если у вас есть уже какой то опыт в тестировании, вы наверняка смекнули почему автор использовал фабрики вместо [`stubs` и `mocks`](https://www.youtube.com/watch?v=oyMPzA-ZWkE). Исходя из опыта автора, базовые объекты и фабрики более быстро и комфортно начать тестировать. Чрезмерное использование макетов и заглушек может привести к созданию отдельного набора проблем...

Поговорим подробнее про макеты и заглушки в 9 и 19 главх.

## Заключение

Наш синтаксис стал более леговесным, у нас теперь есть достаточно гибкая вариативность создания тестовых данных, реалистичные данные для тестов, мы обладаем техникой создания сложных ассоциаций. Не забываем смотреть в документацию [Factory Girl](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md) там можно почерпнуть много интересного чего нету в книге.

Мы будем использовать Factory Girl на протяжении всей книги. Удобство которе предоставляют фабрики напрочь перевешивает медленность прохождения тестов. Фабрики будут играть значительную роль в следующе главе, когда мы будем тестировать контроллеры, которые как раз гоняют данные между моделями и вьюхами.
