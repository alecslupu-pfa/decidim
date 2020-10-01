# frozen_string_literal: true

module Decidim
  module Meetings
    module Admin
      # This command is executed when the user changes a Meeting from the admin
      # panel.
      class UpdateMeeting < Rectify::Command
        # Initializes a UpdateMeeting Command.
        #
        # form - The form from which to get the data.
        # meeting - The current instance of the page to be updated.
        def initialize(form, meeting)
          @form = form
          @meeting = meeting
        end

        # Updates the meeting if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if form.invalid?

          transaction do
            update_meeting!
            send_notification if should_notify_followers?
            schedule_upcoming_meeting_notification if start_time_changed?
            update_services!
          end

          broadcast(:ok, meeting)
        end

        private

        attr_reader :form, :meeting

        def update_meeting!
          parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.title, current_organization: form.current_organization).rewrite
          parsed_description = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.description, current_organization: form.current_organization).rewrite

          Decidim.traceability.update!(
            meeting,
            form.current_user,
            scope: form.scope,
            category: form.category,
            title: parsed_title,
            description: parsed_description,
            type_of_meeting: form.type_of_meeting,
            end_time: form.end_time,
            start_time: form.start_time,
            online_meeting_link: form.online_meeting_link,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            location: form.location,
            location_hints: form.location_hints,
            registration_type: form.registration_type,
            registration_terms: form.registration_terms,
            available_slots: form.available_slots,
            external_registration_system_link: form.external_registration_system_link,
            private_meeting: form.private_meeting,
            transparent: form.transparent,
            terms_and_conditions: form.terms_and_conditions
          )
        end

        def update_services!
          meeting.services = form.services_to_persist.map do |service|
            Decidim::Meetings::Service.new("title" => service.title, "description" => service.description)
          end
          meeting.save!
        end

        def send_notification
          Decidim::EventsManager.publish(
            event: "decidim.events.meetings.meeting_updated",
            event_class: Decidim::Meetings::UpdateMeetingEvent,
            resource: meeting,
            followers: meeting.followers
          )
        end

        def should_notify_followers?
          important_attributes.any? { |attr| meeting.previous_changes[attr].present? }
        end

        def important_attributes
          %w(start_time end_time address)
        end

        def start_time_changed?
          meeting.previous_changes["start_time"].present?
        end

        def schedule_upcoming_meeting_notification
          checksum = Decidim::Meetings::UpcomingMeetingNotificationJob.generate_checksum(meeting)

          Decidim::Meetings::UpcomingMeetingNotificationJob
            .set(wait_until: meeting.start_time - 2.days)
            .perform_later(meeting.id, checksum)
        end
      end
    end
  end
end
