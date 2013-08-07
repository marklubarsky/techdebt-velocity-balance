# THIS CLASS IS NOT USED ANYMORE AS I REPLACED CSV IMPORT WITH PIVOTAL API

require 'rubygems'
require 'mechanize'
require 'optparse'

class PivotalExporter
  attr_reader :project_id, :file

  USERNAME = 'mark@viralheat.com'

  def initialize(project_id, file)
    @project_id = project_id
    @file = file
  end

  def export
    agent = Mechanize.new
    agent.follow_meta_refresh = true

    page = agent.get("https://www.pivotaltracker.com/projects/#{project_id}")

    sign_in = page.forms.first
    sign_in.field_with(:name => 'credentials[username]').value = USERNAME
    sign_in.field_with(:name => 'credentials[password]').value = PASSWORD
    project_page = agent.submit(sign_in, sign_in.buttons.first)
    project_page = agent.submit(sign_in, sign_in.buttons.first)

    export_page = project_page.link_with(:text => "Export CSV").click
    export_form = export_page.forms.first
    csv = agent.submit(export_form, export_form.buttons.first)
    csv.save_as(file)
  end
end