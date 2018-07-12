class RemittanceInfo < ApplicationRecord
  belongs_to :order, optional: true
end
