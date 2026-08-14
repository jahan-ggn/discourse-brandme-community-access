# frozen_string_literal: true

module DiscourseBrandmeCommunityAccess
  class ProcessedEvent < ActiveRecord::Base
    self.table_name = "brandme_processed_events"

    validates :webhook_id, presence: true
    validates :event_type, presence: true, inclusion: { in: %w[purchase refund] }
    validates :order_id, presence: true
    validates :product_id, presence: true
    validates :email, presence: true

    validates :webhook_id, uniqueness: { scope: [:product_id, :event_type] }
  end
end
# == Schema Information
#
# Table name: brandme_processed_events
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  event_type :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  order_id   :string           not null
#  product_id :string           not null
#  webhook_id :string           not null
#
# Indexes
#
#  idx_brandme_processed_events_order_id    (order_id)
#  idx_brandme_processed_events_unique_event  (webhook_id,product_id,event_type) UNIQUE
#
