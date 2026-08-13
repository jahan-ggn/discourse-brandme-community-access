# frozen_string_literal: true

# name: discourse-brandme-community-access
# about: Grant and revoke Discourse group access based on Shopify product purchases and refunds.
# version: 0.0.1
# authors: Jahan Gagan
# url: http://github.com/jahan-ggn/discourse-brandme-community-access

enabled_site_setting :discourse_brandme_community_access_enabled

module ::DiscourseBrandmeCommunityAccess
  PLUGIN_NAME = "discourse-brandme-community-access"
end

require_relative "lib/discourse_brandme_community_access/engine"

after_initialize {}
