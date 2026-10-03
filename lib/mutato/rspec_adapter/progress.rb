# frozen_string_literal: true

module Mutato
  module RSpecAdapter
    class Progress
      attr_reader :ran, :current

      def initialize
        @ran = []
        @current = nil
      end

      def example_started(notification)
        @current = notification.example.id
        @ran << @current
      end
    end
    private_constant :Progress
  end
end
