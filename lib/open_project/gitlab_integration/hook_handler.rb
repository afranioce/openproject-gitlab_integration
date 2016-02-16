module OpenProject::GitlabIntegration
  class HookHandler
    # List of the gitlab events we can handle.
    KNOWN_EVENTS = {'Push Hook' => 'push', 'Note Hook' => 'note', 'Merge Request Hook' => 'merge_request'}

    # A gitlab webhook happened.
    # We need to check validity of the data and send a Notification
    # which we process in our NotificationHandler.
    def process(hook, environment, params, user)
      event_type = environment['HTTP_X_GILAB_EVENT']

      Rails.logger.debug "Received gitlab webhook: #{event_type}"

      KNOWN_EVENTS['push']

      return 404 unless KNOWN_EVENTS.include?(event_type)
      return 403 unless user.present?

      payload = Hash.new
      payload.merge! params.require('webhook')
      payload.merge! 'user_id' => user.id,
                     'gitlab_event' => event_type,
                     'gitlab_object_kind' => KNOWN_EVENTS[event_type]

      OpenProject::Notifications.send(event_object_kind(event_type), payload)

      return 200
    end

    # gitlab_object_kind: 'push' | 'note' | 'merge_request'
    private def event_object_kind(gitlab_object_kind)
      "gitlab.#{KNOWN_EVENTS[gitlab_object_kind]}"
    end
  end
end