class CompaniesController < ApplicationController
  before_filter :set_per_page_session
  helper_method :sort_column, :sort_direction
  include CompaniesHelper
  # GET /companies
  # GET /companies.json
  def index
    @companies = current_user.current_account.companies.unarchived.page(params[:page]).per(session["#{controller_name}-per_page"]).order(sort_column + " " + sort_direction)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @companies }
      format.js
    end
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    @company = Company.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/new
  # GET /companies/new.json
  def new
    @company = Company.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/1/edit
  def edit
    @company = Company.find(params[:id])
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = current_user.current_account.companies.new(params[:company])

    respond_to do |format|
      if @company.save
        format.html { redirect_to edit_company_path(@company), notice: 'Company has been created successfully.' }
        format.json { render json: @company, status: :created, location: @company }
      else
        format.html { render action: "new" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /companies/1
  # PUT /companies/1.json
  def update
    @company = Company.find(params[:id])

    respond_to do |format|
      if @company.update_attributes(params[:company])
        format.html { redirect_to edit_company_path(@company), notice: 'Your company has been updated successfully.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company = Company.find(params[:id])
    @company.destroy

    respond_to do |format|
      format.html { redirect_to companies_url }
      format.json { head :no_content }
    end
  end

  def filter_companies
    @companies = Company.filter(params.merge(per: session["#{controller_name}-per_page"], account: current_user.current_account))
    respond_to { |format| format.js }
  end

  def bulk_actions
    result = Services::CompanyBulkActionsService.new(params.merge({current_user: current_user})).perform

    @companies = result[:companies]
    @message = get_intimation_message(result[:action_to_perform], result[:company_ids])
    @action = result[:action]
    respond_to { |format| format.js }
  end

  def undo_actions
    params[:archived] ? Company.recover_archived(params[:ids]) : Company.recover_deleted(params[:ids])
    @companies = current_user.current_account.companies.unarchived.page(params[:page]).per(session["#{controller_name}-per_page"])

    respond_to { |format| format.js }
  end

  private

  def get_intimation_message(action_key, company_ids)
    helper_methods = {archive: 'companies_archived', destroy: 'companies_deleted'}
    helper_method = helper_methods[action_key.to_sym]
    helper_method.present? ? send(helper_method, company_ids) : nil
  end

  def set_per_page_session
    session["#{controller_name}-per_page"] = params[:per] || session["#{controller_name}-per_page"] || 10
  end

  def sort_column
    params[:sort] ||= 'created_at'
  end

  def sort_direction
    params[:direction] ||= 'desc'
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

end
