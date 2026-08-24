# frozen_string_literal: true

DiscourseBrandmeCommunityAccess::Engine.routes.draw do
  post "/access" => "access#create"
  get "/health" => "access#health"
end

Discourse::Application.routes.draw do
  mount ::DiscourseBrandmeCommunityAccess::Engine, at: "brandme"
end
