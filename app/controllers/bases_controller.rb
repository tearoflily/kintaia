class BasesController < ApplicationController
  
  def index
    @bases = Base.all
    @base_create = Base.new 
  end
  
  def new
    
  end
  
  def create
  end
  
  def edit
  end
  
  def update
  end
  
  def destroy
  end
  
end