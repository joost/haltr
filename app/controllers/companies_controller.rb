class CompaniesController < ApplicationController

  unloadable
  menu_item :haltr

  before_filter :project_patch
  before_filter :find_project, :except => [:update]
  before_filter :find_company, :only => [:update]
  before_filter :authorize

  def index
    if @project.company.nil?
      @company = Company.new(:project=>@project)
      @company.save(false)
    else
      @company = @project.company
    end
    render :action => 'edit'
  end

  def update
    if @company.update_attributes(params[:company])
      flash[:notice] = 'Settings successfully updated'
      redirect_to :action => 'index', :id => @project
    else
      render :action => 'edit'
    end
  end

  private

  def find_company
    @company = Company.find params[:id]
    @project = @company.project
  end

  def project_patch
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
  end

end