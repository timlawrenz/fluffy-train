class AddAiPromptToClusters < ActiveRecord::Migration[8.0]
  def change
    add_column :clusters, :ai_prompt, :text
  end
end
