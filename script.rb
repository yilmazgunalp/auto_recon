require './bookings.rb'
require './booking_item.rb'

bookings = booking_list
booking_objects = {}
File.new('../../Desktop/errors.txt','w') 
recon_file = File.new('../../Desktop/errors.txt','a+')
file = CSV.table("../../Desktop/auto_recon_terminal_list.csv")


no_bookings = []
containers = 0

 
CSV.foreach("../../Desktop/auto_recon_terminal_list.csv", {headers: true}) do |line| 
begin
containers += 1
bkg_no = line.field("BOOKING REFERENCE NUMBER").to_sym

	if !bookings.has_key?(bkg_no)
	#CONTAINERS WITH NO MATCHING BOOKING
	no_bookings << line
	else
	booking_hash = bookings[bkg_no]
	shipper = bookings[bkg_no][:shipper] 
	pod = bookings[bkg_no][:pod] 
	booking_obj =  booking_objects[bkg_no] || Booking.new(booking_hash, bkg_no, shipper,pod)
	booking_objects[booking_obj.bkg_no] ||= booking_obj
	
	#CREATE a CONTAINER OBJECT
	container = Container.new(line)
	number =  container.instance_variable_get(:@container)

	#CHECK POD
	container.errors <<  "Wrong POD. Container booked for #{booking_hash[:pod]}"  if $PORTS[container.instance_variable_get(:@portofdischarge)] !=  booking_hash[:pod]
	
	#ALLOCATE CONTAINER TO BOOKING
	booking_obj.allocate(container)
	
	end
	
rescue => e
write_log "#{e}\t: #{number}"
end	

end




sub_header( "WARNING!!..Program produced errors!!  send 'auto_recon_logs' file to Yilmaz..", recon_file)  if $WITH_ERRORS 


recon_file.puts "\nFound #{containers} containers ...\n\n"
linked_units = 0
booking_objects.each_value do |v| 
linked_units += v.count_units
end
recon_file.puts "Linked #{linked_units} containers ...\n\n"

	# CUSTOMS HELD CONTAINERS
	 holds=  file.values_at_with_condition(:booking_reference_number,:container,:time_in, :load_hold) {|condition| condition == "HELD"}
	if  holds.any?
	 sub_header "customs held containers", recon_file
	 recon_file.puts  "Booking No\tContainer\tTime in\t\tHold"
	
	holds.each do |c|
	c.each {|f| recon_file <<  "#{f}\t" }
	recon_file << "\n\n\n\n"
	end
	end

	#output containers without bookings
	if no_bookings.any?
	sub_header "Containers with no matching bookings", recon_file
	recon_file.puts  "BookingNo\tContainer\tPOD\tFINAL"	
	CSV::Table.new(no_bookings).values_at("BOOKING REFERENCE NUMBER","CONTAINER","PORT OF DISCHARGE","FINAL DESTINATION").each do |c| 
	c.each {|f| recon_file <<  "#{f}\t" }
	recon_file << "\n\n\n\n"
	end
	end		




booking_objects.each_value do |v| 
v.reconcile_items
v.print recon_file
end

