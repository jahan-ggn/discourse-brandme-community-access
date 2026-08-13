# frozen_string_literal: true

# name: discourse-brandme-community-access
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_brandme_community_access_enabled

module ::DiscourseBrandmeCommunityAccess
  PLUGIN_NAME = "discourse-brandme-community-access"
end

require_relative "lib/discourse_brandme_community_access/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
