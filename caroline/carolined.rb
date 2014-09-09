$ROOT_PATH=ENV['ROOT_PATH']
$: << "#{$ROOT_PATH}/model/"

require 'model.Server.RunCase'

$CAROLINE_PATH="#{$ROOT_PATH}/caroline"
active = true

def clean_exit
  puts "Goodbye, Caroline!"
  if $runCaseServer
    $runCaseServer.clean 
    $runCaseServer=nil
  end
  exit(0)
end

$runCaseServer=RunCaseServer.new

to_run = []
begin
  while active do
    
    next unless active

    begin
      puts "Checking for test scans to be run..."
      runCase=$runCaseServer.getRunCaseFromQueue
      if runCase
        $runCaseServer.ackRunCaseToQueue
        result=$runCaseServer.validate(runCase)
        to_run << runCase if result
      end
    end

    to_run.each do |run| 
      puts "Running scan #{run.id}..."
      Dir.chdir($CAROLINE_PATH) do 
        break unless active
        $runCaseServer.run(run)
        $runCaseServer.saveRunCaseToDB(run,true)
        to_run.delete(run)
      end
    end
  end
rescue => exp
  puts $!
  $stderr.puts "#{exp.backtrace.join("\n")}"
end

clean_exit
