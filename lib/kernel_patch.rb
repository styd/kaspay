module Kernel
  def add__get__to array
    array.map {|el| "get_#{el}".to_sym}
  end
end
