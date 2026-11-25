# frozen_string_literal: true

module Projects
  class ListService
    class InvalidDateRange < StandardError; end

    PROJECT_STATUSES = %w[
      順調
      リスクあり
      要対応
      保留中
      完了
    ].freeze

    SORT_OPTIONS = %w[
      updated_at
      due_date
      name
    ].freeze

    PER_PAGE = 20

    def self.call(team:, filters: {})
      new(team:, filters:).call
    end

    def initialize(team:, filters:)
      @team = team
      @filters = filters.to_h.symbolize_keys
    end

    def call
      projects = @team.projects
                      .where(archived_at: nil)
                      .includes(assignee_membership: :user)

      projects = filter_by_keyword(projects)
      projects = filter_by_status(projects)
      projects = filter_by_assignee(projects)
      projects = filter_by_due_date(projects)

      apply_sort(projects)
    end

    private

    def filter_by_keyword(projects)
      keyword = @filters[:keyword].to_s.strip
      return projects if keyword.blank?

      projects.where("projects.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(keyword)}%")
    end

    def filter_by_status(projects)
      status = @filters[:status].to_s
      return projects if status.blank?

      return projects.none unless PROJECT_STATUSES.include?(status)

      projects.where(status:)
    end

    def filter_by_assignee(projects)
      assignee_id = @filters[:assignee_id].to_s
      return projects if assignee_id.blank?

      return projects.where(assignee_membership_id: nil) if assignee_id == "unassigned"

      return projects.none unless assignee_id.match?(/\A\d+\z/)

      projects.where(assignee_membership_id: assignee_id)
    end

    def filter_by_due_date(projects)
      from = parse_date(@filters[:due_date_from])
      to = parse_date(@filters[:due_date_to])

      raise InvalidDateRange, "期限の開始日は終了日以前の日付を指定してください。" if from && to && from > to

      projects = projects.where("projects.due_date >= ?", from) if from
      projects = projects.where("projects.due_date <= ?", to) if to

      projects
    end

    def parse_date(value)
      return if value.blank?

      Date.iso8601(value.to_s)
    rescue Date::Error
      raise InvalidDateRange, "期限の日付が正しくありません。"
    end

    def apply_sort(projects)
      case @filters[:sort].to_s
      when "due_date"
        projects.order(Arel.sql("projects.due_date ASC NULLS LAST"), id: :asc)
      when "name"
        projects.order(name: :asc, id: :asc)
      else
        projects.order(updated_at: :desc, id: :asc)
      end
    end
  end
end
