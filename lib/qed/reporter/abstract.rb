module QED
module Reporter

  require 'facets/string'
  require 'ansi/code'

  # = Reporter Absract Base Class
  #
  # Serves as the base class for all other output formats.
  class Abstract

    attr :session

    attr :io

    attr :record

    # TODO: pass session into initialize
    def initialize(options={})
      @io    = options[:io] || STDOUT
      @trace = options[:trace]

      @record = {
        :demo  => [],
        :step  => [],
        :omit  => [],
        :pass  => [],
        :fail  => [],
        :error => []
      }

      #@demos = 0
      #@steps = 0
      #@omit  = []
      #@pass  = []
      #@fail  = []
      #@error = []

      @source = {}
    end

    def demos  ; @record[:demo]  ; end
    def steps  ; @record[:step]  ; end
    def omits  ; @record[:omit]  ; end
    def passes ; @record[:pass]  ; end
    def errors ; @record[:error] ; end
    def fails  ; @record[:fail]  ; end

    #
    def trace?
      @trace
    end

    #
    def update(type, *args)
      __send__("count_#{type}", *args) if respond_to?("count_#{type}")
      __send__("#{type}", *args)
    end

    def self.When(type, &block)
      #raise ArgumentError unless %w{session demo demonstration step}.include?(type.to_s)
      #type = :demonstration if type.to_s == 'demo'
      define_method(type, &block)
    end

    def self.Before(type, &block)
    #  raise ArgumentError unless %w{session demo demonstration step}.include?(type.to_s)
    #  type = :demonstration if type.to_s == 'demo'
      define_method("before_#{type}", &block)
    end

    def self.After(type, &block)
    #  raise ArgumentError unless %w{session demo demonstration step pass fail error}.include?(type.to_s)
    #  type = :demonstration if type.to_s == 'demo'
      define_method("after_#{type}", &block)
    end

    #
    #def Before(type, target, *args)
    #  type = :demonstration if type.to_s == 'demo'
    #  __send__("before_#{type}", target, *args)
    #end

    #
    #def After(type, target, *args)
    #  type = :demonstration if type.to_s == 'demo'
    #  __send__("after_#{type}", target, *args)
    #end

    def count_demo(demo)
      @record[:demo] << demo
    end

    def count_desc(step)
      @record[:step] << step
    end

    def count_code(step)
      @record[:step] << step
    end

    def count_pass(step)
      @record[:pass] << step
    end

    def count_fail(step, exception)
      @record[:fail] << [step, exception]
    end

    def count_error(step, exception)
      @record[:error] << [step, exception]
    end


    # At the start of a session, before running any demonstrations.
    def before_session(session)
      @session    = session
      @start_time = Time.now
    end

    # Beginning of a demonstration.
    def before_demo(demo) #demo(demo)
      #demos << demo
    end

    #
    def load(demo)
    end

    #
    def import(file)
    end

    #def comment(elem)
    #end

    #
    def before_step(step)
      #@steps += 1
    end

    #
    def before_head(step)
    end

    #
    def before_desc(step)
      #steps << step
    end

    #
    def before_data(step)
    end

    # Before running a step that is omitted.
    #def before_omit(step)
    #  @omit << step
    #end

    #
    def before_code(step)
      #steps << step
    end

    # Reight before demo.
    def demo(demo)
    end

    # Right before header.
    def head(step)
    end

    # Right before text section.
    def desc(step)  #text ?
    end

    # Right before date section.
    def data(step)
    end

    # Right before running code.
    def code(step)
    end

    # After running a step that passed.
    def pass(step)
      #@pass << step
    end

    # After running a step that failed.
    def fail(step, assertion)
      #@fail << [step, assertion]
    end

    # After running a step that raised an error.
    def error(step, exception)
      raise exception if $DEBUG  # TODO: do we really want to do it like this?
      #@error << [step, exception]
    end

    #
    def after_data(step)
    end

    #
    def after_code(step)
    end

    #
    def after_desc(step)
    end

    #
    def after_head(step)
    end

    #
    def after_step(step)
    end

    #
    def unload
    end

    # End of a demonstration.
    def after_demo(demo)  #demo(demo)
    end

    # After running all demonstrations. This is the place
    # to output a summary of the session, if applicable.
    def after_session(session)
    end

    # TODO: should we rename b/c of keyword?
    def when(*args)
    end

  private

    def print_time
      io.puts "\nFinished in %.5f seconds.\n\n" % [Time.now - @start_time]
    end

    def print_tally
      assert_count = AE::Assertor.counts[:total]
      assert_fails = AE::Assertor.counts[:fail]
      assert_delta = assert_count - assert_fails

      mask = "%s demos, %s steps: %s failures, %s errors (%s/%s assertions)"
      vars = [demos.size, steps.size, fails.size, errors.size, assert_delta, assert_count] #, @pass.size ]

      io.puts mask % vars 
    end

    #
    INTERNALS = /(lib|bin)[\\\/](qed|ae)/

    #
    def sane_backtrace(exception)
      if trace_count
        clean_backtrace(*exception.backtrace[0, trace_count])
      else
        clean_backtrace(*exception.backtrace)
      end
    end

    #
    def clean_backtrace(*btrace)
      stack = btrace.reject{ |bt| bt =~ INTERNALS } unless $DEBUG
      stack.map do |bt|
        bt.chomp(":in \`__binding__'")
      end
    end

