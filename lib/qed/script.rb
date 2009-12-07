module QED
  require 'yaml'
  require 'facets/dir/ascend'

  require 'ae'

  require 'qed/reporter/dotprogress'
  require 'qed/reporter/summary'
  require 'qed/reporter/verbatim'

  #Assertion   = AE::Assertion
  Expectation = Assertor

  # New Specification
  #def initialize(specs, output=nil)
  #  @specs  = [specs].flatten
  #end

  # = Script
  #
  class Script

    #def self.load(file, output=nil)
    #  new(File.read(file), output)
    #end

    attr :file
    attr :output

    # New Script
    def initialize(file, output=nil)
      @file   = file
      @output = output || Reporter::Verbatim.new #(self)

      source = File.read(file)
      index  = source.rindex('---') || source.size

      @source = source[0...index]
      @helper = source[index+3...-1].to_s.strip
    end

    # File basename less extension.
    def name
      @name ||= File.basename(file).chomp(File.extname(file))
    end

    #def convert
    #  @source.gsub(/^\w/, '# \1')
    #end

    # Run the script.
    def run
      #steps = @source.split(/\n\s*$/)
      eval(@helper, context._binding, @file) if @helper
      steps.each do |step|
        output.report_step(step)
        case step
        when /^[=#]/
          output.report_header(step)
        when /^\S/
          output.report_comment(step)
          context.When.each do |(regex, proc)|
            if md = regex.match(step)
              proc.call(*md[1..-1])
            end
          end
        else
          #if context.table
          #  run_table(step)
          #else
            run_step(step)
          #end
        end
      end
    end

    #
    def run_step(step=nil, &blk)
      context.Before.call if context.Before
      begin
        if blk
          blk.call #eval(step, context._binding)
        else
          eval(step, context._binding, @file) # TODO: would be nice to know file and lineno here
        end
        output.report_pass(step) if step
      rescue Assertion => error
        output.report_fail(step, error)
      rescue Exception => error
        output.report_error(step, error)
      ensure
        context.After.call if context.After
      end
    end

=begin
    #
    def run_table(step)
      file = context.table
      Dir.ascend(Dir.pwd) do |path|
        f1 = File.join(path, file)
        f2 = File.join(path, 'fixtures', file)
        fr = File.file?(f1) ? f1 : File.exist?(f2) ? f2 : nil
        (file = fr; break) if fr
      end
      output.report_pass(step) #step)

      tbl = YAML.load(File.new(file))
      key = tbl.shift
      tbl.each do |set|
        assign = key.zip(set).map{ |k, v| "#{k}=#{v.inspect};" }.join
        run_table_step(assign + step, set)
        #run_step(set.inspect.tabto(4)){ blk.call(set) }
        #@_script.run_step(set.to_yaml.tabto(2)){ blk.call(set) }
        #@_script.output.report_table(set)
      end
      #output.report_pass(step) #step)
      context.table = nil
    end

    #
    #def run_table_step(step, set)
    def run_table_step(set, &blk)
      context.before.call if context.before
      begin
        #eval(step, context._binding, @file) # TODO: would be nice to know file and lineno here
        blk.call(*set)
        output.report_pass('    ' + set.inspect) #step)
      rescue Assertion => error
        output.report_fail(set.inspect, error)
      rescue Exception => error
        output.report_error(set.inspect, error)
      ensure
        context.after.call if context.after
      end
    end
=end

    # Cut-up script into steps.
    def steps
      @steps ||= (
        code  = false
        str   = ''
        steps = []
        @source.each_line do |line|
          if /^\s*$/.match line
            str << line
          elsif /^[=]/.match line
            steps << str #.chomp("\n")
            steps << line #.chomp("\n")
            str = ''
            #str << line
            code = false
          elsif /^\S/.match line
            if code
              steps << str #.chomp("\n")
              str = ''
              str << line
              code = false
            else
              str << line
            end
          else
            if code
              str << line
            else
              steps << str
              str = ''
              str << line
              code = true
            end
          end
        end
        steps << str
        #steps.map{ |s| s.chomp("\n") }
        steps
      )
    end

    # The run context.
    def context
      @context ||= Context.new(self)
    end

  end

  #
  class Context < Module

    TABLE = /^TABLE\[(.*?)\]/i

    def initialize(script)
      @_script = script
      @_when   = []
      @_tables = []
    end

    def _binding
      @_binding ||= binding
    end

    # Before each step.
    def Before(&procedure)
      @_before = procedure if procedure
      @_before
    end

    # After each step.
    def After(&procedure)
      @_after = procedure if procedure
      @_after
    end

    #
    def When(pattern=nil, &procedure)
      return @_when unless procedure
      raise ArgumentError unless pattern
      unless Regexp === pattern
        pattern = __when_string_to_regexp(pattern)
      end
      @_when << [pattern, procedure]
    end

    # Table-based steps.
    def Table(file=nil, &blk)
      file = file || @_tables.last
      tbl = YAML.load(File.new(file))
      tbl.each do |set|
        blk.call(*set)
      end
      @_tables << file
    end

    # Read/Write a fixture.
    def Data(file, &content)
      raise if File.directory?(file)
      if content
        FileUtils.mkdir_p(File.dirname(fname))
        case File.extname(file)
        when '.yml', '.yaml'
          File.open(file, 'w'){ |f| f << content.call.to_yaml }
        else
          File.open(file, 'w'){ |f| f << content.call }
        end
      else
        #raise LoadError, "no such fixture file -- #{fname}" unless File.exist?(fname)
        case File.extname(file)
        when '.yml', '.yaml'
          YAML.load(File.new(file))
        else
          File.read(file)
        end
      end
    end

  private

    def __when_string_to_regexp(str)
      str = str.split(/(\(\(.*?\)\))(?!\))/).map{ |x|
        x =~ /\A\(\((.*)\)\)\z/ ? $1 : Regexp.escape(x)
      }.join
      str = str.gsub(/(\\\ )+/, '\s+')
      Regexp.new(str, Regexp::IGNORECASE)

      #rexps = []
      #str = str.gsub(/\(\((.*?)\)\)/) do |m|
      #  rexps << '(' + $1 + ')'
      #  "\0"
      #end
      #str = Regexp.escape(str)
      #rexps.each do |r|
      #  str = str.sub("\0", r)
      #end
      #str = str.gsub(/(\\\ )+/, '\s+')
      #Regexp.new(str, Regexp::IGNORECASE)
    end

    # 
    # check only local and maybe start paths
    #def __locate_file(file)
    #  Dir.ascend(Dir.pwd) do |path|
    #    f1 = File.join(path, file)
    #    f2 = File.join(path, 'fixtures', file)
    #    fr = File.file?(f1) ? f1 : File.exist?(f2) ? f2 : nil
    #    (file = fr; break) if fr
    #  end
    #end

  end

end

