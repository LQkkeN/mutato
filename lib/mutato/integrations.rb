# frozen_string_literal: true

require_relative "integrations/active_record"

module Mutato
  # The database libraries' fork safety, as built-in hooks: a child must not share a socket.
  module Integrations
    module_function

    def install
      Mutato.before_fork { before_fork }
      Mutato.after_fork { after_fork }
    end

    # The classes, not the namespaces: a gem may define ActiveRecord without its Base.
    def before_fork
      ::Sequel::DATABASES.each(&:disconnect) if defined?(::Sequel::DATABASES)
      ActiveRecord.before_fork if defined?(::ActiveRecord::Base)
    end

    def after_fork
      ActiveRecord.after_fork if defined?(::ActiveRecord::Base)
    end
  end
end
