# frozen_string_literal: true

module SuperAgent
  module Workflow
    # Immutable context object for passing state between workflow tasks
    class Context
      attr_reader :private_keys

      def initialize(initial_data = {}, private_keys: [], **kwargs)
        data = initial_data.is_a?(Hash) ? initial_data.merge(kwargs) : kwargs
        @data = data.transform_keys(&:to_sym)
        @private_keys = Array(private_keys).map(&:to_sym)
      end

      # Get a value from the context
      def get(key)
        @data[key.to_sym]
      end

      # Set a value in the context, returning a new immutable instance
      def set(key, value)
        new_data = @data.dup
        new_data[key.to_sym] = value
        self.class.new(new_data, private_keys: @private_keys)
      end

      # Set multiple values at once, returning a new immutable instance
      def merge(new_data)
        merged_data = @data.merge(new_data.transform_keys(&:to_sym))
        self.class.new(merged_data, private_keys: @private_keys)
      end

      # Filter sensitive data for logging
      def filtered_for_logging
        filtered_data = @data.dup
        
        @private_keys.each do |key|
          filtered_data[key] = '[FILTERED]' if filtered_data.key?(key)
        end
        
        filtered_data
      end

      # Get all keys in the context
      def keys
        @data.keys
      end

      # Check if context is empty
      def empty?
        @data.empty?
      end

      # Convert to hash
      def to_h
        @data.dup
      end

      # Check if a key exists
      def key?(key)
        @data.key?(key.to_sym)
      end
    end
  end
end