class SubmissionsController < ApplicationController

  def index
    @submissions = Submission.all
  end

  def show
    @submission = Submission.find(params[:id])
    @ifg_result = @submission.ifg_result
    if valid_json?(@ifg_result)
      @ifg_result = JSON.parse @ifg_result
      if @ifg_result["ResponseStatus"]["StatusCode"] == 200
        @policy_id = @ifg_result["PolicyNumber"]
        @final_premium =  @ifg_result["RatingResponse"]["FinalPremium"]
      end
    end

  end

  def new
    @submission = Submission.new
  end

  def edit

  end

  def create
    # binding.pry
    data = submission_form
    type = params[:submission_type]
    @submission = Submission.new(user_id: current_user.id, data: data, submission_type: type)
    respond_to do |format|
      if @submission.save
          authenticate_key = authenticate_merkel
              # binding.pry
          authenticate_key = authenticate_key["access_token"]
          cpp = cpp_merkel(authenticate_key, @submission.data)
          cpp_ifg = cqgl_ifg(@submission.data)
          @submission.update_attribute('markel_results', cpp)
          @submission.update_attribute('ifg_result', cpp_ifg)
          format.html { render :show, flash: 'Submission successfully.'}
      else
        format.html { render :new }
      end
    end
  end


  def form_type
    @type = params[:submission_type]
  end

  private

