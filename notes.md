# Продвинутые тесты контроллеров

Итак, мы разобралисьс базовыми техниками тестирования контроллеров. Теперь давайте взглянем как RSpec помогает программисту быть уверенным что контроллеры делают именно то что он предпологает.

В этот раз мы будем опиратся на "ванильный" _CRUD_ при написании тестов, толко с учетом слоёв аутентификации и авторизации. Небольшой план по которому мы будем двигатся в этой главе:

- Мы начнем с создания более сложного `spec`'a.
- Далее мы покроем тыстами аутентификацию, или _требования для входа_, через контроллер.
- Мы реализуем это тестируя авторизацию, или _роли_, так же через контроллер.
- Так же мы взглянем на техники которые подарят нам уверенность что тесты контроллеров корректно работают с дополнительными настройками(фичами) которые могут быть в вашем приложении.

## Подготовимся

В предидущей главе мы закомментировали `before_action` для аутентификации `ContactController`'a. Раскомментируем, что бы снова включить аутентификацию. Запустем RSpec и посмотрим сколько тестов сломается!

```ruby
Finished in 1.11 seconds (files took 3.15 seconds to load)
32 examples, 13 failures
```

Нам необходимо имитировать процесс авторизации в "спеке" контроллера. Самое главное, совладать с юзером который залогинился или нет, и ролью залогиненого юзера. Напомню, что вам необходимо быть юзером что бы добавлять и редактиовать контакты, и вам необходимо быть администратором что бы добавлять юзеров. Мы используем базовые механизмы в контроллере нашего приложения, для обработки уровня авторизации в самом приложении, и протестируем мы это на уровне контроллера.

## Тестирование ролей админа юзера
Мы используем другой подход, что бы "пройтись" по тестам контроллера в этот раз. Мы пройдемся по каждой возможно роли: гость, юзер и администратор. Давайте начнем с тех тестов которые падают. В нашем пиложении юзеры и админы(те у котрых будевое значение `:admin` включено) обладают одинаковыми правами по отношению к контактам: Любой юзер который вошел с валидного аккаунта может создавать, редактировать и удалять любой контакт.

Сначала давайте сделаем фабрику для пользователей:

**factories/users.rb**
```ruby
FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password 'secret'
    password_confirmation { password }

    factory :admin do
      admin true
    end
  end
end
```

Это позволит нам быстренько создавать обьект с новым юзером при помощи `create(:user)`(`FactoryGirl.create(:user)` если не сокращать). Так же мы сделали дочернюю фабрику `admin` которая создает юзера с ролью администратора, изменяя булевое значение поля `admin` на `true`.

Теперь вернемся к спеку контроллера. Давайте используем фабрику что бы протестировать доступ администратора. Обратите особое внимание на первые несколько строк:

**spec/controllers/contacts_controller_spec.rb**
```ruby
  describe "administrator access" do
    before :each do
      user = create(:admin)
      session[:user_id] = user.id
    end

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

    describe 'GET #show' do
      it "assigns the requested contact to @contact" do
        contact = create(:contact)
        get :show, id: contact
        expect(assigns(:contact)).to eq contact
      end

      it "renders the :show template" do
        contact = create(:contact)
        get :show, id: contact
        expect(response).to render_template :show
      end
    end

    # and so on ...
  end
```

Что здесь происходит? Все очень просто! "Рили": мы начали с того что упрятали все имеющиеся тесты в `describe` блок, и добавили туда `before` блок, что бы каждый раз имитировать вход с правами администратора. Сначала "инстанциируется"(записывается в инстанс переменную) обьект "администратор" при помощи нашей новой `:admin` фабрики, а потом отправляем это значение напрямую в сессию.

В данном случае это все. С симуляцией валидного входа(логина), тесты контроллера снова проходят.

Для краткости автор не стал включать полностью тесты для юзера не админа. Взглянте на код приложения: кроме блока `before :each` все предположения остаются теми же:

**spec/controllers/contacts_controller_spec.rb**
```ruby
 describe "user access" do
  before :each do
    user = create(:user)
    session[:user_id] = user.id
  end

  # specs are the same as administrator
end
```

Да, пока что мы видим много избыточного(лишнего) кода. Но е стоит переживать, у RSpec есть фичи что бы это пофиксить. Мы займемся этим в следующей главе. А сейчас нам необходимо сфокусироватья на различных кейсах которые надо протестировать.

## Тестирование роли гостя(guest)

Частенько легко проглядеть роль гостя — это пользователь который не залогинился. Хотя, в публичных приложениях(таких как наше), это может быть самая распространённая роль. Давайте добавим ее в `spec`. В отличае от тестов других ролей, нам необходимо внести изменения в тесты, это достаточно просто:

**spec/controllers/contacts_controller_spec.rb**

