# frozen_string_literal: true

module HashtagGenerations
  # Maps detected objects from photo analysis to relevant Instagram hashtags
  class ObjectMapper
    # Comprehensive mapping of detected objects to contextual hashtags
    OBJECT_MAPPINGS = {
      # Nature & Landscapes
      'sunset' => %w[#GoldenHour #SunsetLovers #SunsetPhotography #Dusk #EveningVibes],
      'sunrise' => %w[#GoldenHour #SunriseLovers #MorningLight #Dawn #NewDay],
      'mountain' => %w[#MountainLife #MountainView #PeakViews #MountainLovers #Summit],
      'sky' => %w[#SkyLovers #SkyPhotography #Skyline #BlueSky #Skies],
      'cloud' => %w[#CloudPorn #Cloudscape #SkyScape #DramaticSky],
      'tree' => %w[#TreeLovers #ForestLife #NatureLovers #Woodland],
      'forest' => %w[#ForestWalk #IntoTheWild #Woodland #Trees #NatureTrail],
      'water' => %w[#WaterReflections #LakeLife #OceanVibes #WaterPhotography],
      'ocean' => %w[#OceanVibes #SeaLife #BeachVibes #CoastalLiving #BlueWater],
      'beach' => %w[#BeachLife #CoastalVibes #SandyToes #BeachDay #Seaside],
      'flower' => %w[#FlowerPower #BotanicalBeauty #BloomWhere #FloralPhotography],
      
      # Urban & Architecture
      'building' => %w[#ArchitectureLovers #UrbanPhotography #CityScape #ModernArchitecture],
      'city' => %w[#CityLife #UrbanExplorer #CityVibes #StreetPhotography #Cityscape],
      'street' => %w[#StreetLife #UrbanStreets #CityWalking #StreetView],
      'architecture' => %w[#ArchitecturalPhotography #BuildingDesign #ArchitectureLovers],
      'bridge' => %w[#BridgePhotography #EngineeringMarvel #UrbanLandmark],
      'window' => %w[#WindowView #UrbanDetails #ArchitecturalDetails],
      
      # People & Lifestyle
      'person' => %w[#PortraitPhotography #PeoplePhotography #HumanConnection #Lifestyle],
      'woman' => %w[#WomenPortrait #FemalePhotography #PortraitMood #StyleInspo],
      'face' => %w[#FacePhotography #PortraitMode #HumanBeauty #Expression],
      'smile' => %w[#HappyMoments #SmileMore #JoyfulMoments #GoodVibes],
      
      # Food & Drink
      'food' => %w[#FoodPhotography #Foodie #FoodLovers #Yummy #FoodPorn],
      'coffee' => %w[#CoffeeLovers #CoffeeTime #CoffeeAddict #ButFirstCoffee #CoffeeCulture],
      'drink' => %w[#DrinkUp #BeveragePhotography #RefreshingDrinks],
      
      # Objects & Details
      'car' => %w[#CarPhotography #AutoLovers #VehiclePhotography #RideOrDie],
      'book' => %w[#BookLovers #Reading #BookPhotography #Bookstagram],
      'camera' => %w[#Photography #PhotographyLovers #CameraGear #ShootAndShare],
      'phone' => %w[#TechLife #MobilePhotography #DigitalLife],
      
      # Animals
      'dog' => %w[#DogsOfInstagram #DogLovers #PuppyLove #DogPhotography],
      'cat' => %w[#CatsOfInstagram #CatLovers #Meow #CatPhotography],
      'bird' => %w[#BirdPhotography #BirdWatching #WildlifePhotography #AvianBeauty],
      'animal' => %w[#AnimalLovers #WildlifePhotography #AnimalPhotography #Nature]
    }.freeze

    def self.map_objects(detected_objects)
      new(detected_objects).map_objects
    end

    def initialize(detected_objects)
      @detected_objects = detected_objects || []
    end

    def map_objects
      tags = []
      
      @detected_objects.each do |obj|
        label = obj.is_a?(Hash) ? obj['label'] : obj.to_s
        label_key = label.downcase.gsub(/[^a-z]/, '')
        
        if OBJECT_MAPPINGS.key?(label_key)
          tags.concat(OBJECT_MAPPINGS[label_key])
        end
      end
      
      tags.uniq
    end

    # Get tags for a specific category
    def self.tags_for_category(category)
      OBJECT_MAPPINGS[category.to_s.downcase] || []
    end

    # Check if we have mappings for an object
    def self.has_mapping?(object)
      OBJECT_MAPPINGS.key?(object.to_s.downcase.gsub(/[^a-z]/, ''))
    end
  end
end
