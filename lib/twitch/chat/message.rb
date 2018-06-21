module Twitch
  module Chat
    class Message
      attr_reader :type, :message, :user, :params, :command, :raw, :prefix, :error, :channel, :target, :userParams
      
      def initialize(msg)
        @raw = msg
        @userParams={}
        uUserParams,@prefix,@command,raw_params=msg.match(/(?:^)(?:@(\S+) )?(?::(\S+) )?(\S+)(.*)/).captures.last(4)
        if(!uUserParams.nil?)
          uUserParams.split(";").each{|param|
            key,value=param.split("=")
            @userParams[key]=value
          }
        end
        @params = parse_params(raw_params)
        @user = parse_user
        @channel = parse_channel
        @target  = @channel || @user
        @error = parse_error
        @message = parse_message
        @type = parse_type
      end

      def error?
        !@error.nil?
      end

      def numeric_reply?
        !!@command.match(/^\d{3}$/)
      end

    private

      def parse_params(raw_params)
        raw_params = raw_params.strip

        params     = []
        if match = raw_params.match(/(?:^:| :)(.*)$/)
          params = match.pre_match.split(" ")
          params << match[1]
        else
          params = raw_params.split(" ")
        end

        params
      end

      def parse_user
        return unless @prefix
        nick = @prefix[/^(\S+)!/, 1]

        return nil if nick.nil?
        nick
      end

      def parse_channel
        if @params.first.to_s.start_with?('#')
          @params.first.gsub('#', '')
        end
      end

      def parse_error
        @command.to_i if numeric_reply? && @command[/[45]\d\d/]
      end

      def parse_message
        if error?
          @error.to_s
        elsif regular_command?
          @params.last
        end
      end

      def numeric_reply?
        !!@command.match(/^\d{3}$/)
      end

      def regular_command?
        !numeric_reply?
      end
      def to_s
        return @message
      end
      def parse_type
        case @command
          when 'PRIVMSG'
            :message
          when 'MODE' then :mode
          when 'PING' then :ping
          when 'NOTICE'
            if @params.last == 'Login unsuccessful'
              :login_unsuccessful
            end
            case @userParams["msg_id"]
              when /slow_on/ then :slow_mode
              when /slow_off/ then :slow_mode_off
              when /r9k_on/ then :r9k_mode
              when /r9k_off/ then :r9k_mode_off
              when /emote_only_on/ then :emote_only_mode
              when /emote_only_off/ then :emote_only_mode_off
            end
          else :not_supported
        end
      end
    end
  end
end
