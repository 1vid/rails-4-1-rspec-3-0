# 03. Model specs

У нас есть вcе инструменты для написания надежных тестов — самое время заставить их работать. Начнем с основных строительных блоков ядра нашего приложения - моделей!

В этой главе мы решим следующие задачи:
- Создадим `spec` существующей модели `Contact`
- Затем напишем тесты для модели: протестируем валидации, методы классa и инстанс методы. Структурируем наш `spec` файл.

## Анатомия `spec`'a модели

Научиться тестированию проще всего на уровне моделей, т.к. это позволяет исследовать и тестировать строительные блоки ядра приложения. Хорошо протестированный код на этом уровне это ключ — надежный фундамент это первый шаг к надежной кодовой базе в целом.

Для начала `spec` модели должен содержать следующее
- Метод модели `create` должен быть "валидным" после прохождения валидации атрибутов.
- Данные которые не соответствуют валидации не должны быть валидными
- Методы класса и экземпляра должны вести себя так как предполагается.

Давайте взглянем на базовую структуру `spec` файла для модели в контексте RSpec. Полезно взглянуть на эти строки сами по себе. Например вот требования к нашей модели `Contact`:

```ruby
describe Contact do
  it "is valid with a firstname, lastname and email"
  it "is invalid without a firstname"
  it "is invalid without a lastname"
  it "is invalid without an email address"
  it "is invalid with a duplicate email address"
  it "returns a contact's full name as a string"
end
```

Мы расширим этот план через несколько минут, но для начала это уже дает нам очень много. Это простой `spec`:
- **Наш план описывает набор ожиданий** — как должна выглядеть модель `Contact` и как она должна себя вести.
- **Каждый пример (строка начинающаяся с it) предполагает только одну вещь** — Отметим что у нас валидации `firstname`,`lastname` и `email` проверяются отдельно. Таким образом если если данные для теста будут не пройдут тест, не надо будет углубляться в отчет RSpec что бы понять где поломалось. Ну может и покопаться прийдеться, но не на глубину Марианской впадины. 
- **Каждый пример явный** — строка с описанием после `it` технически опциональная для RSpec. Но отсутствующее или непонятное описание затруднит чтение результатов теста.
- **Каждое описание начинается с глагола** Прочитайте предположения вслух: _Contact is invalid without a firstname_, _Contact is invalid without a lastname_, _Contact returns a contact’s full name as a string_. Читаемость это важно!

Держа в голове эти лучшие практики давайте напишем `contact_spec.rb`

## Создание `spec`'a модели

**spec/models/contact_spec.rb**
Открываем папку _spec_ и создаем папку _models_, если еще нет. И там создаем файл _contact_spec.rb_ :
```ruby
describe Contact do
  it "is valid with a firstname, lastname and email"
  it "is invalid without a firstname"
  it "is invalid without a lastname"
  it "is invalid without an email address"
  it "is invalid with a duplicate email address"
  it "returns a contact's full name as a string"
end
```

## :warning: :warning: :warning: Расположение :warning: :warning: :warning:

Название и путь к `spec` файлу очень важны! Структура тестов повторяет структуру `app` директории.
Например путь к модели `app/models/contat.rb` — путь к тесту модели `spec/models/contact_spec.rb`.
Это будет очень важно далее, когда мы начнем автоматизировать тесты. _Spec_'и и соответствующие файлу приложения будут обновляться и наоборот.

Перед тем как вникнуть в детали давайте попробуем запустить 
```ruby
bin/rspec
```
или
```ruby
rspec
```

