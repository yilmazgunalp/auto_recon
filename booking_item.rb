
require_relative  './helpers.rb'


class Booking
attr_accessor :items, :bkg_no, :shipper, :errors, :pod


def initialize booking_hash, bkg_no,shipper, pod
@bkg_no = bkg_no
@shipper = shipper
@errors = []
@pod = pod
new_hash = booking_hash.select { |k,v|  ![:pod,:shipper].include?(k) }
@items = []

new_hash.each do |k,v|
	
	items << BI.new(v)

end
end

def count_units 
i = 0 
items.each do |it|
it.units.each {|u| i+=1 if u.filled?}
end
i
end

def print file
file.puts
file.puts "______________________________________________________"
file.puts ">>>>>>>>>>>> #{bkg_no} : #{shipper.match(/^\w+\s\w+/)} - #{pod} <<<<<<<<<<<<<"
if errors.any?
file.puts"!!!!!!!"
errors.each {|e| file.puts "\t\t\t\t\t\t\t#{e}"} 
file.puts "!!!!!!!"
end
items.each_with_index do |it,i|
file.puts"-------------"
file.puts "Booking ITEM #{i+1}" + " -#{it.cmdty} " ": #{it.units.length} X #{it.type} " 
file.puts "\t\t\t\t\t\t\t"+it.errors.join if it.errors.any?
file.puts"-------------"
it.units.each_with_index do |u,i|
file.puts "Container #{i+1}" + ' : ' + u.box.instance_variable_get(:@container).to_s 
if !u.box.nil? && u.box.errors.any?
puts
file.puts"!!!!!!!"
u.box.errors.each {|e| file.puts "\t\t\t\t\t\t\t#{e}"}
file.puts"!!!!!!!"
puts
end
end
end
file.puts "______________________________________________________"
file.puts
end

def pick_items(array,attribute,compared_to,status=true)
if status
bis = array.select do |bi| 
bi.send(attribute) == compared_to && !bi.filled? 
end
else 
bis = array.select {|bi| bi.send(attribute) == compared_to}
end
end

def reconcile_items 
items.each {|item| item.reconcile_units}
end

###################################################################################################################

# container allocation with multiple lines
def sub_allocate array,attribute,compared_to,container,&block
sub_array = pick_items(array,attribute,compared_to)
				# select the first empty element from Booking Items matching condition
				if !sub_array.empty? 
					sub_array.each do |it|
						if it.first_empty_unit  
						it.first_empty_unit.box = container
						return 
						end
					end
				elsif block_given?
				new_array = yield array
					if !new_array.empty?
						new_array.each do |bi|
								if bi.first_empty_unit  
								bi.first_empty_unit.box = container
								return 
								end
						
						end
					else 
					# select the first empty element from any Booking Item
					array.each do |bi|
							if bi.first_empty_unit  
							bi.first_empty_unit.box = container
							return 
							end
					
					end
										
					end
				#SURPLUS CONTAINER	
				errors << "Surplus Container #{container.instance_variable_get(:@container)}" 
				else
				# select the first empty element from any Booking Item
					array.each do |bi|
							if bi.first_empty_unit  
							bi.first_empty_unit.box = container
							return 
							end
					
					end
				#SURPLUS CONTAINER	
				errors << "Surplus Container #{container.instance_variable_get(:@container)}" 
				end

end


