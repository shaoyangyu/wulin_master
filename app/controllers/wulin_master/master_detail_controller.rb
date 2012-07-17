module WulinMaster
  class MasterDetailController < ApplicationController
    def get_detail_controller
      render :json => {:status => 'OK', :controller => params[:model].tableize}
    end

    def attach_details
      middle_model = params[:model].classify.constantize
      detail_column = middle_model.reflections[params[:detail_model].to_sym].foreign_key
      params[:detail_ids].each do |detail_id|
        middle_model.create({detail_column => detail_id, params[:master_column] => params[:master_id]})
      end
      render :json => {:status => 'OK', :message => "Attached #{params[:detail_ids].size} records."}
    end
  end
end