Консоль на выведет следующее:
```
Contact
  is valid with a firstname, lastname and email
    (PENDING: Not yet implemented)
  is invalid without a firstname
    (PENDING: Not yet implemented)
  is invalid without a lastname
    (PENDING: Not yet implemented)
  is invalid without an email address
    (PENDING: Not yet implemented)
  is invalid with a duplicate email address
    (PENDING: Not yet implemented)
  returns a contact's full name as a string
    (PENDING: Not yet implemented)

Pending:
  Contact is valid with a firstname, lastname
    and email
    # Not yet implemented
    # ./spec/models/contact_spec.rb:4
  Contact is invalid without a firstname
    # Not yet implemented
    # ./spec/models/contact_spec.rb:5
  Contact is invalid without a lastname
    # Not yet implemented
    # ./spec/models/contact_spec.rb:6
  Contact is invalid without an email address
    # Not yet implemented
    # ./spec/models/contact_spec.rb:7
  Contact is invalid with a duplicate email address
    # Not yet implemented
    # ./spec/models/contact_spec.rb:8
  Contact returns a contact's full name as a string
    # Not yet implemented
    # ./spec/models/contact_spec.rb:9

Finished in 0.00105 seconds (files took 2.42 seconds to load)
6 examples, 0 failures, 6 pending
```

В древних версиях до 2.11 старый синтаксис.
|old|new|
|---|---|
|should|to|
|should_not| not_to|

old
```ruby
it "adds 2 and 1 to make 3" do
  (2 + 1).should eq 3
end
```

new
```ruby
it "adds 2 and 1 to make 3" do
  expect(2 + 1).to eq 3
end
```
RSpec 3 поддерживает и старый синтаксис, но если его использовать, будут появляться предупреждения(их можно отключить). Но все таки лучше пользоваться синтаксисом `expect(...)`

Итак посмотрим как же выглядит синтаксис на практике, давайте заполним первое предположение из `spec`'a нашей модели `Contact`:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'

describe Contact do
  it "is valid with a firstname, lastname and email" do
    contact = Contact.new(
    firstname: 'Aaron',
    lastname: 'Sumner',
    email: 'tester@example.com')
    expect(contact).to be_valid
  end

 # remaining examples to come
end
```

В этом примере используется простой матчер `be_valid`. Он проверяет знает ли наша модель как надо выглядеть что бы прошли валидации. Мы создали объект(новый-но не сохраненный экземпляр `contact` класса `Contact`), затем передали его методу `expect` для сравнения с матчером.

Теперь если мы запустим `rspec`, увидим один пройденный тест. Мы на верном пути. Погнали тестит больше нашего кода!

## Тестирование валидаций

Валидации это отличная штука, что бы ворватся в автоматизированное тестирование. Обычно эти тесты могут быть написаны в одну или две строки кода. Особенно когда мы начнем использовать для удобства фабрики(в следующе главе). Взглянем на `spec` валидации `firstname`:

```ruby
it "is invalid without a firstname" do
  contact = Contact.new(firstname: nil)
  contact.valid?
  expect(contact.errors[:firstname]).to include("can't be blank")
end
```

В этот раз мы предположим что новый `contact` не будет валидным. Мы явно указываем значение атрибута `firstname` равное `nil`. При создание экземпляра с таким значением параметра `firstname` мы должны увидеть специфическую для него ошибку. Для проверки такой ошибки мы используем матчер `include` — он проверяет есть явно нами заданное значение среди перечисленных в `expect`. Опять запускаем RSpec и у нас уже два пройденных теста!

Что бы проверить все ли работает как мы предполагаем, давайте заменим `to` на `not_to`:

```ruby
it "is invalid without a firstname" do
  contact = Contact.new(firstname: nil)
  contact.valid?
  expect(contact.errors[:firstname]).not_to include("can't be blank")
end
```

И конечно Rspec скажет нам что тест упал:

```ruby
Failures:
  1) Contact is invalid without a firstname
    Failure/Error: expect(contact.errors[:firstname]).not_to
        include("can't be blank")
      expected ["can't be blank"] not to include "can't be blank"
    # ./spec/models/contact_spec.rb:15:in `block (2 levels) in
      <top (required)>
```
Операторы `to_not` и `not_to` эквивалентны.

Это простой способ проверить корректность работы тестов. Главное не забыть потом поменять обратно `not_to` на `to`.

Используем такой же подход для тестирования валидации атрибута `:lastname` :

**spec/models/contact_spec.rb**
```ruby
it "is invalid without a lastname" do
  contact = Contact.new(lastname: nil)
  contact.valid?
  expect(contact.errors[:lastname]).to include("can't be blank")
