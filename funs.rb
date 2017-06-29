def to_csv(x)
	content_type :csv
  attachment "data.csv"
  string = CSV.generate do |csv|
    csv << x.column_names
    x.to_a.each do |h|
      csv << h.attributes.values
    end
  end
end
