require 'erb'
require 'ostruct'
require 'json'

module Environment
  class UserDataFile
    RHEL_TEMPLATE = File.dirname(__FILE__) + '/templates/linux_user_data.erb'
    WIN_TEMPLATE = File.dirname(__FILE__) + '/templates/windows_user_data.erb'

    def initialize(os_type)
      if os_type == :rhel
        @template = File.read(RHEL_TEMPLATE)
      elsif os_type == :win
        @template = File.read(WIN_TEMPLATE)
      else
        @template = File.read(RHEL_TEMPLATE)
      end
    end

    def generate_from_write_to(variables_file, filename)
      variables_string = File.read(variables_file)

      vars = JSON.parse(variables_string)
      File.open(filename, 'w') do |f|
        f.write UserDataRenderer.render(@template, vars)
      end
    end

    class UserDataRenderer < OpenStruct
      def self.render(t, h)
        UserDataRenderer.new(h)._render(t)
      end

      def _render(template)
        ERB.new(template).result(binding)
      end
    end
  end
end