# frozen_string_literal: true

class CreateBrandmeAccessLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :brandme_access_logs do |t|
      t.string :webhook_id, null: false
      t.string :event_type, null: false
      t.string :order_id, null: false
      t.string :product_id, null: false
      t.string :email, null: false
      t.string :group_name
      t.string :action, null: false
      t.string :status, null: false
      t.text :message

      t.timestamps
    end

    add_index :brandme_access_logs,
              :webhook_id,
              name: "idx_brandme_access_logs_webhook_id"

    add_index :brandme_access_logs,
              :order_id,
              name: "idx_brandme_access_logs_order_id"

    add_index :brandme_access_logs,
              :product_id,
              name: "idx_brandme_access_logs_product_id"

    add_index :brandme_access_logs,
              :email,
              name: "idx_brandme_access_logs_email"

    add_index :brandme_access_logs,
              :created_at,
              name: "idx_brandme_access_logs_created_at"
  end
end