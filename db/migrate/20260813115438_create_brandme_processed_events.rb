# frozen_string_literal: true

class CreateBrandmeProcessedEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :brandme_processed_events do |t|
      t.string :webhook_id, null: false
      t.string :event_type, null: false
      t.string :order_id, null: false
      t.string :product_id, null: false
      t.string :email, null: false

      t.timestamps
    end

    add_index :brandme_processed_events,
              :webhook_id,
              unique: true,
              name: "idx_brandme_processed_events_webhook_id"

    add_index :brandme_processed_events,
              :order_id,
              name: "idx_brandme_processed_events_order_id"
  end
end