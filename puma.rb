workers 1
threads 2, 8
worker_timeout 30
daemonize
directory File.join(File.dirname(__FILE__), '')
port 8876
stdout_redirect 'log/stdout.log', 'log/stderr.log', true
