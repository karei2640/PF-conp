class ViewCount < ApplicationRecord
    belongs_to :customer
    belongs_to :game
end
