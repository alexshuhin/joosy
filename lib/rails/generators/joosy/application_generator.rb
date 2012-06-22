require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class ApplicationGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        template "app.js.coffee", "#{file_path}.js.coffee"

        empty_directory file_path

        template "app/routes.js.coffee", "#{file_path}/routes.js.coffee"
        template "app/railties.js.coffee.erb", "#{file_path}/railties.js.coffee.erb"

        empty_directory "#{file_path}/helpers"
        template "app/helpers/application.js.coffee", "#{file_path}/helpers/application.js.coffee"

        empty_directory "#{file_path}/layouts"
        template "app/layouts/application.js.coffee", "#{file_path}/layouts/application.js.coffee"

        # empty_directory "#{file_path}/pages/welcome"
        template "app/pages/application.js.coffee", "#{file_path}/pages/application.js.coffee"
        # template "app/pages/welcome/index.js.coffee", "#{file_path}/pages/welcome/index.js.coffee"

        empty_directory "#{file_path}/templates/layouts"
        template "app/templates/layouts/application.jst.hamlc", "#{file_path}/templates/layouts/application.jst.hamlc"

        empty_directory_with_gitkeep "#{file_path}/templates/pages"
        # empty_directory "#{file_path}/templates/pages/welcome"
        # template "app/templates/pages/welcome/index.jst.hamlc", "#{file_path}/templates/pages/welcome/index.jst.hamlc"

        empty_directory_with_gitkeep "#{file_path}/widgets"
        empty_directory_with_gitkeep "#{file_path}/resources"

        empty_directory_with_gitkeep "#{file_path}/templates/layouts"
        empty_directory_with_gitkeep "#{file_path}/templates/widgets"
      end
    end
  end
end