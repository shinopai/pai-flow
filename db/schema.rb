# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_09_013116) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "comments", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "team_membership_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_comments_on_task_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "invitee_id", null: false
    t.bigint "invited_by_id", null: false
    t.string "email", null: false
    t.string "status", null: false
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invitee_id"], name: "index_invitations_on_invitee_id"
    t.index ["team_id", "invitee_id"], name: "index_invitations_on_team_id_and_invitee_id", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["team_id"], name: "index_invitations_on_team_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'accepted'::character varying, 'declined'::character varying, 'cancelled'::character varying]::text[])", name: "check_invitations_status"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "created_by_id", null: false
    t.bigint "assignee_membership_id"
    t.string "name", null: false
    t.text "description"
    t.date "due_date"
    t.string "status", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_membership_id"], name: "index_projects_on_assignee_membership_id"
    t.index ["team_id", "assignee_membership_id"], name: "index_projects_on_team_id_and_assignee_membership_id"
    t.index ["team_id", "due_date"], name: "index_projects_on_team_id_and_due_date"
    t.index ["team_id", "name"], name: "index_projects_on_team_id_and_name"
    t.index ["team_id", "status"], name: "index_projects_on_team_id_and_status"
    t.index ["team_id", "updated_at"], name: "index_projects_on_team_id_and_updated_at"
    t.index ["team_id"], name: "index_projects_on_team_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "parent_task_id"
    t.bigint "created_by_id", null: false
    t.bigint "assignee_membership_id"
    t.string "title", null: false
    t.text "description"
    t.date "due_date"
    t.string "priority", null: false
    t.string "status", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_membership_id", "due_date"], name: "index_tasks_on_assignee_membership_id_and_due_date"
    t.index ["assignee_membership_id"], name: "index_tasks_on_assignee_membership_id"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["parent_task_id", "position"], name: "index_tasks_on_parent_task_id_and_position"
    t.index ["parent_task_id"], name: "index_tasks_on_parent_task_id"
    t.index ["project_id", "created_at"], name: "index_tasks_on_project_id_and_created_at"
    t.index ["project_id", "due_date"], name: "index_tasks_on_project_id_and_due_date"
    t.index ["project_id", "position"], name: "index_tasks_on_project_id_and_position"
    t.index ["project_id", "priority"], name: "index_tasks_on_project_id_and_priority"
    t.index ["project_id", "status"], name: "index_tasks_on_project_id_and_status"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.string "role", null: false
    t.string "status", null: false
    t.datetime "joined_at", null: false
    t.datetime "left_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["team_id"], name: "index_team_memberships_on_team_id", unique: true, where: "(((role)::text = 'owner'::text) AND ((status)::text = 'active'::text))"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying, 'member'::character varying, 'guest'::character varying]::text[])", name: "check_team_memberships_role"
    t.check_constraint "status::text = 'active'::text AND left_at IS NULL OR status::text = 'left'::text AND left_at IS NOT NULL", name: "check_team_memberships_status_left_at"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'left'::character varying]::text[])", name: "check_team_memberships_status"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "comments", "tasks", on_delete: :cascade
  add_foreign_key "comments", "team_memberships", on_delete: :restrict
  add_foreign_key "invitations", "teams", on_delete: :restrict
  add_foreign_key "invitations", "users", column: "invited_by_id", on_delete: :restrict
  add_foreign_key "invitations", "users", column: "invitee_id", on_delete: :restrict
  add_foreign_key "projects", "team_memberships", column: "assignee_membership_id", on_delete: :restrict
  add_foreign_key "projects", "teams", on_delete: :restrict
  add_foreign_key "projects", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "tasks", "projects", on_delete: :cascade
  add_foreign_key "tasks", "tasks", column: "parent_task_id", on_delete: :cascade
  add_foreign_key "tasks", "team_memberships", column: "assignee_membership_id", on_delete: :restrict
  add_foreign_key "tasks", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "team_memberships", "teams", on_delete: :restrict
  add_foreign_key "team_memberships", "users", on_delete: :restrict
end
