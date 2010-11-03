module QED
module Reporter #:nodoc:

  require 'qed/reporter/abstract'

  # = Verbose ANSI Console Reporter
  #
  class Verbatim < Abstract

    #
    def before_session(session)
      @start_time = Time.now
    end

    #
    def head(step)
      io.print step.text.ansi(:bold)
    end

    #
    def desc(step)
    end

    #
    def data(step)
      io.puts step.clean_text.ansi(:blue)
      io.puts
    end

    #
    def pass(step)
      super(step)
      if step.code?
        io.print "#{step.text}".ansi(:green)
      elsif step.header?
        io.print "#{step.text}".ansi(:bold)
      else
        io.print "#{step.text}"
      end
    end

    #
    def fail(step, error)
      super(step, error)
      txt = step.text.rstrip #.sub("\n",'')
      tab = step.text.index(/\S/)
      io.print "#{txt}\n\n".ansi(:red)
      msg = []
      #msg << ANSI::Code.bold(ANSI::Code.red("FAIL: ")) + error.message
      #msg << ANSI::Code.bold(clean_backtrace(error.backtrace[0]))
      msg << "FAIL: ".ansi(:bold, :red) + error.message #to_str
      msg << clean_backtrace(error.backtrace[0]).ansi(:bold)
      io.puts msg.join("\n").tabto(tab||2)
      io.puts
    end

    #
    def error(step, error)
      super(step, error)
      raise error if $DEBUG
      txt = step.text.rstrip #.sub("\n",'')
      tab = step.text.index(/\S/)
      io.print "#{txt}\n\n".ansi(:red)
      msg = []
      msg << "ERROR: #{error.class} ".ansi(:bold,:red) + error.message #.sub(/for QED::Context.*?$/,'')
      msg << clean_backtrace(error.backtrace[0]).ansi(:bold)
      #msg = msg.ansi(:red)
      io.puts msg.join("\n").tabto(tab||2)
      io.puts
    end

    #def report(str)
    #  count[-1] += 1 unless count.empty?
    #  str = str.chomp('.') + '.'
    #  str = count.join('.') + ' ' + str
    #  puts str.strip
    #end

    #def report_table(set)
    #  puts set.to_yaml.tabto(2).ansi(:magenta)
    #end

    #
    #def macro(step)
    #  #io.puts
    #  #io.puts step.text
    #  io.print "#{step}".ansi(:magenta)
    #  #io.puts
    #end

    #
    def after_session(session)
      print_time
      print_tally
    end

  end

end #module Reporter
end #module QED