#############################################################################################

	
	class BI 
		attr_accessor :units, :type, :temp, :odims, :oh, :haz, :weight, :errors, :terminal_weight, :cmdty
		def initialize item_hash
		
		@units = []
		@type = $BBLKS.include?(item_hash[:type]) ? "BBLK" : item_hash[:type]
		@temp = item_hash[:temp]
		@odims = [item_hash[:oh], item_hash[:owr], item_hash[:owl], item_hash[:olf], item_hash[:olb]].map! { |e|  e == "0" ? e = nil : (e.to_f*100).to_i.to_s }
		@oh = item_hash[:oh] == "0" ? nil : (item_hash[:oh].to_f*100).to_i.to_s
		@haz = item_hash[:haz].values.uniq.select {|i| !i.strip.empty?}
		@weight = item_hash[:weight].to_i
		@cmdty = item_hash[:cmdty] == "HAZARD " ?  "HAZ" : item_hash[:cmdty]
		
		@terminal_weight = 0
		@errors = []
		item_hash[:qty].to_i.times do 
		units << Unit.new(item_hash)
		end
		
		end
		
		class Unit
		attr_accessor :box, :type, :temp
		def filled?
		true if @box
		end
		def initialize item_hash
		@type = item_hash[:type]
		@temp = item_hash[:temp]
		
		item_hash.each do |k,v|
		instance_variable_set("@"+k.to_s.gsub(/\?/,""),v) unless k == :qty
		end
		end	
		
		end

		def each_empty_unit &block
			@units.each  do |u|  
			yield u  if !u.filled?
			end 
		end
		
		def each_filled_unit &block
			@units.each  do |u|  
			yield u  if u.filled?
			end 
		end
		
	
		def empty_units 
		result = []
		each_empty_unit {|u| result << u}
		result
		end
		
		def first_empty_unit 
		empty_units[0]
		end	
		
		def filled?
		empty_units.empty?
		end
		
		def check_unit u
		number =  u.box.instance_variable_get(:@container)
		temp =  u.box.instance_variable_get(:@reefertemperaturec)
		odims = [u.box.instance_variable_get(:@oogtopcm),u.box.instance_variable_get(:@oogrightcm),u.box.instance_variable_get(:@oogleftcm),
				u.box.instance_variable_get(:@oogfrontcm),u.box.instance_variable_get(:@oogbackcm)]
		oh =  u.box.instance_variable_get(:@oogtopcm)
		haz = u.box.instance_variable_get(:@imdgcodes).split(",") unless u.box.instance_variable_get(:@imdgcodes).nil?
		weight = u.box.instance_variable_get(:@weightkg).sub(',',"").to_i
			case @type
			when "20RF","40RF"
			u.box.errors << "Reefer Temp (#{temp}) doesn't match booking temp: [#{@temp}]" if @temp != temp
			when "20OT","40OT"
			u.box.errors << "OOG dims (#{oh}) doesn't match booking: [#{@oh}]" if @oh != oh
			when "20FF","40FF" 
				u.box.errors << "OOG dims (#{odims}) doesn't match booking: [#{@odims}]" if @odims != odims
			end
			u.box.errors << "Container is not PRAed as HAZ booking : #{@haz} container: #{haz}" if !@haz.empty? && !haz
			
			if (!@haz.empty? && !haz) || (@haz.empty? && haz) || (!@haz.empty? && haz)
			u.box.errors << "HAZ doesn't match " if @haz != haz
			end
			if filled?
				if units.length == 1 && @weight != weight
					u.box.errors << "Amend Booking cargo weight to (#{weight-u.box.tare(@type)})" 
				else
				@terminal_weight += weight
				
				end
			end
		end	
		
		
		def reconcile_units
		each_filled_unit {|u| check_unit u}
		
		errors << "Amend Booking Item cargo weight to (#{@terminal_weight - $TARES[type]*units.length})" if filled? && @terminal_weight != @weight && units.length > 1
		
		
		end
		
	end
	
	
def allocate container
		
		type = container.type(container.instance_variable_get(:@iso))
		number =  container.instance_variable_get(:@container)
		temp =  container.instance_variable_get(:@reefertemperaturec)
		odims = [container.instance_variable_get(:@oogtopcm),container.instance_variable_get(:@oogrightcm),container.instance_variable_get(:@oogleftcm),
				container.instance_variable_get(:@oogfrontcm),container.instance_variable_get(:@oogbackcm)]
		oh =  container.instance_variable_get(:@oogtopcm)
		haz = container.instance_variable_get(:@imdgcodes).split(",") unless container.instance_variable_get(:@imdgcodes).nil?
		bis = pick_items(items,:type,type, false)
		cmdty = container.instance_variable_get(:@commodity)
		
		#CONTAINER TYPE DOESN'T MATCH BOOKING
		errors << "Container type for #{number} is wrong" if bis.empty?
			
		if bis.length == 1
		#SURPLUS CONTAINER
		!bis[0].first_empty_unit ?  errors << "Surplus Container #{number}" : bis[0].first_empty_unit.box = container
		else
			case type
				when "20RF"
				sub_allocate(bis,:temp,temp,container)
				when "20FF", "40FF"
				sub_allocate(bis,:odims,odims,container) {|bis_array| bis_array.select {|item| oog_array_match? item.odims, odims}}
				when "20OT", "40OT"
				sub_allocate(bis,:oh,oh,container)
				when  "20DY","40HC","40DY","BBLK"  
				if cmdty == "HAZ"
				sub_allocate(bis,:haz,haz,container)  {|bis_array| bis_array.select {|item| item.cmdty == "HAZ"}}
				else 
				sub_allocate(bis,:haz,haz,container) {|bis_array| bis_array.select {|item| item.cmdty != "HAZ"}}
				end
			end
			
		end			
	
	end
	

end



class Container 
attr_accessor :errors

def initialize csv_row
	@errors = []
	csv_row.each do |k,v|
	instance_variable_set(("@"+k.gsub(/[\s\.\(\)\/]/,"")).downcase.strip,v)
	end
	
	
end

def type  iso
$TYPES.each_key do |key| 
if key.include?(iso)
	return $TYPES[key]
end
end
write_log "#{iso} ISO CODE NOT FOUND!"
end



def tare type

$TARES[type]


end

end
