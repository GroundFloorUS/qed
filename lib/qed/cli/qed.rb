module QED

  require 'qed/session'

  #
  def self.cli(*argv)
    Session.cli(*argv)
  end

  class Session

    #
    def self.cli(*argv)
      require 'optparse'
      require 'shellwords'

      files, options = cli_parse(argv)

      #if files.empty?
      #  puts "No files."
      #  exit -1
      #end

      session = Session.new(files, options)
      success = session.run

      exit -1 unless success
    end

    # Instance of OptionParser
    def self.cli_parse(argv)
      options = {}
      options_parser = OptionParser.new do |opt|
        opt.banner = "Usage: qed [options] <files...>"

        opt.separator("Custom Profiles:") unless settings.profiles.empty?

        settings.profiles.each do |name, value|
          o = "--#{name}"
          opt.on(o, "#{name} custom profile") do
            options[:profile] = name.to_sym
          end
        end

        opt.separator("Report Formats (pick one):")
        #opt.on('--dotprogress', '-d', "use dot-progress reporter [default]") do
        #  options[:format] = :dotprogress
        #end
        opt.on('--verbatim', '-v', "shortcut for verbatim reporter") do
          options[:format] = :verbatim
        end
        opt.on('--tapy', '-y', "shortcut for TAP-Y reporter") do
          options[:format] = :tapy
        end
        #opt.on('--bullet', '-b', "use bullet-point reporter") do
        #  options[:format] = :bullet
        #end
        #opt.on('--html', '-h', "use underlying HTML reporter") do
        #  options[:format] = :html
        #end
        #opt.on('--script', "psuedo-reporter") do
        #  options[:format] = :script  # psuedo-reporter
        #end
        opt.on('--format', '-f FORMAT', "use custom reporter") do |format|
          options[:format] = format.to_sym
        end

        opt.separator("Control Options:")
        opt.on('--comment', '-c', "run comment code") do
          options[:mode] = :comment
        end
        opt.on('--profile', '-p NAME', "load runtime profile") do |name|
          options[:profile] = name
        end
        opt.on('--loadpath', "-I PATH", "add paths to $LOAD_PATH") do |paths|
          options[:loadpath] = paths.split(/[:;]/).map{|d| File.expand_path(d)}
        end
        opt.on('--require', "-r LIB", "require library") do |paths|
          options[:requires] = paths.split(/[:;]/)
        end
        opt.on('--rooted', '-R', "run from project root instead of temporary directory") do
          options[:rooted] = true
        end
        # COMMIT:
        #   The qed command --trace option takes a count.
        #   Use 0 to mean all.
        opt.on('--trace', '-t [COUNT]', "show full backtraces for exceptions") do |cnt|
          #options[:trace] = true
          ENV['trace'] = cnt
        end
        opt.on('--warn', "run with warnings turned on") do
          $VERBOSE = true # wish this were called $WARN!
        end
        opt.on('--debug', "exit immediately upon raised exception") do
          $DEBUG   = true
        end

        opt.separator("Optional Commands:")
        opt.on_tail('--version', "display version") do
          puts "QED #{QED::VERSION}"
          exit
        end
        opt.on_tail('--copyright', "display copyrights") do
          puts "Copyright (c) 2008 Thomas Sawyer, Apache 2.0 License"
          exit
        end
        opt.on_tail('--help', '-h', "display this help message") do
          puts opt
          exit
        end
      end
      options_parser.parse!(argv)
      return argv, options
    end

    # TODO: Pass to Session class, instead of acting global.
    # It is used at the class level to get profiles for the cli.
    def self.settings
      @settings ||= Settings.new
    end

  end

end
