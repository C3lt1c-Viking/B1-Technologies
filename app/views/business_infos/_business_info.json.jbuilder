json.extract! business_info, :id, :business_type, :class_code, :created_at, :updated_at
json.url business_info_url(business_info, format: :json)
