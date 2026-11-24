# frozen_string_literal: true

module Projects
  class DestroyService
    def self.call(project:)
      new(project:).call
    end

    def initialize(project:)
      @project = project
    end

    def call
      @project.with_lock do
        @project.destroy!
      end
    end
  end
end
