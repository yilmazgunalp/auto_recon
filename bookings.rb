require 'csv'
#reads B10 report and  creates a hash of bookings (bookings={}) with selected fields
def booking_list 
bookings = {}
b10=File.open('./data_files/booking_list.csv')

CSV.foreach(b10, {headers: true, skip_blanks: true}) do |line|

#selected fields for a booking
bkg = line["Booking No"].strip.to_sym
pod = line["POD"]
qty = line['Units(Qty.)']
type = line["Container Type"].strip
weight = line["Weight(Gross)"]
cmdty = line["Commodity"]
reefer = line["Reefer"]
temp = line["Temp"]
oog = line["OOG"]
oh = line["OOG Height"]
owr = line["OOG Right Width"]
owl = line["OOG Left Width"]
olf = line["OOG Front Length"]
olb = line["OOG Rear Length"]
haz = line["Hazardous"]

#if bookings hash already have the booking number adds another booking item which is also a hash
  if bookings.has_key?(bkg)
  
	bkg_item = (bookings[bkg].select {|k,v| k.is_a?(Integer)}).keys.max + 1
    bookings[bkg][bkg_item] = {qty: qty, type: type, weight: weight, cmdty: cmdty, reefer?: reefer, 
								temp: temp, oog?: oog, oh: oh, owr: owr, owl: owl, olf: olf,olb: olb, haz?: haz}
		
	if  line.index("HAZ IMO Class")
	bookings[bkg][bkg_item][:haz] = {}
		
	first_imdg = line.index("HAZ IMO Class")

		i = 1	
		while line.index("HAZ IMO Class",first_imdg)
		bookings[bkg][bkg_item][:haz][i] = line.field("HAZ IMO Class",first_imdg)  if (line.field("HAZ IMO Class",first_imdg))
		first_imdg += 4 
		i += 1 
		end
	end
 
 #if not creates a booking with the first booking item numbered as 1 
  else  

  bookings[bkg] = {pod: pod, 1 => {qty: qty, type: type, weight: weight, cmdty: cmdty, reefer?: reefer, 
								temp: temp, oog?: oog, oh: oh, owr: owr, owl: owl, olf: olf,olb: olb, haz?: haz}}
  
	if  line.index("HAZ IMO Class")
	bookings[bkg][1][:haz] = {}
		
	first_imdg = line.index("HAZ IMO Class")

		i = 1
		while line.index("HAZ IMO Class",first_imdg)
		bookings[bkg][1][:haz][i] = line.field("HAZ IMO Class",first_imdg)  if (line.field("HAZ IMO Class",first_imdg))
		
		first_imdg += 4 
		i += 1 
		end
	end
  
    
  end  

end  
bookings
end



