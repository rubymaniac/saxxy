module Saxxy

  class CallbackArray < Array
    def <<(obj)
      super(obj)
      @add_callback.call(obj) if @add_callback
      self
    end

    def >>(obj)
      delete(obj)
      @remove_callback.call(obj) if @remove_callback
      self
    end

    def on_remove(&block)
      @remove_callback = block
      self
    end

    def on_add(&block)
      @add_callback = block
      self
    end
  end

end
