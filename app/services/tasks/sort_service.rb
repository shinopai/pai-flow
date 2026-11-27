# frozen_string_literal: true

module Tasks
  class SortService
    SORT_ORDERS = {
      "manual" => lambda { |relation|
        relation.order(position: :asc)
      },
      "due_date" => lambda { |relation|
        relation.order(
          Arel.sql("due_date ASC NULLS LAST"),
          position: :asc
        )
      },
      "priority" => lambda { |relation|
        relation.order(
          Arel.sql(
            "CASE priority " \
            "WHEN 'high' THEN 0 " \
            "WHEN 'medium' THEN 1 " \
            "WHEN 'low' THEN 2 " \
            "ELSE 3 END ASC"
          ),
          position: :asc
        )
      },
      "status" => lambda { |relation|
        relation.order(
          Arel.sql(
            "CASE status " \
            "WHEN 'not_started' THEN 0 " \
            "WHEN 'in_progress' THEN 1 " \
            "WHEN 'completed' THEN 2 " \
            "ELSE 3 END ASC"
          ),
          position: :asc
        )
      },
      "created_at" => lambda { |relation|
        relation.order(created_at: :desc, position: :asc)
      }
    }.freeze

    def self.call(project:, sort_by: nil, parent_task_id: nil)
      new(
        project: project,
        sort_by: sort_by,
        parent_task_id: parent_task_id
      ).call
    end

    def initialize(project:, sort_by:, parent_task_id:)
      @project = project
      @sort_by = sort_by
      @parent_task_id = parent_task_id
    end

    def call
      find_parent_task! if @parent_task_id.present?

      relation = @project.tasks.where(parent_task_id: @parent_task_id)
      sort_order = SORT_ORDERS.fetch(@sort_by.to_s, SORT_ORDERS["manual"])

      sort_order.call(relation)
    end

    private

    def find_parent_task!
      @project.tasks
              .where(parent_task_id: nil)
              .find(@parent_task_id)
    end
  end
end
