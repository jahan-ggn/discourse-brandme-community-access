# frozen_string_literal: true

DiscourseBrandmeCommunityAccess::Engine.routes.draw { post "/access" => "access#create" }

Discourse::Application.routes.draw do
  mount ::DiscourseBrandmeCommunityAccess::Engine, at: "brandme"
end
