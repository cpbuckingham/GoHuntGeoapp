require 'simple_geolocation'

class LocatorsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :new_request

  def index
    x_forwarded_ip = request.env['HTTP_X_FORWARDED_FOR']
    ip = request.remote_ip

    if get_my_location(ip).nil?
      ip = '74.125.113.104'
    end

    remote_ip_location = get_my_location(ip)
    if x_forwarded_ip.present?
      @location = get_my_location(x_forwarded_ip.split(',')[0])
      if @location.nil?
        @location = remote_ip_location
      end
    else
      @location = remote_ip_location
    end
  end

  def new_request
    ip = params[:ip_input]

    @location = get_my_location(ip)

    if @location.nil?
      render :text => 'Invalid IP Address', :status => 400
    else
      render :index
    end
  end

  private

  def get_my_location(ip)
    SimpleGeolocation::Geocoder.new(ip).geocode!
  end
end