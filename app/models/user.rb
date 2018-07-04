class User < ApplicationRecord
	has_many :orders
  has_many :favorites
  has_many :messages

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  devise :omniauthable, omniauth_providers: %i[google_oauth2]
  # devise :omniauthable, omniauth_providers: %i[google_oauth2 facebook]

  # def self.from_omniauth_google(access_token)
  #   data = access_token.info
  #   user = User.where(email: data['email']).first
  #   ccc
  #   unless user
  #     user = User.create(name: data['name'],
  #        email: data['email'],
  #        password: Devise.friendly_token[0,20],
  #        confirmed_at: Time.new,
  #        true_name: data['last_name'] + data['first_name'],
  #        role: 'member',
  #        provider: '',
  #     )
  #     user.skip_confirmation!
  #   end
  #   user
  # end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      # user.email = auth.info.email.present? ? auth.info.email : '未取得'
      user.email = auth.info.email
      
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.skip_confirmation!
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
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
