require './bookings.rb'
require './booking_item.rb'
require './helper.rb'

bookings = booking_list
booking_objects = {}
output = CSV.open('./output_files/output.csv','a+')

recon_file = File.new('./errors.txt','a+')

file = CSV.table("./data_files/terminal.csv")
#CUSTOMS HELD CONTAINERS
 holds=  file.values_at_with_condition(:booking_reference_number,:container,:time_in, :load_hold) {|condition| condition == "HELD"}
 headers = ["Booking No","Container","Time in","Hold"]
 sub_header "customs held containers", output
 output << headers
holds.each do |container |
row = CSV::Row.new(headers,container)
output << row 
end
output.puts [" "]
no_bookings = []
containers = 0
CSV.foreach("./data_files/terminal.csv", {headers: true}) do |line| 
containers += 1
bkg_no = line.field("BOOKING REFERENCE NUMBER").to_sym

	if !bookings.has_key?(bkg_no)
	#CONTAINERS WITH NO MATCHING BOOKING
	no_bookings << line
	else
	booking_hash = bookings[bkg_no]
	shipper = bookings[bkg_no][:shipper] 
	booking_obj =  booking_objects[bkg_no] || Booking.new(booking_hash, bkg_no, shipper)
	booking_objects[booking_obj.bkg_no] ||= booking_obj
	
	#CREATE a CONTAINER OBJECT
	container = Container.new(line)
	number =  container.instance_variable_get(:@container)

	#CHECK POD
	container.errors <<  "Wrong POD. Container booked for #{booking_hash[:pod]}"  if $PORTS[container.instance_variable_get(:@portofdischarge)] !=  booking_hash[:pod]
	
	#ALLOCATE CONTAINER TO BOOKING
	booking_obj.allocate(container)
	
	end

end

	#output containers without bookings
	headers = ["Booking No","Container","POD","FINAL"]
	sub_header "Containers with no matching bookings", output
	output << headers
	CSV::Table.new(no_bookings).values_at("BOOKING REFERENCE NUMBER","CONTAINER","PORT OF DISCHARGE","FINAL DESTINATION").each {|c| output << c}
puts	
puts " | |\n | |\n | |\n"
puts
recon_file.puts "Found #{containers} containers ..."
booking_objects.each_value do |v| 
v.reconcile_items
v.print recon_file
end