end
```

Вы можете подумать что эти тесты относительно бессмысленны. Как понять все ли нужные валидации прописаны в модели? Суть в том что вы можете их и пропустить. Но очень важно что бы вы понимали и думали о том какие валидации _должны_ быть в модели когда вы пишете тесты. И тогда благодаря тестам вы уж точно их не пропустите.

Протестируем уникальность атрибута `:email` :

**spec/models/contact_spec.rb**
```ruby
it "is invalid with a duplicate email address" do
  Contact.create(
    firstname: 'Joe', lastname: 'Tester',
    email: 'tester@example.com'
  )
  contact = Contact.new(
    firstname: 'Jane', lastname: 'Tester',
    email: 'tester@example.com'
  )
  contact.valid?
  expect(contact.errors[:email]).to include("has already been taken")
end
```
Обратим внимание на один важный нюанс: Мы сохранили в тестовую БД первый валидный экземпляр класса `Contact` методом `create` (`new` + `save`). А второй экземпляр, который мы будем проверять, записали в переменную `contact`. Второй экземпляр уже будет провряться опираясь на запись в БД, то есть на первый экземпляр сохраненный туда.

Давайте теперь проверим более комплексные валидации. 
- Мы не хотим что бы у одного юзера дублировались номера
- У двух юзеров номера могут дублироваться 

Как нам это реализовать в тесте?

Переходим в спек модели `Phone` и увидим пример:

**spec/models/phone_spec.rb**
```ruby
require 'rails_helper'

describe Phone do
  it "does not allow duplicate phone numbers per contact" do
    contact = Contact.create(
      firstname: 'Joe',
      lastname: 'Tester',
      email: 'joetester@example.com'
    )
    contact.phones.create(
      phone_type: 'home',
      phone: '785-555-1234'
    )
    mobile_phone = contact.phones.build(
      phone_type: 'mobile',
      phone: '785-555-1234'
    )

    mobile_phone.valid?
    expect(mobile_phone.errors[:phone]).to include('has already been taken')
  end

  it "allows two contacts to share a phone number" do
    contact = Contact.create(
      firstname: 'Joe',
      lastname: 'Tester',
      email: 'joetester@example.com'
    )
    contact.phones.create(
      phone_type: 'home',
      phone: '785-555-1234'
    )
    other_contact = Contact.new
    other_phone = other_contact.phones.build(
      phone_type: 'home',
      phone: '785-555-1234'
    )

    expect(other_phone).to be_valid
  end
end
```

Модели `Contact` и `Phone` связаны через _Active Record_. В первом случае у нас два номера присвоены одному контакту. Во втором один и тот же номер присвоен двум разным контактам. В обоих случаях нам необходимо создать первый контакт методом `create` т.е. сохранить его в БД для сравнения его с другим контактом который мы будем тестировать.

И с тех пор как у нас появляется вот такая валидация у модели `Phone`:

**app/models/phone.rb**
```ruby
validates :phone, uniqueness: { scope: :contact_id }
```

Тест будет проходить без проблем

Конечно валидации могут быть намного более сложными чем проверка уникальности при помощи [scope](https://guides.rubyonrails.org/active_record_validations.html#uniqueness). Вы можете использовать ложную [регулярку](https://regex101.com/) или какой кастомный валидатор. Надо взять за привычку тестировать валидации. И не только валидные данные, но те которые вызовут ошибку! Например как в упражнении которое мы не так давно делали, передавали параметр `nil` атрибуту экземпляра и пытались его инициализировать.

## Тестирование методов экземпляра класса

Это было бы удобно обратиться к `@contact.name` что бы отрендерить полное имя нашего контакта, вместо того чтобы каждый раз объединять имя и фамилию в новую строку. Для этого у нас есть метод экземпляра класса `Contact`:

**app/models/contact.rb**
```ruby
def name
  [firstname, lastname].join(' ')
end
```

Мы можем использовать такую же базовую технику, которую использовали для тестирования валидаций, для создания примера проходящего тест этой фичи:

**spec/models/contact_spec.rb**
```ruby
it "returns a contact's full name as a string" do
  contact = Contact.new(firstname: 'John', lastname: 'Doe',
    email: 'johndoe@example.com')
  expect(contact.name).to eq 'John Doe'
