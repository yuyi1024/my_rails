class User < ApplicationRecord
	has_many :orders
  has_many :favorites

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

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
