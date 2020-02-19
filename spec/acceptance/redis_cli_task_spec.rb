require 'spec_helper_acceptance'

describe 'redis-cli task' do
  it 'install redis-cli with the class' do
    pp = <<-EOS
    Exec {
      path => [ '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', ]
    }

    class { '::redis':
      manage_repo => true,
    }
    EOS

    apply_manifest(pp, catch_failures: true)

    # Apply twice to ensure no errors the second time.
    # TODO: not idempotent on Ubuntu 16.04
    unless fact('operatingsystem') == 'Ubuntu' && fact('operatingsystemmajrelease') == '16.04'
      apply_manifest(pp, catch_changes: true)
    end
  end

  describe 'ping' do
    it 'execute ping' do
      result = run_task(task_name: 'redis::redis_cli', params: 'command="ping"')
      expect_multiple_regexes(result: result, regexes: [%r{{"status":"PONG"}}, %r{Ran on 1 node in .+ seconds}])
    end
  end

  describe 'security' do
    it 'stops script injections and escapes' do
      result = run_task(task_name: 'redis::redis_cli', params: 'command="ping; cat /etc/passwd"')
      expect_multiple_regexes(result: result, regexes: [%r!{"status":"ERR unknown command ('|`)ping; cat /etc/passwd('|`)!, %r{Ran on 1 node in .+ seconds}])

      result = run_task(task_name: 'redis::redis_cli', params: 'command="ping && cat /etc/passwd"')
      expect_multiple_regexes(result: result, regexes: [%r!{"status":"ERR unknown command ('|`)ping && cat /etc/passwd('|`)!, %r{Ran on 1 node in .+ seconds}])
    end
  end
end
