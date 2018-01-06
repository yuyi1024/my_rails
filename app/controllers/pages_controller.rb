class PagesController < ApplicationController
  def index
    @students = Student.all
  end

end
