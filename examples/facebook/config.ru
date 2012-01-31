require './callback'

use Rack::CommonLogger, STDOUT
use Rack::ShowExceptions

run Callback.new
