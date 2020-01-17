require 'ontologies_api_client'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_global_thread_values

  def set_global_thread_values
    Thread.current[:session] = session
    Thread.current[:request] = request
  end

  def response_errors(error_struct)
    errors = {error: "There was an error, please try again"}
    return errors unless error_struct
    return errors unless error_struct.respond_to?(:errors)
    errors = {}
    error_struct.errors.each {|e| ""}
    error_struct.errors.each do |error|
      if error.is_a?(Struct)
        errors.merge!(struct_to_hash(error))
      else
        errors[:error] = error
      end
    end
    errors
  end
end
