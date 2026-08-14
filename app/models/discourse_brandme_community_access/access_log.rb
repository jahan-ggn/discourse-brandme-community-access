# frozen_string_literal: true

module DiscourseBrandmeCommunityAccess
  class AccessLog < ActiveRecord::Base
    self.table_name = "brandme_access_logs"

    STATUSES = %w[success failed].freeze

    ACTIONS = %w[
      added_to_group
      removed_from_group
      invite_sent
      invite_updated
      invite_revoked
      no_action_needed
    ].freeze

    validates :webhook_id, presence: true
    validates :event_type, presence: true
    validates :order_id, presence: true
    validates :product_id, presence: true
    validates :email, presence: true
    validates :action, presence: true
    validates :status, presence: true

    validates :event_type, inclusion: { in: %w[purchase refund] }

    validates :action, inclusion: { in: ACTIONS }

    validates :status, inclusion: { in: STATUSES }
  end
end

# == Schema Information
#
# Table name: brandme_access_logs
#
#  id         :bigint           not null, primary key
#  action     :string           not null
#  email      :string           not null
#  event_type :string           not null
#  group_name :string
#  message    :text
#  status     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  order_id   :string           not null
#  product_id :string           not null
#  webhook_id :string           not null
#
# Indexes
#
#  idx_brandme_access_logs_created_at  (created_at)
#  idx_brandme_access_logs_email       (email)
#  idx_brandme_access_logs_order_id    (order_id)
#  idx_brandme_access_logs_product_id  (product_id)
#  idx_brandme_access_logs_webhook_id  (webhook_id)
#
