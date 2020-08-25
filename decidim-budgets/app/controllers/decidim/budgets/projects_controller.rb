# frozen_string_literal: true

module Decidim
  module Budgets
    # Exposes the project resource so users can view them
    class ProjectsController < Decidim::Budgets::ApplicationController
      include FilterResource
      include NeedsCurrentOrder
      include Orderable
      include Decidim::Budgets::Orderable

      helper_method :projects, :project

      private

      def projects
        return @projects if @projects

        @projects = search.results.page(params[:page]).per(current_component.settings.projects_per_page)
        @projects = reorder(@projects)
      end

      def project
        @project ||= search.results.find(params[:id])
      end

      def search_klass
        ProjectSearch
      end

      def default_filter_params
        {
          search_text: "",
          scope_id: default_filter_scope_params,
          category_id: default_filter_category_params
        }
      end
    end
  end
end