def valid_json?(json)
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
end
## Mask these fields and we will be good to go! ##
  def submission_form
    {"effective_date"=>params[:effective_date], "expiration_date"=>params[:expiration_date], "class_code"=> params[:class_code], "producer_agency"=>params[:producer_agency], "producer_name"=>params[:producer_name], "behalf_of"=>params[:behalf_of], "producer_email"=>params[:producer_email],  "behalf_email"=>params[:behalf_email], "agency_adr"=>params[:agency_adr], "agency_adr1"=>params[:agency_adr1], "agency_city"=>params[:agency_city], "agency_state"=>params[:agency_state], "agency_zip"=>params[:agency_zip],  "agency_tel"=>params[:agency_tel], "agency_fax"=>params[:agency_fax], "name_insured"=>params[:name_insured], "dba_name"=>params[:dba_name], "url"=>params[:url], "street_address"=>params[:street_address], "address"=>params[:address], "city"=>params[:city], "state"=>params[:state], "zip"=>params[:zip], "loc"=>params[:loc], "building_number"=>params[:building_number], "loc1_adr"=>params[:loc1_adr], "loc1_adr1"=>params[:loc1_adr1], "loc1_city"=>params[:loc1_city], "loc1_state"=>params[:loc1_state], "loc1_zip"=>params[:loc1_zip], "loc1_county"=>params[:loc1_county], "loc1_territory"=>params[:loc1_territory], "description_operations"=>params[:description_operations], "business_entity"=>params[:business_type], "premium_base"=>params[:premium_base], "premium_base_divisor"=>params[:premium_base_divisor], "exposure"=>params[:exposure], "include"=>params[:include], "if_any"=>params[:if_any], "classification_id"=>params[:class_code], "meets_guidelines"=>params[:meets_guidelines], "aie_count"=>params[:aie_count], "blanket_count"=>params[:blanket_count], "lessor_count"=>params[:lessor_count], "primary_count"=>params[:primary_count], "subrogation_count"=>params[:subrogation_count], "subrogation_blanket_count"=>params[:subrogation_blanket_count], "rating_basis"=>params[:rating_basis], "per_occurrence_limit"=>params[:per_occurrence_limit], "personal_advertising_limit"=>params[:personal_advertising_limit], "general_aggregate_limit"=>params[:general_aggregate_limit], "damage_to_rented_premises_limit"=>params[:damage_to_rented_premises_limit], "medical_expense_limit"=>params[:medical_expense_limit], "products_operations_aggregate_limit"=> params[:products_operations_aggregate_limit], "deductible"=>params[:deductible], "deductible_basis"=>params[:deductible_basis], "deductible_type"=>params[:deductible_type], "general_liability_covered"=>params[:general_liability_covered], "agent_adjusted_rate"=>params[:agent_adjusted_rate], "agent_premium_override"=>params[:agent_premium_override], "mp"=>params[:mp], "mga_reference_number"=>params[:mga_reference_number], "retail_agent_company"=>params["retail_agent_company"], "retail_attention"=>params[:retail_attention], "retail_email"=>params[:retail_email], "retail_fax"=>params[:retail_fax], "commission"=>params[:commission], "override_commission"=>params[:override_commission], "nj_broker_num"=>params[:nj_broker_num], "sl_broker_name"=>params[:sl_broker_name], "override_defaults"=>params[:override_defaults], "override_agency_license"=>params[:override_agency_license], "mga_commission_rate"=>params[:mga_commission_rate], "is_verified"=>params[:is_verified], "garrage_territory"=>params[:garrage_territory], "wildfire_hazard"=>params[:wildfire_hazard], "violent_crime_score"=>params[:violent_crime_score], "property_crime_score"=>params[:property_crime_score], "distance_to_coast"=>params[:distance_to_coast], "isanylobinfficlocation"=>params[:isanylobinfficlocation], "contractual_liability_limitation"=>params[:contractual_liability_limitation], "written_contractual_limit"=>params[:written_contractual_limit], "fully_earned"=>params[:fully_earned], "is_minimum_premium"=>params[:is_minimum_premium], "submit_rate"=>params[:submit_rate], "submit_premium"=>params[:submit_premium], "gl_class_override"=>params[:gl_class_override], "gl_class_override_by"=>params[:gl_class_override_by], "producer_id"=>params[:producer_id], "broker_license_num"=>params[:broker_license_num], "agency_license_num"=>params[:agency_license_num]}
  end


  def authenticate_merkel
    require "uri"
    require "net/http"
    url = URI("https://api-sandbox.markelcorp.com/mol/authorization/token?grant_type=password")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = "Basic #{Rails.application.credentials.markel_bearer}"
    request["Content-Type"] = "application/json"
    request.body = "{\n  \"username\": \"#{Rails.application.credentials.markel_username}\",\n  \"password\": \"#{Rails.application.credentials.markel_password}\"\n}"
    response = https.request(request)
    return  JSON.parse response.read_body
  end

  def cpp_merkel(authenticate_key, data)
    # binding.pry

    # Start Common Information #
    policy_effective_date = data["effective_date"]
    policy_effective_date = Chronic.parse(policy_effective_date)
    policy_effective_date = policy_effective_date.strftime("%Y-%m-%d")
    policy_to_date = data["expiration_date"]
    policy_to_date = Chronic.parse(policy_to_date)
    policy_to_date = policy_to_date.strftime("%Y-%m-%d")
    business_type = data["business_type"]
    class_code = data["class_code"]
    # End Common Information #

    # Start Building & Location Information #
    business_location = data["loc"]
    business_street_address = data["loc1_adr"]
    business_city = data["loc1_city"]
    business_state = data["loc1_state"]
    business_zip = data["loc1_zip"]
    insured_state = data["state"]
    business_exposure = data["exposure"]
    # End Building & Location Information #

    # Start Business Information #
    base_advisor = data["premium_base_divisor"]
    meets_eligibile_guidelines = data["guidelines_yes"]
    # End Business Information #

    # Start Business Limitations & Deductibles #
    per_occurrence_limit = data["per_occurrence_limit"]
    per_occurrence_limit =  per_occurrence_limit.to_i * 1000
    general_aggregate_limit = data["general_aggregate_limit"]
    general_aggregate_limit = general_aggregate_limit.to_i
    deductible = data["deductible"]
    # End Business Limitations & Deductibles #

    # "{\n  \"PolicyEffectiveDate\": \"#{policy_effective_date}\",\n  \"PolicyExpirationDate\": \"#{policy_to_date}\",\n  \"HomeState\": \"#{insured_state}\",\n  \"GeneralLiability\": {\n    \"GlRiskUnits\": [\n      {\n        \"GlClassification\": {\n          \"Value\": \"#{class_code}\"\n        },\n        \"Location\": {\n          \"LocationNumber\": \"#{business_location}\",\n          \"Address\": {\n            \"StreetAddress\": \"#{business_street_address}\",\n            \"City\": \"#{business_city}\",\n            \"State\": \"#{business_state}\",\n            \"ZipCode\": \"#{business_zip}\"\n          }\n        },\n        \"GlExposure\": {\n          \"Value\": #{business_exposure.to_i},\n          \"PremiumBase\": {\n            \"IsoStandard\": false,\n            \"ExposureToUnitDivisor\": {\n              \"Value\": #{base_advisor.to_i}\n            },\n            \"Value\": \"Units\"\n          }\n        },\n        \"UnderwritingQuestions\": [\n          {\n            \"AnswerInformation\": {\n              \"Answers\": [\n                {\n                  \"Value\": \"No\"\n                }\n              ]\n            },\n            \"Value\": \"#{business_type}\"\n          },\n          {\n            \"AnswerInformation\": {\n              \"ValueSource\": \"Default\",\n              \"Answers\": [\n                {\n                  \"Value\": \"No\"\n                }\n              ]\n            },\n            \"Value\": \"#{business_type}\"\n          }\n        ]\n      }\n    ],\n    \"GlLimitsAndDeductibles\": {\n      \"PerOccurrenceLimit\": {\n        \"Value\": #{per_occurrence_limit.to_i}\n      },\n      \"GeneralAggregateLimit\": {\n        \"Value\": #{general_aggregate_limit.to_i}\n      },\n      \"Deductible\": {\n        \"Value\":  #{deductible.to_i}\n      }\n    },\n    \"OptionalCoverages\": [\n      {\n        \"Selected\": true,\n        \"CountsTowardMinimumPremium\": false,\n        \"Count\": 0,\n        \"Value\": \"TRIA\"\n      }\n    ],\n    \"UnderwritingQuestions\": [\n      {\n        \"AnswerInformation\": {\n          \"Answers\": [\n            {\n              \"Value\": \"Yes\"\n            }\n          ]\n        },\n        \"Value\": \"MeetsEligibilityGuidelines\"\n      }\n    ]\n  }\n}\n"


    # # Create Quote - General Liablity
    require "uri"
    require "net/http"
    url = URI("https://api-sandbox.markelcorp.com/mol/v2/Submission/Gl")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = "Bearer #{authenticate_key}"
    request["Content-Type"] = "application/json"
      request.body = "{\n  \"PolicyEffectiveDate\": \"#{policy_effective_date}\",\n  \"PolicyExpirationDate\": \"#{policy_to_date}\",\n  \"HomeState\": \"#{insured_state}\",\n  \"Insureds\": {\n    \"PrimaryNamedInsured\": {\n      \"Value\": \"Bob Insured\"\n    }\n  },\n  \"ProducerInformation\": {\n    \"Producer\": {\n      \"Value\": \"{{specifiedProducer}}\"\n    }\n  },\n  \"GeneralLiability\": {\n    \"GlRiskUnits\": [\n      {\n        \"GlClassification\": {\n          \"Value\": \"#{class_code}\"\n        },\n        \"Location\": {\n          \"LocationNumber\": \"#{business_location}\",\n          \"Address\": {\n            \"StreetAddress\": \"#{business_street_address}\",\n            \"StreetAddress2\": \"\",\n            \"City\": \"#{business_city}\",\n            \"State\": \"#{business_state}\",\n            \"ZipCode\": \"#{business_zip}\"\n          }\n        },\n        \"GlExposure\": {\n          \"Value\": #{business_exposure.to_i}\n        }\n      }\n    ],\n    \"GlLimitsAndDeductibles\": {\n      \"PerOccurrenceLimit\": {\n        \"Value\": #{per_occurrence_limit.to_i}\n      },\n      \"GeneralAggregateLimit\": {\n        \"Value\": #{general_aggregate_limit.to_i}\n      },\n      \"ProductsAggregateLimit\": {\n        \"Value\": \"2000000\"\n      },\n      \"Deductible\": {\n        \"Value\":  #{deductible.to_i}\n      }\n    },\n    \"UnderwritingQuestions\": [\n      {\n        \"Value\": \"MeetsEligibilityGuidelines\",\n        \"AnswerInformation\": {\n          \"Answers\": [\n            {\n              \"Value\": \"Yes\"\n            }\n          ]\n        }\n      }\n    ]\n  }\n}"

    response = https.request(request)
    return response.read_body
  end

  def gq_markel(submission_id)
    require "uri"
    require "net/http"
    url = URI("https://api-sandbox.markelcorp.com/mol/v2/Submission/#{submission_id}/QuoteLetter?format=PDF")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = "Bearer fUCGwZST391CHu0truUz108u9PfP"
    response = https.request(request)
    puts response.read_body
  end

  def bind_markel(submission_id, policy_effective_date, policy_number)
    require "uri"
    require "net/http"
    url = URI("https://api-sandbox.markelcorp.com/mol/v2/Submission/#{submission_id}/Bind")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = "Bearer fUCGwZST391CHu0truUz108u9PfP"
    request["Content-Type"] = "application/json"
    request.body = "{\n  \"PolicyEffectiveDate\": \"#{policy_effective_date}\",\n  \"PolicyNumber\": \"#{policy_number}\"\n}"
    response = https.request(request)
    puts response.read_body
  end


  def ip_makel(data)

    policy_id = data[]
    require "uri"
    require "net/http"
    url = URI("https://api-sandbox.markelcorp.com/mol/v2/Policy/12345/Issue")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = "Bearer fUCGwZST391CHu0truUz108u9PfP"
    request["Content-Type"] = "application/json"
    request.body = "{\n  \"PolicyNumber\": \"string\",\n  \"Messages\": [\n    {\n      \"Value\": \"string\",\n      \"MessageType\": \"string\",\n      \"InRe\": 0\n    }\n  ],\n  \"PrimaryNamedInsured\": \"string\",\n  \"TransactionUrl\": \"string\",\n  \"PolicyEffectiveDate\": \"string\",\n  \"PolicyExpirationDate\": \"string\",\n  \"PolicyUrl\": \"string\",\n  \"Status\": \"string\",\n  \"NjslaTransactionNumber\": \"string\"\n}"
    response = https.request(request)
    puts response.read_body
  end



  def lookup_underwritting_ifg()
    #This call will allow you to gather all possible dropdown/option values
    require "uri"
    require "net/http"
    url = URI("https://demoifg.ifgcompanies.com/ExternalUnderwriting/api/LookUpValues/GetLookUpValues")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    response = https.request(request)
    return response.read_body
  end

  def authenticate_ifg()
    # User Producer Information
    require "uri"
    require "net/http"
    url = URI("https://demoifg.ifgcompanies.com/InternalUnderwriting/api/GetIUser")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = "{\n    \"WebUser\": \"ifgapitestuser@ifgcompanies.com\",  \n    \"Password\": \"ifgapitestuser\"\n}"
    response = https.request(request)
    return response.read_body
  end

