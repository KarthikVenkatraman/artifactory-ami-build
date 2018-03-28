require 'rake'
require 'rspec/core/rake_task'

namespace 'test' do

  # Dynamically create tasks for serverspec role tests.

  roles = []

  Dir.glob('spec/*').each do |dir|
    roles << File.basename(dir) if File.directory?(dir)
  end

  roles.each do |role|
    desc "run #{role} tests"
    RSpec::Core::RakeTask.new("#{role.to_sym}") do |t|
      t.pattern = "spec/#{role}/*_spec.rb"
    end
  end

  desc 'run all tests'
  task :all => roles

  desc 'run cis-cat on windows instance'
  task :win_cis_cat, [:target_host, :username, :password, :benchmark, :profile, :options] do |t, args|
    require 'winrm'
    require 'winrm-fs'

    user = args[:username]
    password = args[:password]
    target_host = args[:target_host]
    benchmark = args[:benchmark]
    profile = args[:profile]
    options = args[:options]

    opts = {
      user: user,
      password: password,
      endpoint: "http://#{target_host}:5985/wsman",
      operation_timeout: 300,
      transport: :negotiate,
      basic_auth_only: true
    }

    winrm = WinRM::Connection.new(opts)
    winrm.logger.level = :error
    winrm.shell(:powershell) do |shell|
      output = shell.run("C:/Aviva/cis-cat-full/CIS-CAT.bat #{options} --benchmark #{benchmark} --profile #{profile} --results-dir 'C:/Aviva/' --report-name 'cis-cat-report' --report-txt") do |stdout, stderr|
        STDOUT.print stdout
        STDERR.print stderr
      end
      file_manager = WinRM::FS::FileManager.new(winrm)
      file_manager.download('C:/Aviva/cis-cat-report.html', 'cis-cat-report.html')
      file_manager.download('C:/Aviva/cis-cat-report.txt', 'cis-cat-report.txt')
      puts "Completed execution of the CIS-CAT test and exited with exit code #{output.exitcode}"
    end
  end

end
