class AddCaptionConfigToPersonas < ActiveRecord::Migration[8.0]
  def change
    add_column :personas, :caption_config, :jsonb, default: {}
  end
end
