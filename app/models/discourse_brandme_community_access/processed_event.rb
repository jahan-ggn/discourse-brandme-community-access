# frozen_string_literal: true

module DiscourseBrandmeCommunityAccess
  class ProcessedEvent < ActiveRecord::Base
    self.table_name = "brandme_processed_events"

    validates :webhook_id,
              presence: true,
              uniqueness: true

    validates :event_type,
              presence: true,
              inclusion: {
                in: %w[purchase refund],
              }

    validates :order_id, presence: true
    validates :product_id, presence: true
    validates :email, presence: true
  end
end