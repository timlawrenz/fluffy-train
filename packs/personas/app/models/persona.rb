# frozen_string_literal: true

class Persona < ApplicationRecord
  has_many :photos, dependent: :destroy
  has_many :clusters, class_name: 'Clustering::Cluster', dependent: :restrict_with_error
  has_many :content_pillars, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validate :total_pillar_weight_valid

  def caption_config
    return nil if self[:caption_config].nil? || self[:caption_config].empty?
    @caption_config ||= Personas::CaptionConfig.from_hash(self[:caption_config])
  end

  def caption_config=(value)
    config = value.is_a?(Personas::CaptionConfig) ? value : Personas::CaptionConfig.new(value)
    raise ArgumentError, config.errors.join(', ') unless config.valid?
    
    self[:caption_config] = config.to_hash
    @caption_config = config
  end

  def hashtag_strategy
    return nil if self[:hashtag_strategy].nil? || self[:hashtag_strategy].empty?
    @hashtag_strategy ||= Personas::HashtagStrategy.from_hash(self[:hashtag_strategy])
  end

  def hashtag_strategy=(value)
    strategy = value.is_a?(Personas::HashtagStrategy) ? value : Personas::HashtagStrategy.new(value)
    raise ArgumentError, strategy.errors.join(', ') unless strategy.valid?
    
    self[:hashtag_strategy] = strategy.to_hash
    @hashtag_strategy = strategy
  end

  def pillar_weight_total
    content_pillars.active.sum(:weight)
  end

  private

  def total_pillar_weight_valid
    return unless persisted?
    return if pillar_weight_total <= 100

    errors.add(:base, "Total pillar weight cannot exceed 100% (current: #{pillar_weight_total}%)")
  end
end
