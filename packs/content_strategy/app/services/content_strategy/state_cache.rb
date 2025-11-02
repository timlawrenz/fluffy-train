module ContentStrategy
  class StateCache
    CACHE_EXPIRES_IN = 5.minutes

    class << self
      def get(persona_id)
        Rails.cache.fetch(cache_key(persona_id), expires_in: CACHE_EXPIRES_IN) do
          StrategyState.find_by(persona_id: persona_id)
        end
      end

      def set(persona_id, state)
        Rails.cache.write(cache_key(persona_id), state, expires_in: CACHE_EXPIRES_IN)
      end

      def invalidate(persona_id)
        Rails.cache.delete(cache_key(persona_id))
      end

      def invalidate_all
        Rails.cache.delete_matched("content_strategy:state:*")
      end

      private

      def cache_key(persona_id)
        "content_strategy:state:#{persona_id}"
      end
    end
  end
end
