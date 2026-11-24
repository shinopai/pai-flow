# frozen_string_literal: true

module Projects
  class RestoreService
    def self.call(project:)
      new(project:).call
    end

    def initialize(project:)
      @project = project
    end

    def call
      @project.with_lock do
        @project.update!(archived_at: nil) if @project.archived_at.present?
      end

      @project
    end
  end
end