end
```

- `eq` или `eql` обозначают в RSpec предположение равенства
- `==` не используется и не работает

## Тестирование методрв класса и скоупов

Теперь давайте проверим способность модели `Contact` возвращать нам список контактов чьи имена начинаются с заданной буквы. Например если нажать _S_ то должны получить _Smith_, _Sumner_ и так далее, но не _Jones_. Есть несколько вариантов осуществить это, но в целях демонстрации мы рассмотрим только один.

Модель включает в себя этот функционал при помощи метода:

**app/models/contact.rb**
```ruby
def self.by_letter(letter)
  where("lastname LIKE ?", "#{letter}%").order(:lastname)
end
```

Что бы протестировать это, добавим следующее к нашей модели `Contact`:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'

describe Contact do

  # earlier validation examples omitted ...

  it "returns a sorted array of results that match" do
    smith = Contact.create(
      firstname: 'John',
      lastname: 'Smith',
      email: 'jsmith@example.com'
    )
    jones = Contact.create(
      firstname: 'Tim',
      lastname: 'Jones',
      email: 'tjones@example.com'
    )
    johnson = Contact.create(
      firstname: 'John',
      lastname: 'Johnson',
      email: 'jjohnson@example.com'
    )
    expect(Contact.by_letter("J")).to eq [johnson, jones]
  end
end
```

Отметим, мы сортируем запрос и порядок сортировки. `jones` будет извлечен первым из базы данных. Но мы указываем в методе сортировку по фамилии и поэтому `johnson` будет первым в результате сортировки.

## Тестирование сценария с отсутствующими данными в БД

Мы протестировали позитивный сценарий — юзер сделал запрос для которого в БД есть результат — но что делать в случае когда по выбранной букве нет результатов? Хорошо бы нам это тоже протестить. Следующий спек способен это сделать:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'

describe Contact do

  # validation examples ...

  it "omits results that do not match" do
    smith = Contact.create(
      firstname: 'John',
      lastname: 'Smith',
      email: 'jsmith@example.com'
    )
    jones = Contact.create(
      firstname: 'Tim',
      lastname: 'Jones',
      email: 'tjones@example.com'
    )
    johnson = Contact.create(
      firstname: 'John',
      lastname: 'Johnson',
      email: 'jjohnson@example.com'
    )
    expect(Contact.by_letter("J")).not_to include smith
  end
end
```
Этот спек использует метод `include` что бы определить, что неподходящий условиям запроса результат `smith` не входит в массив ` expect(Contact.by_letter("J"))`. Таким образом мы протестировали не только запрос в БД для которого есть результат, но и сценарий в котором по запросу данных нету.

> Это спорный момент надо бы обратить на него внимание. То есть мы могли бы протестировать запрос по другой букве "expect(Contact.by_letter("X")).to eq []" и тест бы прошел но в примере мы еще и протестировали не попадает ли в запрос данные не соответствующие запросу.

## Про матчеры

Мы уже посмотрели в действии 3 матчера.
- `be_valid` – для проверки валидаций модели
- `eq`— эквивалентность значений при сравнении
- `include`— включает ли в себя часть `expect` данные которые мы напишем после матчера

Все три матчера нам предоставляет гем `rails-rspec` после установки в приложение. 

Полный список матчеров RSpec можно глянуть в официальном [README.md](https://github.com/rspec/rspec-expectations#rspec-expectations--)

В главе 7 мы рассмотрим создание собственных кастомных матчеров :sunglasses:

## Не повторяемся при помощи  _describe_, _context_, _before_ and _after_

Если вы внимательно посмотрели на код в этой ветке, вы точно должны были заметить неоответствие между выше приведенными примерами и тем что есть в коде приложения. Там автор использует еще одну фичу RSpec : `before` [hook](https://ru.wikipedia.org/wiki/%D0%9F%D0%B5%D1%80%D0%B5%D1%85%D0%B2%D0%B0%D1%82_(%D0%BF%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5)) для упрощения кода спека и чтоб писать поменьше)

Примеры спеков приведенных выше были неоправданно раздуты. Мы создали три одинаковых объекта в каждом примере, это зашквар бро. Так же как и в коде приложения, в тестах  надо придерживаться [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) принципа (конечно есть исключения, поговорим об этом скоро). Давайте используем "фишки" RSpec что бы сделать наши тесты посимпатичнее. 

Создадим `describe` блок внутри `describe Contact` для фичи с фильтром. В общих чертах это будет выглядеть вот так:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'
 
describe Contact do
 
  # validation examples ...
 
  describe "filter last name by letter" do
    # filtering examples ...
  end
end
```