def cqgl_ifg(data)
  # binding.pry
  # Collect Data from (app -> views -> forms -> _general_liability.html.erb) #
  policy_effective_date = data["effective_date"]
  policy_effective_date = Chronic.parse(policy_effective_date)
  policy_effective_date = policy_effective_date.strftime("%Y-%m-%dT00:00:00")
  policy_to_date = data["expiration_date"]
  policy_to_date = Chronic.parse(policy_to_date)
  policy_to_date = policy_to_date.strftime("%Y-%m-%dT00:00:00")
  class_code = data["class_code"]
  business_operations = data["description_operations"]
  business_type = data["business_entity"]
  insured_name = data["name_insured"]
  insured_address = data["street_address"]
  insured_address2 = data["address"]
  insured_city = data["city"]
  insured_state = data["state"]
  insured_zip = data["zip"]
  producer_id = data["producer_id"]
  doing_business_as = data["dba_name"]
  broker_num = data["broker_license_num"]
  producer_name = data["producer_name"]
  agency_address = data["agency_adr"]
  agency_address1 = data["agency_adr1"]
  agency_city = data["agency_city"]
  agency_state = data["agency_state"]
  agency_zip = data["agency_zip"]
  producer_email = data["producer_email"]
  agency_telephone = data["agency_tel"]
  agency_fax = data["agency_fax"]
  agency_license_number = data["agency_license_num"]
  business_location_number = data["loc"]
  business_building_number = data["building_number"]
  business_address = data["loc1_adr"]
  business_address1 = data["loc1_adr1"]
  business_city = data["loc1_city"]
  business_state = data["loc1_state"]
  business_zip = data["loc1_zip"]
  business_county = data["loc1_county"]
  ocurrence_limits = data["per_occurrence_limit"]
  products_limits = data["products_operations_aggregate_limit"]
  advertising_limits = data["personal_advertising_limit"]
  damages_to_lease_limits = data["damage_to_rented_premises_limit"]
  medical_limits = data["medical_expense_limit"]
  basis_of_deductible = data["deductible_basis"]
  type_of_deductible = data["deductible_type"]
  business_exposure = data["exposure"]
  deductible = data["deductible"]
  meets_guidelines = data["meets_guidelines"]
  mga_referenceNumber = data["mga_reference_number"]
  retail_company = data["retail_agent_company"]
  attention = data["retail_attention"]
  retail_email = data["retail_email"]
  retail_fax = data["retail_fax"]
  commission = data["commission"]
  override_commission = data["override_commission"]
  nj_broker_num = data["nj_broker_num"]
  sl_broker_name = data["sl_broker_name"]
  override_defaults = data["override_defaults"]
  override_agency_license = data["override_agency_license"]
  mga_commission_rate = data["mga_commission_rate"]
  is_verified = data["is_verified"]
  garrage_territory = data["garrage_territory"]
  wildfire_hazard = data["wildfire_hazard"]
  violent_crime_score = data["violent_crime_score"]
  property_crime_score = data["property_crime_score"]
  distance_to_coast = data["distance_to_coast"]
  isanylobinfficlocation = data["isanylobinfficlocation"]
  contractual_liability_limitation = data["contractual_liability_limitation"]
  agent_premium_override = data["agent_premium_override"]
  written_contractual_limit = data["written_contractual_limit"]
  if_any = data["if_any"]
  fully_earned = data["fully_earned"]
  is_minimum_premium = data["is_minimum_premium"]
  classification_id = data["classification_id"]
  submit_rate = data["submit_rate"]
  submit_premium = data["submit_premium"]
  gl_class_override = data["gl_class_override"]
  gl_class_override_by = data["gl_class_override_by"]
  general_liability_covered = data["general_liability_covered"]
  # Create Quote - General Liablity
  require "uri"
  require "net/http"
  url = URI("https://demoifg.ifgcompanies.com/BurlingtonWebAPI/api/Policy/SaveGetPolicy")
  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(url)
  request["Content-Type"] = "application/json"
  request.body =  "{\r\n  \"RequestType\": \"Indication\",\r\n  \"InsuredInformation\": {\r\n    \"Address1\": \"#{insured_address}\",\r\n    \"Address2\": \"#{insured_address2}\",\r\n    \"City\": \"#{insured_city}\",\r\n    \"State\": \"#{insured_state}\",\r\n    \"ZipCode\": \"#{insured_zip}\",\r\n    \"BusinessDescription\": \"Sample business description\",\r\n    \"BusinessEntity\": \"Corporation\"\r\n  },\r\n  \"GeneralInformation\": {\r\n    \"InsuredName\": \"#{insured_name}\",\r\n    \"GoverningState\": \"#{business_state}\",\r\n    \"EffectiveDate\": \"#{policy_effective_date}\",\r\n    \"ExpriationDate\": \"#{policy_to_date}\",\r\n    \"ProducerId\": \"#{producer_id}\",\r\n    \"DoingBusinessAs\": \"#{doing_business_as}\"\r\n  },\r\n  \"AgencyInformation\": {\r\n    \"BrokerLicenseNumber\": \"#{broker_num}\",\r\n    \"ContactName\": \"IFG Testing 1\",\r\n    \"Address1\": \"#{agency_address}\",\r\n    \"Address2\": \"#{agency_address1}\",\r\n    \"City\": \"#{agency_city}\",\r\n    \"State\": \"#{agency_state}\",\r\n    \"ZipCode\": \"#{agency_zip}\",\r\n    \"EmailAddress\": \"#{producer_email}\",\r\n    \"PhoneNumber\": \"#{agency_telephone}\",\r\n    \"FaxNumber\": \"#{agency_fax}\",\r\n    \"AgencyLicenseNumber\": \"#{agency_license_number}\",\r\n    \"MGAReferenceNumber\": \"#{mga_referenceNumber}\",\r\n    \"RetailAgent\": {\r\n      \"CompanyName\": \"#{retail_company}\",\r\n      \"Attention\": \"#{attention}\",\r\n      \"EmailAddress\": \"#{retail_email}\",\r\n      \"FaxNumber\": \"#{retail_fax}\",\r\n      \"Commission\": \"#{commission.to_f}\"\r\n    },\r\n    \"OverrideCommissionRate\": #{override_commission},\r\n    \"NJBrokerLicenseNumber\": \"#{nj_broker_num}\",\r\n    \"SLBrokerFullName\": \"#{sl_broker_name}\",\r\n    \"OverrideDefaults\": #{override_defaults},\r\n    \"OverrideAgencyLicense\": #{override_agency_license},\r\n    \"MGACOMMISSIONRATE\": null\r\n  },\r\n  \"Locations\": [\r\n    {\r\n      \"LocationNumber\": #{business_location_number},\r\n      \"BuildingNumber\": #{business_building_number},\r\n      \"Address1\": \"#{business_address}\",\r\n      \"Address2\": \"#{business_address1}\",\r\n      \"City\": \"#{business_city}\",\r\n      \"State\": \"#{business_state}\",\r\n      \"ZipCode\": \"#{business_zip}\",\r\n      \"County\": \"#{business_county}\",\r\n      \"IsVerified\": #{is_verified},\r\n      \"GarageTerritory\": null,\r\n      \"WildfireHazard\": null,\r\n      \"ViolentCrimeScore\": null,\r\n      \"PropertyCrimeScore\": null,\r\n      \"AIRDistanceToCoast\": null,\r\n      \"IsAnyLOBInFFICLocation\": false\r\n    }\r\n  ],\r\n  \"GeneralLiabilityHeader\": {\r\n    \"EachOccurrenceGeneralAggregate\": \"#{ocurrence_limits}\",\r\n    \"ProductsCompletedOpsAggregate\": \"#{products_limits}\",\r\n    \"PersonalAndAdvertisingInjury\": \"#{advertising_limits}\",\r\n    \"DamageToPremisesRentedToYou\": \"#{damages_to_lease_limits}\",\r\n    \"MedicalExpense\": \"#{medical_limits}\",\r\n    \"ContractualLiabilityLimitation\": \"#{contractual_liability_limitation}\",\r\n    \"DeductibleBasis\": \"#{basis_of_deductible}\",\r\n    \"DeductibleAmount\": \"#{deductible}\",\r\n    \"DeductibleType\": \"#{type_of_deductible}\",\r\n    \"MinimumPremiumOverride\": #{agent_premium_override.to_f},\r\n    \"WrittenContract1mil3mil\": #{written_contractual_limit}\r\n  },\r\n  \"GeneralLiabilityClasses\": [\r\n    {\r\n      \"LocationNumber\": #{business_location_number.to_i},\r\n      \"BuildingNumber\": #{business_building_number.to_i},\r\n      \"ClassCode\": \"#{class_code}\",\r\n      \"Exposure\": #{business_exposure.to_i},\r\n      \"IfAny\": false,\r\n      \"FullyEarned\": false,\r\n      \"IsMinimumPremium\": false,\r\n      \"ClassificationId\": null,\r\n      \"SubmitRate\": null,\r\n      \"SubmitPremium\": null,\r\n      \"GLClassOverride\":  #{gl_class_override.to_i},\r\n      \"GLClassOverrideBy\": #{gl_class_override_by.to_i}\r\n    }\r\n  ],\r\n  \"TriaInformation\": {\r\n    \"GeneralLiabilityCovered\": null\r\n  },\r\n  \"UserName\" : \"ifgapitestuser@ifgcompanies.com\", \r\n  \"Password\" : \"ifgapitestuser\"\r\n}"

  response = https.request(request)
  return response.read_body

