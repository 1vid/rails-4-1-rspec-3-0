# 05. Базовые тесты контроллеров

"Бедные" контроллеры. Мы как нормальные Рейлс разработчики, длжны держать контроллеры худыми(это правильно), и часто мы не уделяем им внимания в наших тестах(что может быть ооочень плохо). В процессе улучшения покрытия тестами нашего текущего приложения, следующей частью приложения за которую стоит взятся это контроллеры.

Частично тестирование контроллеров зависит от нескольких факторов: напримар какая конфигурация отношений моделей, какой набор раутов у вас в приложении. Рассмотрим в этой главе некоторые из них, и стоит раз это сделать, у вас появится ясное понимание как написать спек контроллера в вших приложениях.

Что мы рассмотрим в этой главе:

- Первым делом мы обсудим почему вообще мы должны тестировать контроллеры
- Мы будем идти по очень базовым вещам (на уровне юнит тестов)
- Затем мы схематично организуем тесты контроллеров
- Используем фабрики для заполнения тестов данными
- Затем мы протестим 7 [CRUD](https://ru.wikipedia.org/wiki/CRUD) методов, которые используются вместе с не-CRUD методами
- Посмотрим как тестировать "рауты"
- Мы покроем тестами методы контроллера которые возвращают не _HTML_ ответ, а _JSON_ и _CSV_.

Для этих упражнений нам будет необходимо внести небольшу модификацию в `contacts_controller.rb`. Для того что бы сфокусировать внимание на базовых тестах контроллера, давайте будем обоходить слой аутентификации на протяжении все главы. Самы быстрый способ это сделать — просто закомментировать:

app/controllers/contacts_controller.rb
```ruby
class ContactsController < ApplicationController
  # before_action :authenticate, except: [:index, :show]
  before_action :set_contact, only: [:show, :edit, :update, :destroy]

  # etc
```

## Зачем тестировать контроллеры?

Есть несколько хороших причин для явного тестирования методов ваших контроллеров:

- **Контроллеры это классы с методами**.(автор ссылается на Петра Солнца ссылка устарела). В Рейлс приложениях эти классы очень важны (а так же их методы). Так что это не плохая идея протестировать их так же как и модели.

- **Написание тестов контроллеров намного быстрее чем их [интеграционные](https://ru.wikipedia.org/wiki/%D0%98%D0%BD%D1%82%D0%B5%D0%B3%D1%80%D0%B0%D1%86%D0%B8%D0%BE%D0%BD%D0%BD%D0%BE%D0%B5_%D1%82%D0%B5%D1%81%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5) аналоги**. Для автора это стало критично когда он сталкивался с багом на уровне контроллера, или была необходимость добавить спек в результате небольшого рефакторинга. Написать надежный тест контроллера это сравнительно простой процесс. С тех пор как у меня появились очень специфические аргументы(входящие данные, запросы) для методов я начал писать тесты в обход тестов фих в целом. 
- **Спеки контроллеров работаю быстрее чем интеграционные тесты.** Написание их очень полезно при исправлении багов и проверке нежелательных(или желательных) путей которые может ввести пользователь.

## Почему контроллеры не тестировать?

Так почему же мы не видим повсеместного использования тестов контроллеров в опенсорсных проектах?

- **Контроллеры должны быть тощими**. — настолько тощими, что некоторые предпологаю что тестирование контроллеров беспочвенно.
- **Тесты контроллеров быстрее чем тесты фич. Но медленнее тестов моделей и простых Ruby объектов** Эта разница немного сгладится в главе 9 где мы будем разбирать как ускорять спеки. Но это все равно важный аргумент против.
- **Один тест на фичу способен заменить несколько тестов контроллера** — наверное проще написать и поддерживать один тест чем несколько.

Если подитожить то ответ находится где то по середине. В ранних версиях книги автор постоянно описывал непрекращающуюся внутреннюю борьбу по этому поводу. Когда он изучал RSpec и TDD, тесты контроллеров у автора в сознании подразумевались как интеграционные и по инструментам и по процессам. Это как раз и является причино по которой он решил заострить внимание на этой теме. Это отличная возможность попрактиковать многие фичи RSpec которые мы обычно не используем(они не типичны) для тестов моделей и фич. Так же они хороши для тестирования ньюансов контроллеров избегая интеграционных тестов.

## Основы тестирования контроллеров

*Scaffold'ы* , когда они настроенны корректно, это отличный способ для освоения техник кодинга. Спек файлы генерируются для контроллеров, как минимум с версии RSpec 2.8, оно довольно хороши и создают неплохой шаблон для создания собственных спеков. Взгляните на *scaffold* генератор в репозитории [rspec-rails](https://github.com/rspec/rspec-rails/blob/3-1-maintenance/lib/generators/rspec/scaffold/scaffold_generator.rb) или сгенерите *scaffold* в вашем правильно настроенном для RSpec Rails приложении, что бы начинать понимать эти тесты.

Каждый спек контроллеров разбивается по его методам — каждый пример основан на одном действии и опционально любые переданные му параметры. Вот пример:

```ruby
it "redirects to the home page upon save" do
  post :create, contact: FactoryGirl.attributes_for(:contact)
  expect(response).to redirect_to root_url
end
```

**_ремарка_** Как грепать рауты:
- `rake routes | grep ressource_name` — поиск по имени ресурса(_ressource_name_ - любое слово для запроса). Если оно содержится в раутах то выведется в консоли.
- В версии выше пятой доступны и другие [грепы](https://www.bigbinary.com/blog/rails-5-options-for-rake-routes)

Вы можете найти сходства в тестах которые мы писали ранее:

- Описание каждого теста явное, читаемое, понятное.
- 1 тест — 1 предположение: после обработки пост запроса, редирект должен направить в браузер.
- Тестовые данные сгенерированные фабрикой должны подходить для методв контроллера. Обратите внимание что метод `attribute_for` предоставляемый модулем [FactoryBot::Syntax::Methods](https://www.rubydoc.info/gems/factory_bot/FactoryBot/Syntax/Methods), генерирует `Hash` значений, а не Ruby объект. Конечно мы можем создать старый добрый хэш без вызова дополнительных связей, но для удобства мы будем использовать Factory Girl.

Есть пара новинок на которые стоит взглянуть:

- _Базовый синтаксис спеков контроллера_ — HTTP метод (`post`), метод контроллера (`:create`) и опционально параметры(аргументы, атрибуты) которые передаются в метод. Этот функционал обеспечивает [Rack::Test gem](https://github.com/rack/rack-test), так же он будет полезен в будущем когда мы будем тестироват API'хи.

- _Вышеупомянутый `attributes_for` вызываемый Factory Girl_ — это не ["рокет сайнс"](https://en.wikipedia.org/wiki/Rocket_science). Стоит упомянуть что автор ранее чаще использовал дефолтные фабрики, а не эту фичу. Как напоминание: `attributes_for()` создает хэш с атрибутами, а не объект.

## Организация

Для начала используем подход "сверху-вниз". Как упоминалось ранее, будет полезно посмотреть на спек модели, с точки зрения наброска(схемы) тех вещей которые мы хотим что бы делал _Ruby_ класс. Мы начнем со спека для нашего контроллера контактов(_не забывайте, мы пока игнорим авторизацию_):

**spec/controllers/contacts_controller_spec.rb**
```ruby
require 'rails_helper'

describe ContactsController do

  describe 'GET #index' do
    context 'with params[:letter]' do
      it "populates an array of contacts starting with the letter"
      it "renders the :index template"
    end

    context 'without params[:letter]' do
      it "populates an array of all contacts"
      it "renders the :index template"
    end
  end

  describe 'GET #show' do
    it "assigns the requested contact to @contact"
    it "renders the :show template"
  end

  describe 'GET #new' do
    it "assigns a new Contact to @contact"
    it "renders the :new template"
  end

  describe 'GET #edit' do
    it "assigns the requested contact to @contact"
    it "renders the :edit template"
  end

  describe 'POST #create' do
    context "with valid attributes" do
      it "saves the new contact in the database"
      it "redirects to contacts#show"
    end

     context "with invalid attributes" do
      it "does not save the new contact in the database"
      it "re-renders the :new template"
    end

  describe 'PATCH #update' do
    context "with valid attributes" do
      it "updates the contact in the database"
      it "redirects to the contact"
    end

    context "with invalid attributes" do
      it "does not update the contact"
      it "re-renders the :edit template"
    end
  end

  describe 'DELETE #destroy' do
    it "deletes the contact from the database"
    it "redirects to users#index"
  end
end
```

Так же как в спеках моделей мы можем использовать `context` и `describe` для организации предположений(примеров, тестов) по иерархии, основанной на экшенах(методах) контроллера. Контекст который мы тестируем в нашем случае:

- удачный путь — метод получает валидные атрибуты для контроллера
- неудачный путь — метод получает не валидные или не полные атрибуты

## Настройка тестовых данных

Так же как и спекам моделей, спекам контроллеров нужны данные. Здесь снова мы используем фабрики что бы начать — как только вы освоитесь, вы сможете воспользоватся другим более эффективным созданием тестовых данных. Но сей час для наших целей (и для нашего неболього приложения) фабрики будут работать отлично.

Это фабрика которую мы уже создали для кнтакта. Давай отнаследуем от нее не валидный контакт:

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

    factory :invalid_contact do
      firstname nil
    end
  end
end
```

Помните как мы использовали наследование что бы создать `:home_phone`,`:office_phone`, и `:mobile_phone` от родительской фабрики `:phone`? Мы можем использовать такую же технику для создания `:invalid_contact`(невалидного контакта) отнаследуясь от основной фабрики `:contact`. Такая техника просто заменяет атрибуты (в этом примере атрибут `firstame`) на явно прописанные в дочерней. Все остальное будет использовано из родительской фабрики `:contact`.

## Тестирование GET запросов

Стандартный Rails контроллер основанный на принципе [CRUD](https://ru.wikipedia.org/wiki/CRUD) включает в себя 4 метода реализующих GET запрос: _index_, _show_, _new_, и _edit_. В целом эти методы тестировать проще всего. Давай начнем с _show_:

spec/controllers/contacts_controller_spec.rb
```ruby
describe 'GET #show' do
  it "assigns the requested contact to @contact" do
    contact = create(:contact)
    get :show, id: contact
    expect(assigns(:contact)).to eq contact
  end

  it "renders the :show template" do
    contact = create(:contact)
    get :show, id: contact
    expect( ).to render_template :show
  end
end
```

Давайте разбиратся. Мы проверяем здесь две вещи:

- Метод контроллера находит сохраненный в БД объект и правильно назначает его в конкретную переменную. Что бы проверить это мы используем приемущество использования метода `assigns()`. Он проверяет что значение записанное в инстанс переменную `@contact` именно такое, какое мы предпологаем.

- Второе предположение говорит само за себя. Спасибо хорошо читаемому синтаксису RSpec. Ответ на обработанный запрос который нам возвращает метод контроллера запускает цепную реакцию, благодаря которой в браузере рендерится шаблон `show.html.erb`.

Эти два предположения дают нам ключ к пониманию концепции тестирования контроллеров:

- Базовые команды специфические для RSpec(в книге [DSL](http://sewiki.ru/DSL)) взаимодействующие с методами контроллера: Каждый спецефический HTTP запрос(GET, PUT, PATCH, DELETE, UPDATE) имеет свой аналог в RSpec(get, put, patch, delete, update) и предпологает какой то метод из контроллера переданный в виде ключа( в этом примере `:show`), за которым могут следовать любые дополнительные параметры(`id: contact`) 

- Переменные созданные при помощи контроллера могут быть проверенны(оценены) используя `assigns(:variable_name)`

- Финальный результат работы метода контроллера может быть оценён при помощи `response`

Теперь давайте посмотрим на метод `index` он немного сложнее:

**spec/controllers/contacts_controller_spec.rb**
```ruby
describe 'GET #index' do
  context 'with params[:letter]' do
    it "populates an array of contacts starting with the letter" do
      smith = create(:contact, lastname: 'Smith')
      jones = create(:contact, lastname: 'Jones')
      get :index, letter: 'S'
      expect(assigns(:contacts)).to match_array([smith])
    end

    it "renders the :index template" do
      get :index, letter: 'S'
      expect(response).to render_template :index
    end
  end

  context 'without params[:letter]' do
    it "populates an array of all contacts" do
      smith = create(:contact, lastname: 'Smith')
      jones = create(:contact, lastname: 'Jones')
      get :index
      expect(assigns(:contacts)).to match_array([smith, jones])
    end

    it "renders the :index template" do
      get :index
      expect(response).to render_template :index
    end
  end
end
```

**Ну давайте разбиратся что же здесь написано. Начнём с первого контекста. Здесь мы проверяем две вещи:**

- Массив контактов, соответствующий поиску по первой букве, создан и присвоен инстанс переменной `@contacts`. Снова мы используем метод `assigns()`, мы проверяем соответствует ли коллекция(присвоенная переменой `@conacts`) нашим ожиданиям используя RSpec'овский матчер `match_array`. В данном случае он ищет массив с одним объектом `smith` созданным в примере. А `jones` в этом массиве появится не должен. 

- Второй пример проверяет что рендерится `index.html.erb`, для этой проверки используется `response`. 

:warning:
_Матчер `match_array` ищет и сравненивает только содержимое массива, не учитывая порядок элементов. Если порядок имеет значение, необходимо использовать матчер `eq`._

**Во втором контексте используются те же базовые конструкции. Основное отличие заключается в том что в запросе мы не передаем параметр(букву, `letter`) в запрос.** Как результат, в первом предположении оба сгенерированных контакта попадут в резултат(переменную `@contacts`). Пока что это репетиция, мы изучаем синтаксис. В скором времени мы здесь приберемся. Но пока все важно выполнять именно так.

Нам осталось добавить _new_ и _edit_ "GET" методы:

**spec/controllers/contacts_controller_spec.rb**
```ruby
  describe 'GET #new' do
    it "assigns a new Contact to @contact" do
      get :new
      expect(assigns(:contact)).to be_a_new(Contact)
    end

    it "renders the :new template" do
      get :new
      expect(response).to render_template :new
    end
  end

  describe 'GET #edit' do
    it "assigns the requested contact to @contact" do
      contact = create(:contact)
      get :edit, id: contact
      expect(assigns(:contact)).to eq contact
    end

    it "renders the :edit template" do
      contact = create(:contact)
      get :edit, id: contact
      expect(response).to render_template :edit
    end
  end
```

Взгляните на это пример. Если понять как тестировать один типичный "GET" метод, вы сможете тестировать большинство из них используя набор стандартных конвенциональных техник(_conventions_). :surfer:

## Тестирование POST запросов

Самое время перейти к методу контроллера _create_, он реализует POST-запрос в нашем [RESTful](https://habr.com/ru/company/hexlet/blog/274675/) приложении. Главное(ключевое) отличие от GET методов: 

- Вместо `:id` который мы передавали в "GET-метод", нам необходимо передавать в "POST-метод" эквивалент `params[:contact]`(содержание формы в которой юзер указывает информацию для нового контакта). Как упоминалось ранее, мы будем использовать `attributes_for()` для этого, создавая ХЭШ содержащий атрибуты контакта и передавая их в контроллер. Вот базовый подход:

```ruby
it "does something upon post#create" do
  post :create, contact: attributes_for(:contact)
end
```

Держа это в голове, посмотрим на пару примеров тестирования методов ниже, сначала с валидными атрибутами:

**spec/controllers/contacts_controller_spec.rb**
```ruby
describe "POST #create" do
  before :each do
    @phones = [
      attributes_for(:phone),
      attributes_for(:phone),
      attributes_for(:phone)
    ]
  end

  context "with valid attributes" do
    it "saves the new contact in the database" do
      expect{
        post :create, contact: attributes_for(:contact,
          phones_attributes: @phones)
      }.to change(Contact, :count).by(1)
    end

    it "redirects to contacts#show" do
      post :create, contact: attributes_for(:contact,
        phones_attributes: @phones)
      expect(response).to redirect_to contact_path(assigns[:contact])
    end
  end
```

И закроем этот блок примерами с не валидными атрибутами:

**spec/controllers/contacts_controller_spec.rb**
```ruby
  context "with invalid attributes" do
    it "does not save the new contact in the database" do
      expect{
        post :create,
          contact: attributes_for(:invalid_contact)
      }.not_to change(Contact, :count)
    end

    it "re-renders the :new template" do
      post :create,
        contact: attributes_for(:invalid_contact)
      expect(response).to render_template :new
    end
  end
end
```

В этом коде есть несколько вещей на которые стоит обратить пристальное внимание:

В данном случае мы их используем `context` блоки для описания разных _состояний_: с валидными и не валидными атрибутами. Пример с не валидными атрибутами использует отнаследованную фабрику `:invalid_contact` которую мы  создали в начале главы.

Так же стоит обратить внимание на хук `before` который мы используем в начале блока `describe`. Ввиду того что мы прописали валидацию наличия трех телефонов, в инстанс переменной `@phones` у экземпляра модели `Contact` ассоциированных с ним, нам необходимо соответственно и в тестах передать такой атрибут. Это только один из вариантов сделать это, создать массив из трех атрибутов телефона и передать в POST запрос. В дальнейшем мы рассмотрим другой, более эффективный способ.

:warning: Если реально хотите прокачатся в использовании `attributes_for()` и ассоциациях, гляньте в официальную [доку](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#custom-strategies) Factory Girl.

И наконец давайте посмотрим на то как мы используем `expect` в первом примере. На этот раз мы передаем полноценный HTTP запрос в `expect` блоком(`{}`). Этот подход немного сложнее чем тот что мы использовали ранее. HTTP запрос передается в виде Proc'а, результат оценивается до и после, таким образом проще понять произошло ли ожидаемое изменение или нет(как в данном случае).

И как обычно читаемость RSpec синтаксиса "неотразима" — предположим что код здесь делает что то (или не делает)(`.to` или `.not_to`). Этот небольшой пример проверяет создался ли объект и размещен ли он в БД. Ознакомьтесь с этой техникой как следует! Она буде очень полезна в тестировании разнообразных методов контроллеров, моделей и в итоге, на уровне интеграционных тестов.

## Тестирование PATCH запросов

В нашем методе контроллера `update` нам необходимо проверить пару вещей:

- Первая: атрибуты которые мы передаем методу, должны быть присвоены модели которую мы хотим обновить.
- Вторая: редирект должен работать именно так как мы хотим.


Давайте воспользуемся приемуществом использовани PATCH HTTP запроса, который доступен в рельсах выше версии 4.1(в версиях до 4.0 вместо PATCH используется PUT):

**spec/controllers/contacts_controller_spec.rb**
```ruby
describe 'PATCH #update' do
  before :each do
    @contact = create(:contact,
      firstname: 'Lawrence',
      lastname: 'Smith')
  end

  context "valid attributes" do
    it "locates the requested @contact" do
      patch :update, id: @contact, contact: attributes_for(:contact)
      expect(assigns(:contact)).to eq(@contact)
    end

    it "changes @contact's attributes" do
      patch :update, id: @contact,
        contact: attributes_for(:contact,
          firstname: 'Larry',
          lastname: 'Smith')
      @contact.reload
      expect(@contact.firstname).to eq('Larry')
      expect(@contact.lastname).to eq('Smith')
    end

    it "redirects to the updated contact" do
      patch :update, id: @contact, contact: attributes_for(:contact)
      expect(response).to redirect_to @contact
    end
  end

  # ...
end
```

Так же необходимо проверить ситуацию когда мы передаем не валидные атрибуты в параметры:

**spec/controllers/contacts_controller_spec.rb**
```ruby
describe 'PATCH #update' do
  # ...

  context "with invalid attributes" do
    it "does not change the contact's attributes" do
      patch :update, id: @contact,
        contact: attributes_for(:contact,
          firstname: 'Larry',
          lastname: nil)
      @contact.reload
      expect(@contact.firstname).not_to eq('Larry')
      expect(@contact.lastname).to eq('Smith')
    end

    it "re-renders the edit template" do
      patch :update, id: @contact,
        contact: attributes_for(:invalid_contact)
      expect(response).to render_template :edit
    end
  end
end
```

- Так как мы хотим обновить существующий контакт, нам необходимо сначала сделать запись в БД. Мы позаботились об этом в хуке `before`, благодаря этому мы можем быть уверенны что в переменной `@contact` будет назачен контакт сохраненный в БД. Мы рассмотрим более подходящие варианты сделать это в последующих главах.

- В обоих примерах где мы проверяем, правда ли атрибуты обьекта изменены методом `update`, нельзя использовать `expect{}` как Proc. Напротив, нам необходимо вызвать метод `reload` у `@contact` что бы проверить, правда ли наши данные записались в БД. Другими словами, эти примеры сделаны по схеме схожей с той что мы использовали в тестах с POST запросами.

## Тестирование DELETE запросов

После всего что мы разобрали до этого, тестирование метода `destroy` относительно простая задача:

**spec/controllers/contacts_controller_spec.rb**
```ruby
describe 'DELETE #destroy' do
  before :each do
    @contact = create(:contact)
  end

  it "deletes the contact" do
    expect{
      delete :destroy, id: @contact
    }.to change(Contact,:count).by(-1)
  end

  it "redirects to contacts#index" do
    delete :destroy, id: @contact
    expect(response).to redirect_to contacts_url
  end
end
```

На данный момент вы должны уже понимать что происходит. Первое предположение позволяет проверить нам действительно ли метод контроллера `destroy` удаляет объект(используя уже знакомый `expect{}` Proc); втрое предположение проверяет происходит ли редирект на "index" в случае успеха.

## Тестирование "не CRUD" методов

Тестирование других методов контроллера не сильно отличается от тестирования стандартных(которые идут из коробки, "RESTful" ресурсы). Давайте проверим гипотетический пример с `hide_contact` методом из `ContactsController`'а, котрый позволит администартору удоно скрывать контакты не удаляя их из БД.(Оставлю вам возможность самостоятельно интегрировать эту фичу, если у вас есть желание).

Нам надо ее будет протестировать следующим образом:


```ruby
describe "PATCH hide_contact" do
  before :each do
    @contact = create(:contact)
  end

  it "marks the contact as hidden" do
    patch :hide_contact, id: @contact
    expect(@contact.reload.hidden?).to be_true
  end

  it "redirects to contacts#index" do
    patch :hide_contact, id: @contact
    expect(response).to redirect_to contacts_url
  end
end
```

Если ваш метод использует один из методов с HTTP запросом, используйте примеры как для CRUD.

## Тестирование вложенных маршрутов

Вложенные маршруты выгледят примерно так `/contacts/34/phones/22`

## :warning:
Что бы хорошо разобратся с вложенными ресурсами почитайте [документацию](https://guides.rubyonrails.org/routing.html#nested-resources) и эту [статью](https://weblog.jamisbuck.org/2007/2/5/nesting-resources)

В другом гипотетическом примере давате иплементируем телефоны при помощи вложенных ресурсов, вместо вложенных аттрибутов. Это значит что вместо введения каждого атрибута телефона в форме асоциированного контакта, нам необходимо разбить комбинацию `controller` для сбора и обработки данных телефонов. Конфиг пути в _con-
fig/routes.rb_ будет выглядеть следующим образом:

**config/routes.rb**
```ruby
resources :contacts do
  resources :phones
end
```

Теперь если мы проверим наши пути в командной строке при помощи `rake routes` то путь к методу `:show` `PhoneController'a` будет выглядеть как _/contacts/:contact_id/phones/:id_. То есть нам необходимо передать `:id` телефона и `:contact_id` родительского контакта. Так это будет выглядеть в тесте:

```ruby
describe 'GET #show' do
  it "renders the :show template for the phone" do
    contact = create(:contact)
    phone = create(:phone, contact: contact)
    get :show, id: phone, contact_id: contact.id
    expect(response).to render_template :show
  end
end
```


Главное, что нужно помнить, это то, что вам нужно передать родительский маршрут на сервер в форме `:parent_id` – в данном случае `:contact_id`. Контроллер будет обрабатывать вещи оттуда, как указано в вашем файле _route.rb_. Эта базовая техника может быть применима к любому методу контроллера который использует вложенные пути(_маршруты_).

## Тестирование ответа контроллера НЕ HTML формата

Во всех предидущих случях мы работали с тестированием методов контороллеров с HTML ответом. Рельсы дают нам возможность делать ответ из одного метода контроллера в разных форматах.

Завершая наш цикл гипотетических примеров, давайте предположим что нам надо экспортировать контакты в _CSV_ файл. Если вы уже делали вывод не HTML формата из контроллера в вашем приложении, вы, вероятно, знаете, как переопределить HTML по умолчанию в данном маршрут метода:

```ruby
link_to 'Export', contacts_path(format: :csv)
```

Это предпологает следующий метод контроллера:
```ruby
def index
  @contacts = Contact.all

  respond_to do |format|
    format.html # index.html.erb
    format.csv do
      send_data Contact.to_csv(@contacts),
      type: 'text/csv; charset=iso-8859-1; header=present',
      disposition: 'attachment; filename=contacts.csv'
    end
  end
end
```

Проще всего здесь проверить тип данных:

```ruby
describe 'CSV output' do
  it "returns a CSV file" do
    get :index, format: :csv
    expect(response.headers['Content-Type']).to match 'text/csv'
  end

  it 'returns content' do
    create(:contact,
    firstname: 'Aaron',
    lastname: 'Sumner',
    email: 'aaron@sample.com')
    get :index, format: :csv
    expect(response.body).to match 'Aaron Sumner,aaron@sample.com'
  end
end
```

Отметим что использование матчера `match`. Хотя он используется для сравнения полученных результатов с регулярным выражением.

Выполняется проверка результата работы контроллера: ответ пришел в формате _CSV_ с необходимым типом содержания. Однако, учитывая структуру, которую мы используем для создания CSV-контента: то есть с методом класса в контакте, тестируя эту функциональность на уровне модели (в отличие от уровня контроллера), пожалуй, идеальный способ:

```ruby
it "returns comma separated values" do
  create(:contact,
    firstname: 'Aaron',
    lastname: 'Sumner',
    email: 'aaron@sample.com')
  expect(Contact.to_csv).to match /Aaron Sumner,aaron@sample.com/
end
```

## :warning:
Более подробно о создании _CSV_ гляньте [Эпизод 362 из RailsCasts](http://railscasts.com/episodes/362-exporting-csv-and-excel)


Так же, относительно легко, можно протестировать _XML_ и _JSON_ ответы на уровне контроллеров:

```ruby
it "returns JSON-formatted content" do
  contact = create(:contact)
  get :index, format: :json
expect(response.body).to have_content contact.to_json
end
```

## Итоги

В двух словах, глава про то, как тестировать контроллеры приложения. Идея в том что бы разложить то что вы хотите протестировать по фрагментам, а затем постепенно писать тесты пока не покроете всю функциональность.

К сожалению тесты контроллеров не всегда просты и прямолинейны. Зачастую вам прийдется боротся с логированием пользователей, не шаблонным кодом, и моделями с конкретными требованиями валидации. Мы рассмотрим это далее.
