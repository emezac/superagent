# app/controllers/api/v1/search_controller.rb
class Api::V1::SearchController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_department_access!

  def search
    result = rag_service.departmental_search(
      current_user.department,
      params[:query],
      metadata_filter: search_filters
    )

    render json: {
      answer: extract_answer(result),
      sources: extract_sources(result),
      confidence: calculate_confidence(result)
    }
  rescue => error
    render json: { error: error.message }, status: 500
  end

  def cross_search
    departments = params[:departments] & current_user.accessible_departments
    
    result = rag_service.cross_departmental_search(
      departments,
      params[:query]
    )

    render json: format_cross_search_result(result)
  end

  private

  def rag_service
    Rails.application.config.rag_service
  end

  def search_filters
    filters = {}
    filters["document_type"] = params[:document_type] if params[:document_type].present?
    filters["date_range"] = params[:date_range] if params[:date_range].present?
    filters
  end

  def authorize_department_access!
    unless current_user.can_access_department?(params[:department])
      render json: { error: "Access denied" }, status: 403
    end
  end

  def extract_answer(result)
    result.dig("output", 1, "content", 0, "text")
  end

  def extract_sources(result)
    annotations = result.dig("output", 1, "content", 0, "annotations") || []
    annotations.map { |ann| ann["filename"] }.uniq
  end

  def calculate_confidence(result)
    # Implementar lógica de confianza basada en número de fuentes, etc.
    annotations = result.dig("output", 1, "content", 0, "annotations") || []
    [annotations.length / 5.0, 1.0].min
  end
end
