module Agents
  class PushbulletAgent < Agent
    cannot_be_scheduled!
    cannot_create_events!

    API_URL = 'https://api.pushbullet.com/v2/pushes'

    description <<-MD
      The Pushbullet agent sends pushes to a pushbullet device

      To authenticate you need to set the `api_key`, you can find yours at your account page:

      `https://www.pushbullet.com/account`

      Currently you need to get a the device identification manually:

      `curl -u <your api key here>: https://api.pushbullet.com/v2/devices`

      To register a new device run the following command:

      `curl -u <your api key here>: -X POST https://api.pushbullet.com/v2/devices -d nickname=huginn -d type=stream`

      Put one of the retured `iden` strings into the `device_id` field.

      You have to provide a message `type` which has to be `note`, `link`, or `address`. The message types `checklist`, and `file` are not supported at the moment.

      Depending on the message `type` you can use additional fields:

      * note: `title` and `body`
      * link: `title`, `body`, and `url`
      * address: `name`, and `address`

      In every value of the options hash you can use the liquid templating, learn more about it at the [Wiki](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid).
    MD

    def default_options
      {
        'api_key' => '',
        'device_id' => '',
        'title' => "{{title}}",
        'body' => '{{body}}',
        'type' => 'note',
      }
    end

    def validate_options
      errors.add(:base, "you need to specify a pushbullet api_key") if options['api_key'].blank?
      errors.add(:base, "you need to specify a device_id") if options['device_id'].blank?
      errors.add(:base, "you need to specify a valid message type") if options['type'].blank? or not ['note', 'link', 'address'].include?(options['type'])
    end

    def working?
      received_event_without_error?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        response = HTTParty.post API_URL, query_options(event)
        error(response.body) if response.body.include? 'error'
      end
    end

    private

    def query_options(event)
      mo = interpolated(event)
      body = {device_iden: mo[:device_id], type: mo[:type]}
      case mo[:type]
      when "note"
        body[:title] = mo[:title]
        body[:body] = mo[:body]
      when "link"
        body[:title] = mo[:title]
        body[:body] = mo[:body]
        body[:url] = mo[:url]
      when "address"
        body[:name] = mo[:name]
        body[:address] = mo[:address]
      end
      {
        :basic_auth => {:username => mo[:api_key], :password => ''},
        :body => body
      }
    end
  end
end
