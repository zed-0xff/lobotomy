module Nanoc3
  class Item
    def writeup?
      if attributes[:categories]
        attributes[:categories].include?('writeup') || attributes[:categories].include?('writeups')
      else
        identifier['writeup']
      end
    end

    def achievement?
      if attributes[:categories]
        attributes[:categories].include?('achievement') || attributes[:categories].include?('achievements')
      else
        identifier['place/']
      end
    end
  end
end
