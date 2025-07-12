# This migration comes from solid_queue (originally 20240212143450)
class CreateSolidQueueTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_queue_jobs do |t|
      t.string :queue_name, null: false, index: true
      t.string :class_name, null: false, index: true
      t.text :arguments
      t.integer :priority, default: 0, null: false
      t.string :active_job_id, index: { unique: true }
      t.datetime :scheduled_at
      t.datetime :finished_at, index: true
      t.string :concurrency_key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :queue_name, :finished_at ], name: "index_solid_queue_jobs_for_filtering"
      t.index [ :scheduled_at, :finished_at ], name: "index_solid_queue_jobs_for_scheduling"
    end

    create_table :solid_queue_scheduled_executions do |t|
      t.references :job, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false, index: true
      t.datetime :created_at, null: false
    end

    create_table :solid_queue_ready_executions do |t|
      t.references :job, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :created_at, null: false

      t.index [ :priority, :job_id ], name: "index_solid_queue_ready_executions_on_priority_and_job_id"
    end

    create_table :solid_queue_claimed_executions do |t|
      t.references :job, index: { unique: true }
      t.bigint :process_id
      t.datetime :created_at, null: false

      t.index [ :process_id, :job_id ]
    end

    create_table :solid_queue_failed_executions do |t|
      t.references :job, index: { unique: true }
      t.text :error
      t.datetime :created_at, null: false
    end

    create_table :solid_queue_semaphores do |t|
      t.string :key, null: false, index: { unique: true }
      t.integer :value, default: 1, null: false
      t.datetime :expires_at, null: false, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    create_table :solid_queue_processes do |t|
      t.string :kind, null: false
      t.string :handler_name, null: false
      t.text :metadata
      t.integer :pid, null: false
      t.string :hostname
      t.datetime :created_at, null: false

      t.index :kind
    end

    create_table :solid_queue_pauses do |t|
      t.string :queue_name, null: false, index: { unique: true }
      t.datetime :created_at, null: false
    end

    add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
  end
end
