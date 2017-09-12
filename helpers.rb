require 'csv'

class CSV::Table
def values_at_with_condition(*indices_or_headers,&block) 
  if @mode == :row or  # by indices
     ( @mode == :col_or_row and indices_or_headers.all? do |index|
                                  index.is_a?(Integer)         or
                                  ( index.is_a?(Range)         and
                                    index.first.is_a?(Integer) and
                                    index.last.is_a?(Integer) )
                                end )
    @table.values_at(*indices_or_headers)
  else                 # by headers
	
    (@table.map { |row| row.values_at(*indices_or_headers)  if yield(row.field(*indices_or_headers[-1])) }).compact
end
  
end





end


# GLOBAL VARIABLES

$TYPES = { ["2210","22G0","22G1", "22GI", "20G1"] => "20DY", ["2232", "22R0", "22R1"] => "20RF", ["4500", "4510", "45G0", "45G1"] =>  "40HC", 
		["42G0","42G1"] => "40DY", ["22P1", "22P3"] => "20FF", ["22T4","22T5","22T6"] => "20TK",  ["42P1","42P3"] => "40FF", ["42U1"] => "40OT", 
		["22U1"] => "20OT", ["25G1", "2EG1"] => "20HC", ["BBLK"] => "BBLK" }
		
$PORTS = { "AUBNE" => "BRISBANE", "PGPOM" => "PORT MORESBY", "PGLAE" => "LAE", "PGLNV" => "LIHIR ISLAND" , "SGSIN" => "SINGAPORE", "SBHIR" => "HONIARA", "FJSUV" => "SUVA", 
			"FJLTK" => "LAUTOKA", "VUVLI" => "VILA", "NCNOU" => "NOUMEA", "NCPNY" => "PRONY BAY", "VUSAN" => "SANTO" }		
	
$TARES = { "20DY" => 2230, "20RF" => 3000, "40HC" => 3900, "40DY" => 3900, "20FF" => 2750, "40FF" => 5400, "40OT" => 3800, "20OT" => 2300, "20HC" => 2300, "BBLK" => 0, "20TK" => 4150  }	

$BBLKS = ["UNIT","BUNIT","BPCE","BBDL","BBULK"]	
		
def oog_array_match? arr1, arr2
x = 0
y = 0
arr1.each_with_index do |item,i|
x += i*3+17 if item
end

arr2.each_with_index do |item,i|
y += i*3+17 if item
end
x == y 
end		


def sub_header string, file
file << "********************************************\n"
file << "#{string.upcase}\n"
file << "********************************************\n"
end


#error_log file
File.new('../../Desktop/auto_recon_logs.txt','w')

$WITH_ERRORS = false
def write_log error
log_file = File.new('../../Desktop/auto_recon_logs.txt','a+')
log_file.puts error
$WITH_ERRORS ||= true
end