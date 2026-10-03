# The class is gone once this file has loaded, so no mutant of it can be
# installed: they come out unviable.
module Outcomes
  class Gone
    def x
      1 + 1
    end
  end

  KEPT = Gone
  remove_const(:Gone)
end
