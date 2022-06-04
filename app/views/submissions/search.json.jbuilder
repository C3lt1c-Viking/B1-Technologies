json.array!(@business_infos) do |business_info|
  json.name business_info.classcode + ', ' + business_info.business_type
end
