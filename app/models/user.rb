class User < ApplicationRecord
	has_many :orders
  has_many :favorites
  has_many :messages

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  devise :omniauthable, omniauth_providers: %i[google_oauth2]

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first

    # Uncomment the section below if you want users to be created if they don't exist
    unless user
        user = User.create(name: data['name'],
           email: data['email'],
           password: Devise.friendly_token[0,20],
           confirmed_at: Time.new,
           true_name: data['last_name'] + data['first_name'],
           role: 'member'
        )
    end
    user
  end

  ROLES = %i[admin employee member]

  def role_cn
  	case self.role
  	when 'admin'
  		'管理員'
		when 'employee'
  		'員工'
		when 'member'
  		'一般會員'
    end
  end

end
