# frozen_string_literal: true

module Decidim
  module Budgets
    # This class handles search and filtering of projects. Needs a
    # `current_component` param with a `Decidim::Component` in order to
    # find the projects.
    class ProjectSearch < ResourceSearch
      text_search_fields :title, :description

      # Public: Initializes the service.
      # component     - A Decidim::Component to get the projects from.
      def initialize(options = {})
        super(Project.all, options)
      end

      # Returns the random projects for the current page.
      def results
        Project.where(id: super.pluck(:id)).includes([:scope, :component, :attachments, :category])
      end
    end
  end
end
