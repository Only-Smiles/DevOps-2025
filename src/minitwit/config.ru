# https://stackoverflow.com/questions/5015471/using-sinatra-for-larger-projects-via-multiple-files
root = ::File.dirname(__FILE__)
require ::File.join(root, 'minitwit')
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter
run MiniTwit.new