# frozen_string_literal: true

module Decidim
  module Meetings
    # This class handles search and filtering of meetings. Needs a
    # `current_component` param with a `Decidim::Component` in order to
    # find the meetings.
    class MeetingSearch < ResourceSearch
      text_search_fields :title, :description

      # Public: Initializes the service.
      # component     - A Decidim::Component to get the meetings from.
      # page        - The page number to paginate the results.
      # per_page    - The number of proposals to return per page.
      def initialize(options = {})
        scope = options.fetch(:scope, Meeting.all)
        super(scope, options)
      end

      # Handle the meeting_type filter
      def search_meeting_type
        online = [options[:meeting_type]].flatten.member?("online") ? query.online : nil
        in_person = [options[:meeting_type]].flatten.member?("in_person") ? query.in_person : nil

        query
          .where(id: online)
          .or(query.where(id: in_person))
      end

      # Handle the search_text filter
      def search_search_text
        query
          .where(localized_search_text_in(:title), text: "%#{search_text}%")
          .or(query.where(localized_search_text_in(:description), text: "%#{search_text}%"))
      end

      # Handle the date filter
      def search_date
        apply_scopes(%w(upcoming past), date)
      end

      def search_space
        return query if options[:space].blank? || options[:space] == "all"

        query.joins(:component).where(decidim_components: { participatory_space_type: options[:space].classify })
      end
    end
  end
end