=begin
    # Clean the backtrace of any reference to ko/ paths and code.
    def clean_backtrace(backtrace)
      trace = backtrace.reject{ |bt| bt =~ INTERNALS }
      trace.map do |bt| 
        if i = bt.index(':in')
          bt[0...i]
        else
          bt
        end
      end
    end
=end

    #
    def code_snippet(exception, bredth=3)
      case exception
      when Exception
        backtrace = exception.backtrace.reject{ |bt| bt =~ INTERNALS }.first
      else
        backtrace = exception
      end

      backtrace =~ /(.+?):(\d+(?=:|\z))/ or return ""

      source_file, source_line = $1, $2.to_i

      source = source(source_file)
      
      radius = bredth # number of surrounding lines to show
      region = [source_line - radius, 1].max ..
               [source_line + radius, source.length].min

      # ensure proper alignment by zero-padding line numbers
      format = " %2s %0#{region.last.to_s.length}d %s"

      pretty = region.map do |n|
        format % [('=>' if n == source_line), n, source[n-1].chomp]
      end #.unshift "[#{region.inspect}] in #{source_file}"

      pretty
    end

    # TODO: Call this method in code_snippet.
    def structured_code_snippet(exception, bredth=3)
      case exception
      when Exception
        backtrace = exception.backtrace.reject{ |bt| bt =~ INTERNALS }.first
      else
        backtrace = exception
      end

      backtrace =~ /(.+?):(\d+(?=:|\z))/ or return ""

      source_file, source_line = $1, $2.to_i

      source = source(source_file)
      
      radius = bredth # number of surrounding lines to show
      region = [source_line - radius, 1].max ..
               [source_line + radius, source.length].min

      region.map do |n|
        {n => source[n-1].chomp}
      end
    end

    # Cache the source code of a file.
    #
    # @param file [String] full pathname to file
    #
    # @return [String] source code
    def source(file)
      @source[file] ||= (
        File.readlines(file)
      )
    end

    #
    #
    #--
    # TODO: Show more of the file name than just the basename.
    #++
    def file_and_line(exception)
      case exception
      when Exception
        backtrace = exception.backtrace.reject{ |bt| bt =~ INTERNALS }.first
      when Array
        backtrace = exception.first
      else
        backtrace = exception
      end
      line = backtrace
      return "" unless line
      i = line.rindex(':in')
      line = i ? line[0...i] : line
      #File.basename(line)
      relative_file(line)
    end

    #
    def file_line(exception)
      file, lineno = file_and_line(exception).split(':')
      return file, lineno.to_i
    end

    # Default trace count. This is the number of backtrace lines that
    # will be provided on errors and failed assertions, unless otherwise
    # overridden with ENV['trace'].
    DEFAULT_TRACE_COUNT = 3

    # Looks at ENV['trace'] to determine how much trace output to provide.
    # If it is not set, or set to`false` or `off`, then the default trace count
    # is used. If set to `0`, `true`, 'on' or 'all' then aa complete trace dump
    # is provided. Otherwise the value is converted to an integer and that many
    # line of trace is given.
    #
    # @return [Integer, nil] trace count
    def trace_count
      cnt = ENV['trace']
      case cnt
      when nil, 'false', 'off'
        DEFAULT_TRACE_COUNT
      when 0, 'all', 'true', 'on'
        nil
      else
        Integer(cnt)
      end
    end

    #
    def relative_file(file)
      pwd = Dir.pwd
      idx = (0...pwd.size).find do |i|
        file[i,1] != pwd[i,1]
      end
      file[(idx || 0)..-1]
    end
  end

end
end

