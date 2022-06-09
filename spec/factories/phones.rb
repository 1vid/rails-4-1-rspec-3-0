FactoryGirl.define do
  factory :phone do
    association :contact  #create a new Contact on the fly for this phone
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