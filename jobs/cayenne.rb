require 'json'
require 'net/http'

SCHEDULER.every '5s', :first_in => 0 do |job|
  begin
    uri = URI.parse('http://localhost:3000/metrics')
    metrics = JSON.parse(Net::HTTP.get(uri))

    metrics.each_pair do |name, metric_info|
      case metric_info['type']
      when 'meter'
        val = metric_info['rates']['1'].round(2)
        send_event(name, {value: val, current: val})
      when 'gauge'
        send_event(name, {value: metric_info['value'], current: metric_info['value']})
      when 'counter'
        send_event(name, {value: metric_info['value'], current: metric_info['value']})
      when 'histogram'
        send_event(name + '.mean', {current: metric_info['mean']})
        send_event(name + '.min', {current: metric_info['min']})
        send_event(name + '.max', {current: metric_info['max']})
        send_event(name + '.sd', {current: metric_info['standard-deviation']})
      when 'timer'
        send_event(name + '.mean', {current: metric_info['mean']})
        send_event(name + '.min', {current: metric_info['min']})
        send_event(name + '.max', {current: metric_info['max']})
        send_event(name + '.sd', {current: metric_info['standard-deviation']})
        send_event(name, {current: metric_info['rates']['1']})
      end
    end
  rescue StandardError => e
    puts "Failed to get metrics data."
    puts e
  end
end
