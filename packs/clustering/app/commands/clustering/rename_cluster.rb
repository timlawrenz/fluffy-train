# frozen_string_literal: true

module Clustering
  class RenameCluster < GLCommand::Callable
    include ActiveModel::Validations

    validates :cluster_id, presence: true
    validates :new_name, presence: true

    requires :cluster_id, :new_name
    returns :message

    def call
      return unless valid?

      cluster = find_cluster
      return if cluster.nil?

      cluster.update!(name: new_name)
      context.message = "Successfully renamed cluster #{cluster_id} to '#{new_name}'"
    end

    private

    def find_cluster
      cluster = Clustering::Cluster.find_by(id: cluster_id)
      if cluster.nil?
        stop_and_fail!('Cluster not found')
        return nil
      end
      cluster
    end
  end
end