```ruby
describe "guest access" do

  # GET #index and GET #show examples are the same as those for
  # administrators and users

  describe 'GET #new' do
    it "requires login" do
      get :new
      expect(response).to redirect_to login_url
    end
  end

  describe 'GET #edit' do
    it "requires login" do
      contact = create(:contact)
      get :edit, id: contact
      expect(response).to redirect_to login_url
    end
  end

  describe "POST #create" do
    it "requires login" do
      post :create, id: create(:contact),
        contact: attributes_for(:contact)
      expect(response).to redirect_to login_url
    end
  end

  describe 'PUT #update' do
    it "requires login" do
      put :update, id: create(:contact),
        contact: attributes_for(:contact)
      expect(response).to redirect_to login_url
    end
  end

  describe 'DELETE #destroy' do
    it "requires login" do
      delete :destroy, id: create(:contact)
      expect(response).to redirect_to login_url
    end
  end
end
```

Ничего нового в _show_ и _index_ нету, пока мы не наткнемся на _new_. "Доступ по логину", к этому блоку подключается в первой строчке контроллера `before_action :authenticate, except: [:index, :show]`. На этот раз нам необходимо убедится чо гость не может пользоватся методами контроллера, и его должно редиректить на `login_url`, точку где приложение попросит его залогинится. Мы можем использовать эту технюку для любых методов которым необходим логин.

Ради эксперимента закомментируем строку `before_action :authenticate` снова, и запустим тесты. Так же вы можете поменять `expect(response).to redirect_to login_url` на `expect(response).not_to redirect_to login_url` или изменить `login_url` на другой путь. 

## :warning:
_это норм тема ломать вещи таким образом, чо бы избежать прохождения ложных предположений в ваших тестах_

## Тестирование авторизации

Наконец, нам необходимо рассмотреть другой контроллер, что бы протестировать авторизацию юзера, посмотреть что ему\ей позволено делать после успешного входа. В рассматриваемом приложении, только админы могут добавлять новых юзеров. Обычным юзерам(`admin: false`) должно быть отказано в доступе.

Базово подход такой же как мы делали ранее: Создаем юзера для симуляции `before :each` блоке, передаем `user_id` в переменную сессии так же в  `before :each` блоке, затем пишем тесты. На этот раз в отличии от редиректа в форму логина, юзера должно редиректнуть на _root URL_. Такое поведение описано в _app/controllers/application_controller.rb_. Вот тесты для этого сценария:

**spec/controllers/users_controller_spec.rb**
```ruby
describe UsersController do
  describe 'user access' do
    before :each do
      @user = create(:user)
      session[:user_id] = @user.id
    end

    describe 'GET #index' do
      it "collects users into @users" do
        user = create(:user)
        get :index
        expect(assigns(:users)).to match_array [@user,user]
      end

      it "renders the :index template" do
        get :index
        expect(response).to render_template :index
      end
    end

    it "GET #new denies access" do
      get :new
      expect(response).to redirect_to root_url
    end

    it "POST#create denies access" do
      post :create, user: attributes_for(:user)
      expect(response).to redirect_to root_url
    end
  end
end
```

## Заключение

Пы покрыли дофигище много в последних двух главах, и это доказывает что можно протестировать дофигище функциональности и получить хорошее покрытие тестами на уровне контроллеров.

Как автор упомянал ранее, он не всегда тщательно тестирует контроллеры в своих приложениях. Он использует тесты контроллеров в каких то специфических(типичных, для [non-boilerplate](https://en.wikipedia.org/wiki/Boilerplate_code)) случаях. Короче суть в том что есть некоторые вещи которые вы можете(и должны) тестировать на уровне контроллера.

И тщательное покрытие тестами контроллеров в вашем приложении это верны путь к тщательному покрытию ваего приложения в целом. На данном этапе вы уже увидели хорошии практики и освоили передовые техники использования RSpec, FactoryGirl и других хелперов которые делают ваши тесты более надежными.

Но по прежнему мы еще не достигли прдела совершенствования наших тестов. В следующе главе мы еще разок пройдемся по этим спекам, подчистим их используя хелперы и "общие примеры"(_хз что это значит., но скоро узнаем_).

## Упражнения

Для данного контроллера в вашем приложении накидайте табличку какой метод должен быть доступен какому пользователю. Например представим что у нас есть приложения для блоггинга с премиальным контентом, пользователям необходмио становится "членами" для полного доступа к контенту, но при этом для гостевые пользователи должны понимать к чему у них нет доступа.

| Role | Index | Show | Create | Update | Destroy |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| Admin | Full | Full | Full | Full | Full |
| Editor | Full | Full | Full | Full | Full |
| Author | Full | Full | Full | Full | None |
| Member | Full | Full | None | None | None |
| Guest | Full | None | None | None | None |

Используйте эту таблицу, что бы разобратся с различными сценариями которые небходимо протестировать.
