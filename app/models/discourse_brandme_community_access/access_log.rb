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
      no_group_mapping
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
