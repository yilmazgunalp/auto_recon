class CSV::Table
def values_at(*indices_or_headers,&block) 
  if @mode == :row or  # by indices
     ( @mode == :col_or_row and indices_or_headers.all? do |index|
                                  index.is_a?(Integer)         or
                                  ( index.is_a?(Range)         and
                                    index.first.is_a?(Integer) and
                                    index.last.is_a?(Integer) )
                                end )
    @table.values_at(*indices_or_headers)
  else                 # by headers
    (@table.map { |row| row.values_at(*indices_or_headers) if yield(row.field(*indices_or_headers[-1])) }).compact
  end
end



end


# CONTAINER TYPES

$TYPES = { ["2210","22G0","22G1"] => "20DY", ["2232", "22R0", "22R1"] => "20RF", ["4500", "4510", "45G0", "45G1"] =>  "40HC", 
		["42G0","42G1"] => "40DY", ["22P1", "22P3"] => "20FF", ["22T4","22T5","22T6"] => "20TK",  ["42P1","42P3"] => "40FF", ["42U1"] => "40OT", ["22U1"] => "20OT"}
		
		
		
		
		
def oog_array_match? arr1, arr2
x = 0
y = 0
arr1.each_with_index do |item,i|
x += i if item
end

arr2.each_with_index do |item,i|
y += i if item
end
x == y 
end		