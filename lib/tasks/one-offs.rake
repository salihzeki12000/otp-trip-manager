#encoding: utf-8
namespace :oneclick do
  namespace :one_offs do

    desc "Associate Shapefile Boundaries with Services"
    task :add_boundaries => :environment do
      #Delete all polygon-based boundaries
      gcs = GeoCoverage.where(coverage_type: 'polygon')
      gcs.each do |gc|
        gc.service_coverage_maps.destroy_all
        gc.delete
      end

      Boundary.all.each do |b|
        gc = GeoCoverage.new(value: b.agency, coverage_type: 'polygon', polygon: b)
        case b.agency
        when "Cobb Community Transit (CCT)"
          service = Service.find_by_external_id("54104859570670229999")
          ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'endpoint_area')
          ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'coverage_area')
        when "Cherokee Area Transportation System (CATS)"
          service = Service.find_by_external_id("32138199527497131111")
          ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'endpoint_area')
          ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'coverage_area')
          #when "Gwinnett County Transit (GCT)"
          #when "Metropolitan Atlanta Rapid Transit Authority"
        end
      end
    end

    task :add_manual_boundaries => :environment do
      z = Zipcode.find_by_zipcode('30309')
      s = Service.find(11)
      s.origin = z.geom
      s.save

      myArray = []
      z.geom.each do |polygon|
        polygon_array = []
        ring_array  = []
        polygon.exterior_ring.points.each do |point|
          ring_array << [point.y, point.x]
        end
        polygon_array < ring_array

        polygon.interior_rings.each do |ring|
          ring_array = []
          ring.each do |point|
            ring_array << [point.y, point.x]
          end
          polygon_array << ring_array
        end
        myArray << polygon_array
      end



    end

    task migrate_comments: :environment do
      [Agency, Provider, Service].each do |commentable_type|
        puts "Migrating #{commentable_type} comments..."
        %w{public private}.each do |visibility|
          puts "...#{visibility}"
          old_field = "#{visibility}_comments_old".to_sym
          method = "#{visibility}_comments".to_sym
          commentable_type.where.not(old_field => nil).each do |c|
            puts ">> #{c.name}"
            c.send(method).create! comment: c.send(old_field), locale: 'en', visibility: visibility
          end
        end
      end
    end

    task set_mode_priority: :environment do
      [['mode_bicycle', 1], ['mode_transit', 2], ['mode_walk', 3], ['mode_park_transit',4], ['mode_bicycle_transit', 0]].each do |m|
        mode = Mode.unscoped.find_by(code: m[0])
        if mode
          puts "Setting #{m[0]} to priority #{m[1]}."
          mode.results_sort_order = m[1]
          mode.active = true
          mode.save
        end
      end
    end

    desc "Create API Guest User"
    task create_api_guest: :environment do

      user = User.find_or_create_by(api_guest: true) do |api_guest|
        api_guest.first_name = "API"
        api_guest.last_name = "Guest"
        api_guest.email = "APIGuest@camsys.com"
        new_password = SecureRandom.hex
        api_guest.password = new_password
        api_guest.password_confirmation = new_password
      end

      user.save

    end

  end

end
