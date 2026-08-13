# frozen_string_literal: true

DiscourseBrandmeCommunityAccess::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::DiscourseBrandmeCommunityAccess::Engine, at: "discourse-brandme-community-access" }