Давайте внесем блоки `context` для двух сценариев: есть совпадение в базе по запросу и нету совпадения:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'
 
describe Contact do
 
  # validation examples ...
 
  describe "filter last name by letter" do
    context "matching letters" do
      # matching examples ...
    end

    context "non-matching letters" do
      # non-matching examples ...
    end
  end
end
```

>`describe` и `context` взаимозаменяемы, но лучше их использовать как в примере выше, для описания конкретных блоков. `describe` для описания основного функционала класса, а `context` для специфических состояний этого функционала. В нашем случае в блоке `describe` описание функциона фичи с фильтром, и 2 блока `context` когда совпадение есть и когда его нет.

Мы сделали описание спека и структурировали его так что бы он мог работать с одинаковыми примерами и был более читаемым. Завершим "причесывание" нашего спека при помощи хука `before`:

**spec/models/contact_spec.rb**
```ruby
require 'rails_helper'
 
describe Contact do
 
  # validation examples ...
 
  describe "filter last name by letter" do
    before :each do
      @smith = Contact.create(
        firstname: 'John',
        lastname: 'Smith',
        email: 'jsmith@example.com'
      )
      @jones = Contact.create(
        firstname: 'Tim',
        lastname: 'Jones',
        email: 'tjones@example.com'
      )
      @johnson = Contact.create(
          firstname: 'John',
          lastname: 'Johnson',
          email: 'jjohnson@example.com'
      )
    end

    context "matching letters" do
      # matching examples ...
    end

    context "non-matching letters" do
      # non-matching examples ...
    end
  end
end
```

Хук `before` запускается перед **каждым** примером внутри блока `describe`. И за пределами блока переменные `@smith` `@jones` и `@johnson` не доступны. `before` можно использовать без `:each`, этот хук по дефолту будет запускаться перед каждым примером, но для ясности в конспекте будем использовать его вместе с `:each`.

Если в спеке требуется очистить базу данных после создания примера — имитация отключения внешних сервисов например — мы можем использовать хук `after`для очистки БД после примера. С тех пор как RSpec автоматически подчищает БД, редко приходится использовать `after`. А вот `before` это и незаменимая штука.

Давайте посмотрим на полностью организованный код:

**spec/models/contact_spec.rb** 
```ruby
require 'rails_helper'

describe Contact do
  it "is valid with a firstname, lastname and email" do
    contact = Contact.new(
      firstname: 'Aaron',
      lastname: 'Sumner',
      email: 'tester@example.com')
    expect(contact).to be_valid
  end

  it "is invalid without a firstname" do
    contact = Contact.new(firstname: nil)
    contact.valid?
    expect(contact.errors[:firstname]).to include("can't be blank")
  end

  it "is invalid without a lastname" do
    contact = Contact.new(lastname: nil)
    contact.valid?
    expect(contact.errors[:lastname]).to include("can't be blank")
  end

  it "is invalid without an email address" do
    contact = Contact.new(email: nil)
    contact.valid?
    expect(contact.errors[:email]).to include("can't be blank")
  end

  it "is invalid with a duplicate email address" do
    Contact.create(
      firstname: 'Joe', lastname: 'Tester',
      email: 'tester@example.com'
    )
    contact = Contact.new(
      firstname: 'Jane', lastname: 'Tester',
      email: 'tester@example.com'
    )
    contact.valid?
    expect(contact.errors[:email]).to include("has already been taken")
  end

  it "returns a contact's full name as a string" do
    contact = Contact.new(
      firstname: 'John',
      lastname: 'Doe',
      email: 'johndoe@example.com'
    )
    expect(contact.name).to eq 'John Doe'
  end

  describe "filter last name by letter" do
    before :each do
      @smith = Contact.create(
        firstname: 'John',
        lastname: 'Smith',
        email: 'jsmith@example.com'
      )
      @jones = Contact.create(
        firstname: 'Tim',
        lastname: 'Jones',
        email: 'tjones@example.com'
      )
      @johnson = Contact.create(
        firstname: 'John',
        lastname: 'Johnson',
        email: 'jjohnson@example.com'
      )
    end

    context "with matching letters" do
      it "returns a sorted array of results that match" do
        expect(Contact.by_letter("J")).to eq [@johnson, @jones]
      end
    end

    context "with non-matching letters" do
      it "omits results that do not match" do
        expect(Contact.by_letter("J")).not_to include @smith
      end
    end
  end
