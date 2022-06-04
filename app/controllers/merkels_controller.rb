class MerkelsController < ApplicationController



  private
  def get_underwritting_question(authenticate_key, classcode)
    require "uri"
    require "net/http"
    url = URI("https://api-sandbox.markelcorp.com/reference/v2/underwritingQuestions?log=GL&classcode=#{classcode}")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["Authorization"] = "Bearer #{authenticate_key}"

    response = https.request(request)
    puts response.read_body
  end
end
