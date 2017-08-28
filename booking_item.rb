require 'csv'
require './helper.rb'


class Booking
attr_accessor :items, :bkg_no


def initialize booking_hash, bkg_no
@bkg_no = bkg_no
new_hash = booking_hash.select { |k,v|  k != :pod }
@items = []

new_hash.each do |k,v|
	
	items << BI.new(v)

end
end

def count_units 
i = 0 
items.each do |it|
it.units.each {|u| i+=1}
end
i
end

def print
puts "---------------------------------------------"
puts bkg_no
items.each do |it|
puts "-------------"
puts it.to_s + ": Booking Item: -#{it.type} -#{it.haz} " 
puts "-------------"
it.units.each do |u|
p u.to_s + ':' + u.box.instance_variable_get(:@container).to_s 
end
end
puts "---------------------------------------------"
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
				container.errors << "Surplus Container #{container.instance_variable_get(:@container)}" 
				else
				# select the first empty element from any Booking Item
					array.each do |bi|
							if bi.first_empty_unit  
							bi.first_empty_unit.box = container
							return 
							end
					
					end
				#SURPLUS CONTAINER	
				container.errors << "Surplus Container #{container.instance_variable_get(:@container)}" 
				end

end
	
	class BI 
		attr_accessor :units, :type, :temp, :odims, :oh, :haz
		def initialize item_hash
		@units = []
		@type = item_hash[:type]
		@temp = item_hash[:temp]
		@odims = [item_hash[:oh], item_hash[:owr], item_hash[:owl], item_hash[:olf], item_hash[:olb]]
		@oh = item_hash[:oh]
		@haz = item_hash[:haz].values.uniq.select {|i| !i.strip.empty?}
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
		
	end
	
	
	def allocate container
		
		type = container.type(container.instance_variable_get(:@iso))
		number =  container.instance_variable_get(:@container)
		temp =  container.instance_variable_get(:@reefertemperaturec)
		odims = [container.instance_variable_get(:@oogtopcm),container.instance_variable_get(:@oogrightcm),container.instance_variable_get(:@oogleftcm),
				container.instance_variable_get(:@oogbackcm),container.instance_variable_get(:@oogfrontcm)]
		oh =  container.instance_variable_get(:@oogtopcm)
		haz = container.instance_variable_get(:@imdgcodes).split(",") unless container.instance_variable_get(:@imdgcodes).nil?
		bis = pick_items(items,:type,type, false)
		#CONTAINER TYPE DOESN'T MATCH BOOKING
		puts "Container type is wrong for #{number}" if bis.empty?
			
		if bis.length == 1
		#SURPLUS CONTAINER
		!bis[0].first_empty_unit ?  container.errors << "Surplus Container #{number}" : bis[0].first_empty_unit.box = container
		else
			case type
				when "20RF"
				sub_allocate(bis,:temp,temp,container)
				when "20FF" || "40FF" 
				sub_allocate(bis,:odims,odims,container) {|bis_array| bis_array.select {|item| oog_array_match? item.odims, odims}}
				when "20OT" || "40OT"
				sub_allocate(bis,:oh,oh,container)
				when  "20DY" || "40HC" || "40DY"
				sub_allocate(bis,:haz,haz,container)
			end
			
		end			
	puts container.errors
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
puts "#{iso} NOT FOUND!"
end
end


