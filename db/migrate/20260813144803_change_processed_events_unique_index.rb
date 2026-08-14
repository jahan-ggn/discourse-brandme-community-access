# frozen_string_literal: true
class ChangeProcessedEventsUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :brandme_processed_events,
                 name: "idx_brandme_processed_events_webhook_id"

    add_index :brandme_processed_events,
              [:webhook_id, :product_id, :event_type],
              unique: true,
              name: "idx_brandme_processed_events_unique_event"
  end
end
