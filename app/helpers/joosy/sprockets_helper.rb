require 'uri'

module Joosy::SprocketsHelper
  def initialize_joosy(name)
    result  = javascript_tag(joosy_libraries name)
    result += javascript_tag(joosy_bootstrap) unless Rails.env.production?
    result
  end

  def joosy_libraries(name)
    libraries = extract_sources_and_sizes_from_include_tag(name).to_json.html_safe

    <<-eos
      window.joosy = {
        libraries: #{libraries}
      }
    eos
  end

  def joosy_bootstrap
    routes = Joosy::SprocketsHelper.routes.to_json.html_safe

    <<-eos
      window.joosy.routes = #{routes}
      window.joosy.environment = '#{Rails.env.to_s}'
    eos
  end

  def extract_sources_and_sizes_from_include_tag(name)
    code = javascript_include_tag name
    resources = code.scan(/(?:href|src)=['"]([^'"]+)['"]/).flatten

    resources.map do |resource|
      uri  = URI.parse resource
      path = ::Rails.root.to_s + "/public" + uri.path
      size = File.size(path) rescue 0
      [resource, size]
    end
  end

  def require_joosy_preloader_for(app_asset, options={})
    preloader_asset = "joosy/preloaders/#{options[:preloader]}"
    force_preloader = options[:force] || false

    if options[:preloader].blank? || options[:preloader] == 'inline'
      require_asset app_asset
    elsif force_preloader
      require_asset preloader_asset
    else
      require_asset Rails.env == 'development' ? app_asset : preloader_asset
    end
  end

  def self.resources(namespaces=nil)
    predefined = {}
    filtered_resources = Joosy::Rails::Engine.resources
    if namespaces
      namespaces = Array.wrap namespaces
      filtered_resources = filtered_resources.select{|key, _| namespaces.include? key }
    end
    filtered_resources.each do |namespace, resources|
      next unless resources && resources.size > 0
      joosy_namespace = namespace.to_s.camelize.split('::').join('.')
      predefined[joosy_namespace] = resources
    end
    predefined
  end

  def self.routes
    backend_routes = Rails.application.routes.routes.select do |x| 
      method = x.constraints[:request_method]
      source = x.app

      if 
        (!method.blank? && method != /^GET$/) ||
        (!source.is_a?(ActionDispatch::Routing::RouteSet::Dispatcher)) ||
        (!x.defaults.has_key?(:action) || !x.defaults.has_key?(:controller))
          false
      else
        true
      end
    end

    routes = Hash[backend_routes.map do |x|
      page = [x.defaults[:controller].camelize.gsub('::', '.'), x.defaults[:action].camelize]
      [x.path.spec.to_s.gsub('(.:format)', ''), page]
    end]
  end
end
