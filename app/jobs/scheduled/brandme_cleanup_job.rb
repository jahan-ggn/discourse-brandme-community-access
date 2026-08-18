# frozen_string_literal: true

module Jobs
  class BrandmeCleanupJob < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      return unless SiteSetting.discourse_brandme_community_access_enabled

      cutoff = 30.days.ago

      DiscourseBrandmeCommunityAccess::ProcessedEvent.where("created_at < ?", cutoff).delete_all
      DiscourseBrandmeCommunityAccess::AccessLog.where("created_at < ?", cutoff).delete_all

      Rails.logger.info("[BrandMe] Cleaned up records older than #{cutoff}")
    end
  end
end
