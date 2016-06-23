FactoryGirl.define do
  factory :volunteer do
    sequence(:name) { |n| "John Doe the #{n.ordinalize}" }
    sequence(:email) { |n| "user#{n}@boulderfoodrescue.org" }
    phone "555-555-5555"
    password "SomePassword"

    factory :volunteer_with_assignment do
      after(:create) do |volunteer|
        assignment = create(:assignment, volunteer: volunteer)
        volunteer.assignments << assignment
        volunteer.assigned = true
        volunteer.save
      end
    end

  end
end
