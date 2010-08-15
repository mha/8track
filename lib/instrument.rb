class Instrument

  attr_reader :patterns
  attr_accessor :current_pattern, :current_pattern_num
  
  def initialize(num_patterns, num_steps)
    @patterns = []
    @current_pattern_num = 0

    num_patterns.times do
      @patterns << Pattern.new(num_steps)
    end
    @current_pattern = @patterns.first
  end
  
  def change_pattern(new_pattern, step_position)
    if new_pattern <= @patterns.length
      @current_pattern = @patterns[new_pattern] 
      @current_pattern.current_step = step_position
      @current_pattern_num = new_pattern
    end
  end
  
  def reset_pattern_positions!
    @patterns.each do |pattern|
      pattern.reset!
    end
  end
end