end

```

Если запустим наши тесты увидим читаемые результаты (благодаря тому что мы указали фомат документации в главе 2 `--documentation format`):

```
Contact
  is valid with a firstname, lastname and email
  is invalid without a firstname
  is invalid without a lastname
  is invalid without an email address
  is invalid with a duplicate email address
  returns a contact's full name as a string
  filter last name by letter
    with matching letters
      returns a sorted array of results that match
    with non-matching letters
      omits results that do not match

Phone
  does not allow duplicate phone numbers per contact
  allows two contacts to share a phone number

Finished in 0.75429 seconds (files took 5.72 seconds to load)
10 examples, 0 failures
```

>Некоторые разрабы используют названия методов для блоков `describe`/. В нашем случае это выглядело бы как `#by_letter` вместо `filter last name by letter`. По мнению автора такой не информативен и не передает поведение кода. Но строгих рамок и рекомендаций на этот счет нету.

## DRY и здравый смысл

Мы потратили много времени в этой главе на организацию спеков в легко понятные блоки. Ключем к этому был хук `before`, но так же не стоит им злоупотреблять.

Когда мы создаем примеры и условия для наших тестов это норм использовать принцип "не повторятся" в интересах читабельности. Но если ты обнаружишь себя в скролинге длиннющего спека в попытках понять что же тут тестируется, допускается дублирование тестовых данных в более маленьких `describe` блоках или даже в самих примерах.

Не менее важно давать говорящие названия нашим переменным. Напримр мы использовали `@james` и `@jones` при тестировании контакта. Это на много понятнее чем `@user1` и `@user2`, для теста функционала по фильтрации контактов по первой букве. Так же понятными будут `@admin_user` и `@guest_user` когда мы будем тестировать специфические роли пользователей в главе 6. Будьте выразительными в придумывании переменных!

## Вывод

В этой главе мы сконцентрировали свое внимание на тестировании моделей, но так же мы изучили несколько важных техник которые будут использованы в других спеках:

-**Используйте ясные предположения**: используйте глаголы для описания результатов примера. Проверяйте только один результат для примера.

-**Тестируйте то что должно произойти и то что произойти не должно**: думайте в обоих направлениях при написании примеров.

-**Тестируйте крайние случаи**: Если у вас есть валидации для пароля от 4 до 10 символов. Не стоит тестировать только случай когда у вас пароль 8 символов. Хороший набор тестов должен включать в себя случаи когда длинна пароля 4 и 10, так же как и 3 и 11. Так же для у вас появится пища для ума например какого черта у вас вообще такие короткие пароли допустимы в приложении. Написание тестов это вообще хороший способ рефлексировать над требованиями к приложению и вашим кодом.

- **Ваши тесты должны быть легко читаемы**: Используйте `describe` и `context` для сортировки похожих примеров. Используйте блоки `before` и `after` что бы избегать дублирования кода, но не забывать про удобство чтения. Соблюдайте баланс.

## Упражнения
Полезны для закрепления материал и более глубокого знакомства с функционалом RSpec.

- Не стесняйтесь комментировать куски кода который вы тестируете что бы убедится что все работает корректно. Например строчку `validates :firstname, presence: true`, запустите тест и увидите что it `is invalid without a firstname` упадет. Раскомментируйте и снова запустите тесты.

- Так же не бойтесь менять значения данных которые вы тестируете. Изменим `it "is invalid without a firstname`— зададим значение отличное от `nil` атрибуту `:firstname`. Тест упадет, вернем обратно и снова все заработает.
