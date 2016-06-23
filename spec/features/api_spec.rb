require 'spec_helper'
require 'pp'

describe 'api' do
  it 'can sign in' do
    volunteer = create(:volunteer_with_assignment)
    auth_params = get_auth_params(volunteer)
    expect(auth_params["volunteer_token"]).to_not be_nil
  end

  it 'can sign out' do
    volunteer = create(:volunteer_with_assignment)
    auth_params = get_auth_params(volunteer)
    expect(auth_params["volunteer_token"]).to_not be_nil

    delete "/volunteers/sign_out.json", auth_params

    body = JSON.parse(last_response.body)
    body["message"].should eq("Session deleted.")
    last_response.status.should eq(204)

    auth_params2 = get_auth_params(volunteer)
    expect(auth_params2["volunteer_token"]).to_not be_nil
    expect(auth_params2["volunteer_token"]).to_not eq(auth_params["volunteer_token"])
  end

  # GET /logs.json
  it "can get a list of logs" do
    log = create(:log)
    volunteer = create(:volunteer_with_assignment)
    auth_params = get_auth_params(volunteer)
    get "/logs.json", auth_params

    expect(last_response.status).to eq(200)

    logs = JSON.parse(last_response.body)
    logs.should be_an(Array)
    expect(logs.length).to eq(1)
  end

  # GET /logs/:id.json
  it "can look up a log" do
    volunteer = create(:volunteer_with_assignment)
    region = volunteer.assignments.first.region
    log = create(:log, region: region)
    auth_params = get_auth_params(volunteer)
    get "/logs/#{log.id}.json", auth_params
    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    json.should be_an(Hash)
    json["log"]["id"].should eq(log.id)
  end

  # GET /logs/:id/take.json
  it "can cover a shift" do
    volunteer = create(:volunteer_with_assignment)
    region = volunteer.assignments.first.region
    log = create(:log, region: region)
    auth_params = get_auth_params(volunteer)
    get "/logs/#{log.id}/take.json", auth_params
    expect(last_response.status).to eq(200)
    log_2 = Log.find(log.id)
    expect(log_2.volunteers.include?(volunteer)).to eq(true)
  end

  # GET /schedule_chains/:id/take.json
  it "can take a open shift" do
    volunteer = create(:volunteer_with_assignment)
    region = volunteer.assignments.first.region
    schedule_chain = create(:schedule_chain, region: region)
    auth_params = get_auth_params(volunteer)
    get "/schedule_chains/#{s.id}/take.json", auth_params
    expect(last_response.status).to eq(200)
    schedule_chain2 = ScheduleChain.find(schedule_chain.id)
    expect(schedule_chain2.volunteers.include?(volunteer)).to eq(true)
  end

  # PUT /logs/:id.json
  it "can update a log" do
    volunteer = create(:volunteer_with_assignment)
    region = volunteer.assignments.first.region
    log = create(:log, region: region)
    log.volunteers << volunteer
    log.save

    auth_params = get_auth_params(volunteer)
    get "/logs/#{log.id}.json", auth_params
    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    pp json

    json["log_parts"].each{ |i, lp|
      json["log_parts"][i][:weight] = 42.0
      json["log_parts"][i][:count] = 5
    }

    put "/logs/#{log.id}.json", auth_params.merge(json)
    pp last_response.body

    expect(last_response.status).to eq(200)
    check = Log.find(log.id)
    check.complete.should be_true
    check.log_parts.first.weight.should eq(42.0)
    check.log_parts.first.count.should eq(5)
  end

  # GET /locations/:id.json
  it "can look up a donor or recipient" do
    volunteer = create(:volunteer_with_assignment)
    region = volunteer.assignments.first.region
    donor = create(:donor, region: region)
    auth_params = get_auth_params(volunteer)
    get "/locations/#{donor.id}.json", auth_params

    puts last_response.body

    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    json.should be_an(Hash)
  end

  it "will reject an unauthenticated request" do
    create(:log)
    create(:volunteer_with_assignment)
    get "/logs.json"
    expect(last_response.status).to eq(401)
  end


  private

  def get_auth_params(user)
    data = {email: user.email, password: user.password}
    post '/volunteers/sign_in.json', data
    expect(last_response.status).to eq(201)
    json = JSON.parse(last_response.body)
    {"volunteer_token" => json["authentication_token"], "volunteer_email" => user.email }
  end

end
