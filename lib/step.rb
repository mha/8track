class Step

  def initialize
    @on = false
    @velocity = false
  end
  
  def inspect
    "State: #{@on} - velocity: #{@velocity}"
  end
  
  def toggle
    case @on
    when true 
      case @velocity
      when false
        @velocity = true
      else
        @on = false
        @velocity = false
      end
    else
      @on = true
      @velocity = false
   end
  end
  
  def on?
    @on
  end
  
  def velocity?
    @velocity
  end
end