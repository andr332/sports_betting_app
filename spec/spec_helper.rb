RSpec.configure do |config|
  # Minimal logging: Exclude gem and framework-related backtrace from logs
  config.backtrace_exclusion_patterns << /gems/ << /lib\/rspec/ << /lib\/ruby/

  # Use the minimal formatter to show progress with dots
  config.default_formatter = 'progress'

  # Disable full backtrace; show minimal backtrace only for failed examples
  config.full_backtrace = false

  # Randomize test order for dependency detection
  config.order = :random
  Kernel.srand config.seed

  # Enable detailed output only for single file runs
  config.default_formatter = 'doc' if config.files_to_run.one?

  # Verify method existence for mocks
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Enable chaining for custom matchers
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Uncomment to focus on specific examples if needed
  # config.filter_run_when_matching :focus
end
