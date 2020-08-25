# frozen_string_literal: true

require "spec_helper"

module Decidim::Budgets
  describe ProjectSearch do
    subject { described_class.new(params).results }

    let(:component) { create :budget_component }
    let(:default_params) { { component: component } }
    let(:params) { default_params }

    it_behaves_like "a resource search", :project
    it_behaves_like "a resource search with scopes", :project
    it_behaves_like "a resource search with categories", :project
  end
end
