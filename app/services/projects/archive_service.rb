# frozen_string_literal: true

module Projects
  class ArchiveService
    def self.call(project:)
      new(project:).call
    end

    def initialize(project:)
      @project = project
    end

    def call
      @project.with_lock do
        @project.update!(archived_at: Time.current) if @project.archived_at.nil?
      end

      @project
    end
  end
end
