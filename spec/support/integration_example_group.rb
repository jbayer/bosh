module IntegrationExampleGroup
  def start_sandbox
    puts "Starting sandboxed environment for BOSH tests..."
    Bosh::Spec::Sandbox.start
  end

  def stop_sandbox
    puts "\nStopping sandboxed environment for BOSH tests..."
    Bosh::Spec::Sandbox.stop
    cleanup_bosh
  end

  def reset_sandbox(example)
    desc = example ? example.example.metadata[:description] : ""
    Bosh::Spec::Sandbox.reset(desc)
  end

  def run_bosh(cmd, work_dir = nil)
    Dir.chdir(work_dir || BOSH_WORK_DIR) do
      output = `bosh -n -c #{BOSH_CONFIG} -C #{BOSH_CACHE_DIR} #{cmd}`
      if $?.exitstatus != 0
        puts output
      end
      output
    end
  end

  def run_bosh_cck_ignore_errors(num_errors)
    resolution_selections = "1\n"*num_errors + "yes"
    output = `echo "#{resolution_selections}" | bosh -c #{BOSH_CONFIG} -C #{BOSH_CACHE_DIR} cloudcheck`
    if $?.exitstatus != 0
      puts output
    end
    output
  end

  def self.included(base)
    base.before(:each) do |example|
      unless $sandbox_started
        start_sandbox
        $sandbox_started = true
        at_exit do
          begin
            if $!
              status = $!.is_a?(::SystemExit) ? $!.status : 1
            else
              status = 0
            end
            stop_sandbox
          ensure
            exit status
          end
        end
      end
      reset_sandbox(example)
    end
  end
end
