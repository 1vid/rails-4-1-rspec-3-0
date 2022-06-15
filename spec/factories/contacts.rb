FactoryGirl.define do
  factory :contact do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name}
    email { Faker::Internet.email }

    after(:build) do |contact| #callback we can also use before(:build), before(:create), and after(:create)
      [:home_phone, :work_phone, :mobile_phone].each do |phone|
        contact.phones << build(:phone,
          phone_type: phone, contact: contact)
      end
    end

    factory :invalid_contact do
      firstname nil
    end
  end
end
