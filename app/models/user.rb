class User < ApplicationRecord
	has_many :orders
  has_many :favorites
  has_many :messages

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  devise :omniauthable, omniauth_providers: %i[google_oauth2]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.skip_confirmation!
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
