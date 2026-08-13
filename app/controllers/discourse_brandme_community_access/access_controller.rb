# frozen_string_literal: true

module DiscourseBrandmeCommunityAccess
  class AccessController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    layout false

    skip_before_action :check_xhr
    skip_before_action :redirect_to_login_if_required
    skip_before_action :verify_authenticity_token

    before_action :verify_hmac

    REPLAY_WINDOW_SECONDS = 300
    MAX_FUTURE_SECONDS = 60

    REQUIRED_FIELDS = %w[event webhookId orderId productId email].freeze

    ALLOWED_EVENTS = %w[purchase refund].freeze

    def create
      payload = parse_payload
      return if performed?

      unless valid_payload?(payload)
        return render_error("Invalid payload: missing required fields", :bad_request)
      end

      if ALLOWED_EVENTS.exclude?(payload["event"])
        return render_error("Invalid event", :bad_request)
      end

      if ProcessedEvent.exists?(webhook_id: payload["webhookId"])
        return render_success("Already processed")
      end

      group = find_group_for_product(payload["productId"])

      unless group
        message = "No group mapping found for product #{payload["productId"]}"

        log_access(
          payload: payload,
          group: nil,
          action: "no_group_mapping",
          status: "failed",
          message: message,
        )

        return render_error(message, :not_found)
      end

      case payload["event"]
      when "purchase"
        handle_purchase(payload, group)
      when "refund"
        handle_refund(payload, group)
      end
    end

    private

    def verify_hmac
      secret = SiteSetting.discourse_brandme_community_access_secret

      return render_error("BrandMe secret is not configured", :forbidden) if secret.blank?

      timestamp = request.headers["X-BrandMe-Timestamp"]

      signature = request.headers["X-BrandMe-Signature"]

      if timestamp.blank? || signature.blank?
        return render_error("Missing authentication headers", :unauthorized)
      end

      unless timestamp.match?(/\A\d+\z/)
        return render_error("Invalid timestamp format", :bad_request)
      end

      request_time = Time.at(timestamp.to_i / 1000.0)

      if request_time < REPLAY_WINDOW_SECONDS.seconds.ago
        return render_error("Request timestamp too old", :unauthorized)
      end

      if request_time > MAX_FUTURE_SECONDS.seconds.from_now
        return render_error("Request timestamp too far in the future", :unauthorized)
      end

      raw_body = request.raw_post

      expected_signature = OpenSSL::HMAC.hexdigest("sha256", secret, "#{timestamp}.#{raw_body}")

      unless secure_signature_match?(expected_signature, signature)
        render_error("Invalid signature", :unauthorized)
      end
    end

    def secure_signature_match?(expected_signature, signature)
      return false unless expected_signature.bytesize == signature.bytesize

      ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
    end

    def parse_payload
      raw_body = request.raw_post

      if raw_body.blank?
        render_error("Empty request body", :bad_request)

        return nil
      end

      JSON.parse(raw_body)
    rescue JSON::ParserError
      render_error("Invalid JSON", :bad_request)

      nil
    end

    def valid_payload?(payload)
      return false unless payload.is_a?(Hash)

      REQUIRED_FIELDS.all? { |field| payload[field].present? }
    end

    def find_group_for_product(product_id)
      mappings = SiteSetting.discourse_brandme_community_access_product_group_mappings

      return nil if mappings.blank?

      mappings
        .split("|")
        .each do |entry|
          mapped_product_id, group_name = entry.split("=", 2)

          next if mapped_product_id.blank?
          next if group_name.blank?

          next unless mapped_product_id.strip == product_id.to_s.strip

          group = ::Group.find_by(name: group_name.strip)

          return group if group
        end

      nil
    end

    def handle_purchase(payload, group)
      email = normalize_email(payload["email"])

      user = ::User.find_by_email(email)

      if user
        add_user_to_group(payload, group, user)
      else
        invite_user_to_group(payload, group, email)
      end
    end

    def add_user_to_group(payload, group, user)
      group.add(user)

      log_access(payload: payload, group: group, action: "added_to_group", status: "success")

      mark_processed(payload)

      render_success("User #{user.username} added to group #{group.name}")
    rescue StandardError => e
      log_access(
        payload: payload,
        group: group,
        action: "added_to_group",
        status: "failed",
        message: e.message,
      )

      render_error("Failed to add user to group: #{e.message}", :internal_server_error)
    end

    def invite_user_to_group(payload, group, email)
      existing_invite = find_pending_invite(email)

      if existing_invite
        add_group_to_invite(existing_invite, group)

        log_access(payload: payload, group: group, action: "invite_updated", status: "success")

        mark_processed(payload)

        return render_success("Pending invite updated with group #{group.name}")
      end

      ::Invite.generate(::Discourse.system_user, email: email, group_ids: [group.id])

      log_access(payload: payload, group: group, action: "invite_sent", status: "success")

      mark_processed(payload)

      render_success("Invite sent to #{email} with group #{group.name}")
    rescue ::Invite::UserExists
      handle_invite_user_exists(payload, group, email)
    rescue StandardError => e
      log_access(
        payload: payload,
        group: group,
        action: "invite_sent",
        status: "failed",
        message: e.message,
      )

      render_error("Failed to send invite: #{e.message}", :internal_server_error)
    end

    def add_group_to_invite(invite, group)
      return if invite.groups.exists?(id: group.id)

      invite.groups << group
    end

    def handle_invite_user_exists(payload, group, email)
      user = ::User.find_by_email(email)

      unless user
        message = "Race condition: user could not be found"

        log_access(
          payload: payload,
          group: group,
          action: "invite_sent",
          status: "failed",
          message: message,
        )

        return render_error("Unexpected state during invite", :internal_server_error)
      end

      add_user_to_group(payload, group, user)
    end

    def handle_refund(payload, group)
      email = normalize_email(payload["email"])

      user = ::User.find_by_email(email)

      if user
        remove_user_from_group(payload, group, user)
      else
        revoke_pending_invite(payload, group, email)
      end
    end

    def remove_user_from_group(payload, group, user)
      group.remove(user)

      log_access(payload: payload, group: group, action: "removed_from_group", status: "success")

      mark_processed(payload)

      render_success("User #{user.username} removed from group #{group.name}")
    rescue StandardError => e
      log_access(
        payload: payload,
        group: group,
        action: "removed_from_group",
        status: "failed",
        message: e.message,
      )

      render_error("Failed to remove user from group: #{e.message}", :internal_server_error)
    end

    def revoke_pending_invite(payload, group, email)
      matching_invites =
        find_pending_invites(email).select { |invite| invite.groups.exists?(id: group.id) }

      if matching_invites.empty?
        message = "No user or pending invite found for this group"

        log_access(
          payload: payload,
          group: group,
          action: "no_action_needed",
          status: "success",
          message: message,
        )

        mark_processed(payload)

        return render_success("No user or pending invite found — nothing to revoke")
      end

      matching_invites.each do |invite|
        invite.groups.delete(group)

        invite.destroy! if invite.groups.empty?
      end

      log_access(payload: payload, group: group, action: "invite_revoked", status: "success")

      mark_processed(payload)

      render_success("Pending invite revoked for group #{group.name}")
    rescue StandardError => e
      log_access(
        payload: payload,
        group: group,
        action: "invite_revoked",
        status: "failed",
        message: e.message,
      )

      render_error("Failed to revoke invite: #{e.message}", :internal_server_error)
    end

    def find_pending_invite(email)
      find_pending_invites(email).first
    end

    def find_pending_invites(email)
      ::Invite
        .where(email: email)
        .where(deleted_at: nil)
        .where(invalidated_at: nil)
        .where("expires_at > ?", Time.zone.now)
        .where("redemption_count < max_redemptions_allowed")
        .order(created_at: :desc)
    end

    def normalize_email(email)
      ::Email.downcase(email.to_s.strip)
    end

    def mark_processed(payload)
      ProcessedEvent.create!(
        webhook_id: payload["webhookId"].to_s,
        event_type: payload["event"].to_s,
        order_id: payload["orderId"].to_s,
        product_id: payload["productId"].to_s,
        email: normalize_email(payload["email"]),
      )
    rescue ActiveRecord::RecordNotUnique
      # The unique database index on webhook_id protects
      # against duplicate inserts from concurrent requests.
      nil
    end

    def log_access(payload:, group:, action:, status:, message: nil)
      AccessLog.create!(
        webhook_id: payload["webhookId"].to_s,
        event_type: payload["event"].to_s,
        order_id: payload["orderId"].to_s,
        product_id: payload["productId"].to_s,
        email: normalize_email(payload["email"]),
        group_name: group&.name,
        action: action,
        status: status,
        message: message,
      )
    rescue StandardError => e
      Rails.logger.error("[BrandMe] Failed to create access log: #{e.class}: #{e.message}")
    end

    def render_success(message)
      render(json: { status: "success", message: message })
    end

    def render_error(message, status)
      render(json: { status: "error", message: message }, status: status)
    end
  end
end
