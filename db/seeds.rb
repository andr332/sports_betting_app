# # Create result types if they don't exist
# ResultType.find_or_create_by!(name: 'win')
# ResultType.find_or_create_by!(name: 'lose')
# ResultType.find_or_create_by!(name: 'draw')

# # Seed some example events

# # Upcoming Events
# Event.find_or_create_by!(name: 'Basketball Game') do |event|
#   event.start_time = Time.now + 1.day
#   event.odds = 2.5
#   event.status = 'upcoming'
#   event.result = nil
# end

# Event.find_or_create_by!(name: 'Soccer Match') do |event|
#   event.start_time = Time.now + 2.days
#   event.odds = 1.8
#   event.status = 'upcoming'
#   event.result = nil
# end

# Ongoing Event
Event.find_or_create_by!(name: 'Tennis Tournament') do |event|
  event.start_time = Time.now
  event.odds = 2.2
  event.status = 'ongoing'
  event.result = nil
end
