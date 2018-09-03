class EcpayPaymentAtmInfo < ApplicationRecord
	belongs_to :order
	belongs_to :user
end
