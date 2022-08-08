# 07. Наведем порядок в тестах контроллера

Если вы применили все чему мы научились ранее к вашему собственному коду, то вы на верном пути к навыку создания надежных тестов. Тем не менее в последней главе мы использовали много повторений и там были потенциально хрупкие тесты. Что случится если вдруг вместо редиректа неавторизованного пользователя на `root_path` мы создадим специальный `denied_path`? Нам предстоит почистить много спеков.

Так же как и в коде приложения, вам необходимо искать возможности чистить код ваших тестов. В этой главе ммы рассмотрим три варианта как снизить избыточность(повторяющийся, ненужный код) и хрупкость, с сохранением "читабельности": 

- Для начала мы расшарим примеры на несколько `describe`  и `context` блоков.
- Затем мы уберем повторения использую _macros_ хэлпер.
- И закончим созданием кастомных RSpec матчеров :metal:

 ## Общие примеры

 Вернемся к первой главе. Когда мы обсуждали основные подходы к тестированию, автор сказал что читаемость тестов важнее 100% высушенного чистого теста. Но посмотрите не _contacts_controller_spec.rb_ там точно есть что убрать. В том виде в котором он сейчас, у нас есть много примеров которые дублируются(один для админов и один для обычных юзеров). Некоторые примеры встречаются трижды(гест юзеры, админы и обычные юзеры все имеют доступ к методам `:show` и `:index`. Это ставит под угрозу читаемость и долгосрочную поддержку.

 Rspec дает нам замечательную возможность хорошенько подчистить код при помощи _shared examples_(расшаренных примеров). Сделать расшаренный пример достаточно просто: Сначала необходимо создать блок для примеров как показано ниже:

 _spec/controllers/contacts_controller_spec.rb_
 ```ruby
shared_examples 'public access to contacts' do
  before :each do
  @contact = create(:contact,
    firstname: 'Lawrence',
    lastname: 'Smith'
  )
end

  describe 'GET #index' do
    it "populates an array of contacts" do
      get :index
      expect(assigns(:contacts)).to match_array [@contact]
    end

    it "renders the :index template" do
      get :index
      expect(response).to render_template :index
    end
  end

  describe 'GET #show' do
    it "assigns the requested contact to @contact" do
      get :show, id: @contact
      expect(assigns(:contact)).to eq @contact
    end

    it "renders the :show template" do
      get :show, id: @contact
      expect(response).to render_template :show
    end
  end
end
 ```

 Затем вставим их в любой `describe` или `context` блок в котором вы хотите использовать примеры, как показано ниже(для понятности здесь нету основнй части кода, посмотрите в приложении что бы понять контекст):

 **spec/controllers/contacts_controller_spec.rb**
 ```ruby
 describe "guest access" do
  it_behaves_like "public access to contacts"

  # rest of specs for guest access ...
end
```

Давайте продолжим со вторым сетом "расшаренных примеров". На этот раз мы создадим пример у которого будет возможность управлять контактами. Эта возможность появляется благодаря роли юзера или админа. Начнем разбиратся с другим `shared_examples` блоком и встроим его в существующую функциональность. 
Хотя фактический код теста ниже не приводится, он, конечно же, должен быть для того, чтобы спек действительно что-то делал. Индивидуальные предположения остались такими же как и в предидущих главах, мы просто их реорганизовали для уменьшения дублирования кода.

В результате такого подхода наш `contacts_controller_spec.rb` стал чище, взгляните сами:

**spec/controllers/contacts_controller_spec.rb**
```ruby
require 'rails_helper'

describe ContactsController do
  shared_examples_for 'public access to contacts' do
    describe 'GET #index' do
      context 'with params[:letter]' do
        it "populates an array of contacts starting with the letter" do
        it "renders the :index template" do
      end

      context 'without params[:letter]' do
        it "populates an array of all contacts" do
        it "renders the :index template" do
      end
    end

    describe 'GET #show' do
      it "assigns the requested contact to @contact" do
      it "renders the :show template" do
    end
  end

  shared_examples 'full access to contacts' do
    describe 'GET #new' do
      it "assigns a new Contact to @contact" do
      it "assigns a home, office, and mobile phone to the new contact" do
      it "renders the :new template" do
    end

    describe 'GET #edit' do
      it "assigns the requested contact to @contact" do
      it "renders the :edit template" do
    end

    describe "POST #create" do
      context "with valid attributes" do
        it "saves the new contact in the database" do
        it "redirects to contacts#show" do
      end

      context "with invalid attributes" do
        it "does not save the new contact in the database" do
        it "re-renders the :new template" do
      end
    end

    describe 'PATCH #update' do
      context "valid attributes" do
        it "locates the requested @contact" do
        it "changes the contact's attributes" do
        it "redirects to the updated contact" do
      end

      context "invalid attributes" do
        it "locates the requested @contact" do
        it "does not change the contact's attributes" do
        it "re-renders the edit method" do
      end
    end

    describe 'DELETE #destroy' do
      it "deletes the contact" do
      it "redirects to contacts#index" do
    end
  end

  describe "administrator access" do
    it_behaves_like 'public access to contacts'
    it_behaves_like 'full access to contacts'
  end

  describe "user access" do
    it_behaves_like 'public access to contacts'
    it_behaves_like 'full access to contacts'
  end

  describe "guest access" do
    it_behaves_like 'public access to contacts'

    describe 'GET #new' do
      it "requires login"
    end

    describe 'GET #edit' do
      it "requires login"
    end

    describe "POST #create" do
      it "requires login"
    end

    describe 'PUT #update' do
      it "requires login"
    end

    describe 'DELETE #destroy' do
      it "requires login"
    end
  end
end
```
И если мы запустим `bin/rspec spec/controllers/contacts_controller_spec.rb`, мы увидим читаемый результат в формате документации:

```ruby
ContactsController
  administrator access
    behaves like public access to contacts
      GET #index
        with params[:letter]
          populates an array of contacts starting with the letter
          renders the :index template
        without params[:letter]
          populates an array of all contacts
          renders the :index template
      GET #show
        assigns the requested contact to @contact
        renders the :show template
    behaves like full access to contacts
      GET #new
        assigns a new Contact to @contact
        assigns a home, office, and mobile phone to the new contact
        renders the :new template
      GET #edit
        assigns the requested contact to @contact
        renders the :edit template
      POST #create
        with valid attributes
          saves the new contact in the database
          redirects to contacts#show
        with invalid attributes
          does not save the new contact in the database
          re-renders the :new template
      PATCH #update
        valid attributes
          locates the requested @contact
          changes the contact's attributes
          redirects to the updated contact
        invalid attributes
          locates the requested @contact
          does not change the contact's attributes
          re-renders the edit method
      DELETE #destroy
        deletes the contact
        redirects to contacts#index
  user access
    behaves like public access to contacts
      GET #index
        with params[:letter]
          populates an array of contacts starting with the letter
          renders the :index template
        without params[:letter]
          populates an array of all contacts
          renders the :index template
      GET #show
        assigns the requested contact to @contact
        renders the :show template
    behaves like full access to contacts
      GET #new
        assigns a new Contact to @contact
        assigns a home, office, and mobile phone to the new contact
        renders the :new template
      GET #edit
        assigns the requested contact to @contact
        renders the :edit template
      POST #create
        with valid attributes
          saves the new contact in the database
          redirects to contacts#show
        with invalid attributes
          does not save the new contact in the database
          re-renders the :new template
      PATCH #update
        valid attributes
          locates the requested @contact
          changes the contact's attributes
          redirects to the updated contact
        invalid attributes
          locates the requested @contact
          does not change the contact's attributes
          re-renders the edit method
      DELETE #destroy
        deletes the contact
        redirects to contacts#index
  guest access
    behaves like public access to contacts
      GET #index
        with params[:letter]
          populates an array of contacts starting with the letter
          renders the :index template
        without params[:letter]
          populates an array of all contacts
          renders the :index template
      GET #show
        assigns the requested contact to @contact
        renders the :show template
    GET #new
      requires login
    GET #edit
      requires login
    POST #create
      requires login
    PUT #update
      requires login
    DELETE #destroy
      requires login
```

## Создание макросов хелперов

Теперь давайте обратим внимание на другой кусочек кода который мы использовали несколько раз в нашем контроллере. Когда бы мы не тестировали что может или не может сделать залогиненнный пользователь, мы симулируем состояние залогиненности устанавливая значение сессии в фабрике генерируя `:id` юзера. Давайте вынесем эту функианальность в RSpec _macro_. Макросы это простой способ создавать методы которые могут быть использованы на протяжении всего вашего набора тестов. Конвенционально макросы распологаются в директории _spec/support_ как модуль, потом подключаются в конфиге RSpec(это будет чуть дальше).

Вот макрос для устанвки "сешн"(сессионной) переменной:

**spec/support/login_macros.rb**
```ruby
module LoginMacros
  def set_user_session(user)
    session[:user_id] = user.id
  end
end
```

Простейший Ruby модуль и метод: он принимает `user` обьект и записывает его `session[:user_id]` непосредственно в его `:id`.

Перед тем как начать пользоватся нам нашим новым хелпером, нам надо указать RSpec'у где его искать.
В блоке `RSpec.configure` в конфигурационном файле `spec/rails_helper.rb` нам необходимо добавить строку `config.include LoginMacros` как показано ниже:

**spec/rails_helper.rb**
```ruby
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # other RSpec configuration omitted ..

  config.include LoginMacros
end
```

## :warning:
Варианты аутентификации, такие как Devise, предлагают аналогичную функциональность. Если вы используете такие решения в вашем проекте, посмотрите в [документацию](https://github.com/heartcombo/devise/wiki/How-To:-Test-controllers-with-Rails-(and-RSpec)) что бы инкорпорировать это в ваши тесты. Там все достаточно подробно описано.

Давайте не отходя от кассы сразу добавим этот макрос в наш спек контроллера. В блоке `before` мы создадим нового юзера-админа, затем создадим сессию для этого юзера. Все это в одну линию:

**spec/controllers/contacts_controller_spec.rb**
```ruby
describe "administrator access" do
  before :each do
    set_user_session create(:admin)
  end

  it_behaves_like "public access to contacts"
  it_behaves_like "full access to contacts"
end
```

Это может выглядет глупо, создавать целый отдельны хелпер-метод для одной единственной строки кода, но на самом деле может случится так что нам необходимо будет изменить всю систему аутентификации, и необходимо будет реализовать логин в другом "дизайне". Симуляция логина в тако манере позволит нам вносить изменения всего в одном месте.

В следующей главе мы начнем погружение в интеграционное тестирование, эта техника поможет нам переиспользовать несколко строчек кода, для симуляции каждого шага логирования пользователя.

## Использование кастомных матчеров
До сих пор мы с отлично справлялись используюя стандартные матчеры предоставляемые RSpec, честно говоря мы можем протестировать целое приложение не отклоняяс от стандартов. (100%). Тем не менее, так же как и наше создание макроса в последней секции, добавление нескольких кастомных матчеров в ваше приложение может значительно повысить поддерживаемость тестов в долгосрочной перспективе. В нашем случае с адресной книги, что если мы изменим путь к форме логина или к той точке куда попадают юзеры которые пытаются получить доступ к контенту на который у них нет доступа? В таком случае нам необходимо будет поменять рауты в большом количестве примеров, или же мы можем создать кастомный матчер и менять путь всего лишь в одном месте. Если мы разместим кастомный матчер в директории _spec/support/matchers_, один матчер — один файл, по дефолту конфиг RSpec автоматом подхватит их для использования в ваших спеках.

Вот пример:

**spec/support/matchers/require_login.rb**
```ruby
RSpec::Matchers.define :require_login do |expected|
  match do |actual|
    expect(actual).to redirect_to Rails.application.routes.url_helpers.login_path
  end

  failure_message do |actual|
    "expected to require login to access the method"
  end

  failure_message_when_negated do |actual|
    "expected not to require login to access the method"
  end

  description do
    "redirect to the login form"
  end
end
```

Давайте пройдемся по этому коду: в блоке `match` мы описываем то что должно случится, по подстановка кода после `expect(something).to` в нужном спеке. Отметим что RSpec не подгружает Рельсовую `UrlHelpers` библиотеку, так шо мы помогаем матчеру указывая весь путь целиком. Мы проверяем значение _actual_ которое мы передаем в матчер(в данном сучае это будет _response_), подходит ли оно под наше предположение(редирект на нашу логин форму). Если да то матчер отобразит положительный результат.

Следуещее что мы можем сделать это вспомогательные сообщения об ошибке в случае не совпадения: первое сообщение для случаев когда мы предпологаем что матчер вернет _true_, второе для обратного случая _false_. Другими словами матчер закрывает сразу два варианта  `expect(:foo).to` и `expect(:foo).not_to`, теряется необходимость в использовании двух матчеров.

Теперь достаточно просто заменить мачеры в наших примерах:

**spec/controllers/contacts_controller_spec.rb**

```ruby
describe 'GET #new' do
  it "requires login" do
    get :new
    expect(response).to require_login
  end
end
```

Это лиш один из примеров того как мы можем использовать кастомный матчер. Выдумывать другой, более причудливый пример было бы весмьа надуманно в данном случае, и мог сбить с толку. Поэтому автор предлагает ознакомится с другими матчерами в [документации к RSpec.](https://www.relishapp.com/rspec/rspec-expectations/v/3-1/docs/custom-matchers)

## Заключение

В неопрятном(неухоженном, сделанном без должного внимани) виде, спеки контроллеров очень быстро выходят из под контроля, но приложив немного усилий(при помощи полезных методов-хелперов которые предоставляет функционал RSpec) вы можете держать ваши тесты под контролем для их надежной и долгосрочной поддержки. Не стоит игнорировать тестирование контроллеров, так же и не стоит игнорировать вашу ответственность в поддержании порядка в тестах. Вы в будущем скажете себе огромное спасибо за такой подход.

Что ж, мы потратили кучу времени тестируя контроллеры. Как автор упомянал в начале пятой главы, тестирование на этом уровне это экономный способ вам быть уверенным в в нормально такой части вашей кодовой базы и это отличная практика для тестирования на других уровнях, так как многие из концепций которые мы рассмотрели могут быть применены и на других уровнях. Поддерживая чистоту и читабельность вы можете сохранить уверенность в вашем приложении до конца его существования.

У нас остался еще один уровень тестирования: Интеграционный. Проделанная прежде работа дала нам комфорт и уверенность в строительных блоках нашего приложения. Теперь нам надо удостоверится что они отлично работают вместе.
