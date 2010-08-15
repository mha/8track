class Pattern
  
  attr_reader :steps
  attr_accessor :last_step, :current_step
  
  def initialize(num_steps)
    @steps = []
    num_steps.times do
      @steps << Step.new
    end
    
    @current_step = 0
    @last_step = num_steps-1
  end
  
  def inspect
    inspect_str = ""
    step_count = 0
    @steps.length.times do
      if @current_step != step_count
        case @steps[step_count].on?
        when true
          inspect_str += "1"
        else
          inspect_str += "0"
        end
      else
        inspect_str += '.'
      end
      step_count += 1
    end
    
    inspect_str
  end

  def advance_step
    if @current_step >= (@last_step)
      # Reached last step in row
      @current_step = 0
    else
      @current_step += 1
    end
  end
  
  def empty?
    empty = true
    @steps.each do |step|
      if step.on?
        return false
      end
    end
    
    empty
  end
  
  def randomize!
    2.times do
      step_count = 0
      @steps.length.times do
        @steps[step_count].toggle if rand(99) < 50
        step_count += 1
      end
    end
  end
  
  def reset!
    @current_step = 0
  end
end