end

def gqgl_ifg()
  # Get Quote - General Liability
  require "uri"
  require "net/http"
  url = URI("https://demoifg.ifgcompanies.com/BurlingtonWebAPI/api/Policy/GetPolicy")
  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(url)
  request["Content-Type"] = "application/json"
  request.body = "{\r\n  \"Token\": \"7B71526C807CA86B5073858281\",\r\n  \"UserName\" : \"ifgapitestuser@ifgcompanies.com\", \r\n  \"Password\" : \"ifgapitestuser\"\r\n}\r\n"
  response = https.request(request)
  return response.read_body
end


def gl
{"mp"=>"", "loc"=>"1", "url"=>"none", "zip"=>"75126", "city"=>"Rockwall", "state"=>"TX", "if_any"=>"", "address"=>"None", "include"=>"", "dba_name"=>"Charlies' Air Conditioning", "exposure"=>"31900", "loc1_adr"=>"required true", "loc1_zip"=>"required true", "aie_count"=>"", "behalf_of"=>"Brent", "loc1_adr1"=>"required true", "loc1_city"=>"required true", "agency_adr"=>"510 Turtle Cove", "agency_fax"=>"972-722-3917", "agency_tel"=>"214-405-5497", "agency_zip"=>"75087", "class_code"=>"91255", "commission"=>"10", "deductible"=>"500", "loc1_state"=>"required true", "retail_fax"=>"none", "agency_adr1"=>"Same", "agency_city"=>"Rockwall", "is_verified"=>"true", "loc1_county"=>"Rockwall", "producer_id"=>"1000", "submit_rate"=>"", "agency_state"=>"TX", "behalf_email"=>"brentd@texasspecialty.com", "fully_earned"=>"true", "lessor_count"=>"", "name_insured"=>"Charlie Chan", "premium_base"=>"Payroll", "rating_basis"=>"$50,000/$50,000", "retail_email"=>"csr@sdia.com", "blanket_count"=>"", "nj_broker_num"=>"na", "primary_count"=>"", "producer_name"=>"Brent Davis", "effective_date"=>"2021-02-19", "loc1_territory"=>"", "producer_email"=>"brentd@texasspecialty.com", "sl_broker_name"=>"Texas Specialty Underwriters Inc. ", "street_address"=>"100 Main", "submit_premium"=>"", "building_number"=>"1", "business_entity"=>"Individual", "deductible_type"=>"Property Damage", "expiration_date"=>"2022-02-19", "producer_agency"=>"Stephenson Davis Ins. Agency", "wildfire_hazard"=>"no", "deductible_basis"=>"Per Claim", "meets_guidelines"=>"yes", "retail_attention"=>"", "classification_id"=>"", "distance_to_coast"=>"250", "garrage_territory"=>"01", "gl_class_override"=>"", "override_defaults"=>"true", "subrogation_count"=>"", "agency_license_num"=>"60122", "broker_license_num"=>"60122", "is_minimum_premium"=>"true", "agent_adjusted_rate"=>"0.00", "mga_commission_rate"=>"20", "override_commission"=>"0", "violent_crime_score"=>"no", "gl_class_override_by"=>"", "mga_reference_number"=>"213456", "per_occurrence_limit"=>"$2,000,000", "premium_base_divisor"=>"1000", "property_crime_score"=>"no", "retail_agent_company"=>"Stephenson Davis Ins. Agency", "medical_expense_limit"=>"$10,000", "agent_premium_override"=>"0.00", "description_operations"=>"Air Conditioning Contractor", "isanylobinfficlocation"=>"false", "general_aggregate_limit"=>"1000000/2000000", "override_agency_license"=>"true", "general_liability_covered"=>"Yes", "subrogation_blanket_count"=>"", "written_contractual_limit"=>"false", "personal_advertising_limit"=>"$300,000", "damage_to_rented_premises_limit"=>"$200,000", "contractual_liability_limitation"=>"No", "products_operations_aggregate_limit"=>"$1,000,000"}
end

end
