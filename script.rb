require './bookings.rb'
require './booking_item.rb'
require './helper.rb'

bookings = booking_list
booking_objects = {}

file = CSV.table("./data_files/terminal.csv")
#CUSTOMS HELD CONTAINERS
# p file.values_at(:booking_reference_number,:container, :load_hold) {|condition| condition == "HELD"}


CSV.foreach("./data_files/terminal.csv", {headers: true}) do |line| 

bkg_no = line.field("BOOKING REFERENCE NUMBER").to_sym

	if !bookings.has_key?(bkg_no)
	#CONTAINERS WITH NO MATCHING BOOKING
	puts  "#{bkg_no} does not exist" 
	else
	booking_hash = bookings[bkg_no]
	booking_obj =  booking_objects[bkg_no] || Booking.new(booking_hash, bkg_no)
	booking_objects[booking_obj.bkg_no] ||= booking_obj
	
	#CREATE a CONTAINER OBJECT
	container = Container.new(line)
	number =  container.instance_variable_get(:@container)

	#CHECK POD
	# puts "Wrong POD for #{number}"  if container.instance_variable_get(:@portofdischarge) != "PG" + booking_hash[:pod]
	
	#ALLOCATE CONTAINER TO BOOKING
	booking_obj.allocate(container)
		 
	end

end

booking_objects.each_value {|v| v.print}
