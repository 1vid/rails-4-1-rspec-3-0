require 'factory_girl_rails'

User.find_or_create_by(
  email: 'admin@example.com',
  password_digest: BCrypt::Password.create('secret'),
  admin: true
)

10.times do 
  FactoryGirl.create(:contact)
end
