require "json"

module KBSecret
  module Record
    # Represents an abstract kbsecret record that can be subclassed to produce
    # more useful records.
    # @abstract
    class Abstract
      attr_accessor :session
      attr_reader :timestamp
      attr_reader :label
      attr_reader :type
      attr_reader :data

      # @return [String] the record's type
      # @example
      #  KBSecret::Record::Abstract.type # => "abstract"
      def self.type
        name.split("::").last.downcase
      end

      # Load the given hash-representation into a record.
      # @param session [Session] the session to associate with
      # @param hsh [Hash] the record's hash-representation
      # @return [Record::AbstractRecord] the created record
      # @api private
      def self.load!(session, hsh)
        instance = allocate
        instance.session = session
        instance.initialize_from_hash(hsh)

        instance
      end

      # Create a brand new record, associated with a session.
      # @param session [Session] the session to associate with
      # @param label [Symbol] the new record's label
      # @note Creation does *not* sync the new record; see {#sync!} for that.
      def initialize(session, label)
        @session = session
        @timestamp = Time.now.to_i
        @label = label
        @type = self.class.type
        @data = {}
      end

      # Fill in instance fields from a record's hash-representation.
      # @param hsh [Hash] the record's hash-representation.
      # @return [void]
      # @api private
      def initialize_from_hash(hsh)
        @timestamp = hsh[:timestamp]
        @label = hsh[:label]
        @type = hsh[:type]
        @data = hsh[:data]
      end

      # The fully qualified path to the record's file.
      # @return [String] the path
      # @note If the record hasn't been synced to disk, this path may not
      #  exist yet.
      def path
        File.join(session.directory, "#{label}.json")
      end

      # Create a hash-representation of the current record.
      # @return [Hash] the hash-representation
      def to_h
        {
          timestamp: timestamp,
          label: label,
          type: type,
          data: data,
        }
      end

      # Write the record's in-memory state to disk.
      # @note Every sync updates the record's timestamp.
      # @return [void]
      def sync!
        # bump the timestamp every time we sync
        @timestamp = Time.now.to_i

        File.write(path, JSON.pretty_generate(to_h))
      end
    end
  end
end
