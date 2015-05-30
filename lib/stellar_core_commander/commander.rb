require 'fileutils'
module StellarCoreCommander

  #
  # Commander is the object that manages running stellar-core processes.  It is
  # responsible for creating and cleaning Process objects
  #
  class Commander
    include Contracts

    #
    # Creates a new core commander
    #
    Contract Or["local", "docker"], Hash => Any
    def initialize(process_type, process_options={})
      @process_type = process_type
      @process_options = process_options
      @processes = []
    end

    Contract Symbol => Process
    #
    # make_process returns a new, unlaunched Process object, bound to a new
    # tmpdir
    def make_process(name)
      tmpdir = Dir.mktmpdir("scc")

      identity      = Stellar::KeyPair.random
      base_port     = 39132 + @processes.map(&:required_ports).sum

      process_class = case @process_type
                        when 'local'
                          LocalProcess
                        when 'docker'
                          DockerProcess
                        else
                          raise "Unknown process type: #{@process_type}"
                      end

      process_class.new(tmpdir, name, base_port, identity, @process_options).tap do |p|
        p.setup
        @processes << p
      end
    end

    def cleanup
      @processes.each(&:cleanup)
    end

    def cleanup_at_exit!
      at_exit do
        $stderr.puts "cleaning up #{@processes.length} processes"
        cleanup
      end
    end

  end
end
