
Then /^I should see the "([^\"]*)" section without any ordering links$/ do |section_name|
  row = row_for section_name
  row.should_not have_css("span.moveUp")
  row.should_not have_css("span.moveDown")
end

Then /^I should see the "([^\"]*)" section with(out)? an enabled checkbox$/ do |section_name, without|
  should = without ? :should_not : :should
  row_for(section_name).send(should, have_css("input[id^='sections_'][type='checkbox']"))
end

Then /^I should see "([^\"]*)" with order of "([^\"]*)"$/ do |section_name, form_order|
  #row_for(section_name).find("//span[@class='formSectionOrder']").text.should == form_order
  page.should have_xpath("//table[@id='form_sections']/tbody/tr[#{form_order}]/td/a[text()='#{section_name}']")
end

Then /^I should see the following form sections in this order:$/ do |section_names_table|
  section_names = section_names_table.raw.flatten
  form_section_page.should_list_the_following_sections(section_names)
end

Then /^I should see the description text "([^\"]*)" for form section "([^\"]*)"$/ do |expected_description, form_section|
  form_section_page.section_should_have_description(form_section, expected_description)
end

Then /^I should see the name "([^\"]*)" for form section "([^\"]*)"$/ do |expected_name, form_section|
  row_for(form_section).should have_css("td:nth-child(3)", :text => expected_name)
end

Then /^the form section "([^"]*)" should be listed as (visible|hidden)$/ do |form_section, visibility|
  #within row_xpath_for(form_section) do
  #  page.should have_css("td[3] input", :checked  => (visibility == 'hidden'))
  #end
  checkbox = page.find("//a[@class='formSectionLink' and contains(., '#{form_section}')]/ancestor::tr/td[3]/input[@class='field_hide_show']")
  if visibility == 'hidden'
    checkbox.should be_checked
  else
    checkbox.should_not be_checked
  end
end

When /^I select the form section "([^"]*)" to toggle visibility$/ do |form_section|
  form_section_page.toggle_section_visibility(form_section)
end

Then /^the form section "([^"]*)" should not be selected to toggle visibility$/ do |form_section|
  find_field(form_section_visibility_checkbox_id(form_section)).should_not be_checked
end

Then /^I should not be able to promote the field "([^"]*)"$/ do |field|
  page.should have_selector("//a[@id='#{field}_up' and @style='display: none;']")
end

Then /^I should not be able to demote the field "([^"]*)"$/ do |field|
   page.should have_selector("//a[@id='#{field}_down' and @style='display: none;']")
end

Then /^I should be able to demote the field "([^"]*)"$/ do |field|
  page.should have_selector("//a[@id='#{field}_down' and @style='display: inline;']")
end

When /^I demote field "([^"]*)"$/ do |field|
  ##find(:css, "a##{field}_down").click
  ##drag = page.find("//tr[@data='#{field}']")
  #drag = page.find("//tr[@data='name']")
  #drop = page.find("//tr[@data='second_name']")
  #drag.drag_to(drop)

  #http://your.bucket.s3.amazonaws.com/jquery.simulate.drag-sortable.js
  page.execute_script %{
    $.getScript("https://github.com/mattheworiordan/jquery.simulate.drag-sortable.js/blob/master/jquery.simulate.drag-sortable.js", function() {
      $("tr[data=\'\'#{field}\'\']").simulateDragSortable({ move: 1});
    });}
end

Then /^I should be able to promote the field "([^"]*)"$/ do |field|
 page.should have_selector("//a[@id='#{field}_up' and @style='display: inline;']")
end

Then /^I should not see the "([^\"]*)" arrow for the "([^\"]*)" field$/ do |arrow_name, field_name|
  row = Nokogiri::HTML(page.body).css("##{field_name}Row").first
  row.inner_html.should_not include(arrow_name)
end

Then /^I should see the "([^\"]*)" arrow for the "([^\"]*)" field$/ do |arrow_name, field_name|
  row = Nokogiri::HTML(page.body).css("##{field_name}Row").first
  row.inner_html.should include(arrow_name)
end

And /^I move field "([^\"]*)" up$/ do |field_name|
  page.find(:xpath, "//td[text()=\"#{field_name}\"]/parent::*").find(:css, "a.moveUp").click
end


And /^I move field "([^\"]*)" down$/ do |field_name|
  page.find(:xpath, "//td[text()=\"#{field_name}\"]/parent::*").find(:css, "a.moveDown").click
end

Then /^I should find the form section with following attributes:$/ do |form_section_fields|
  expected_order = form_section_fields.hashes.collect { |section_field| section_field['Name'] }
  actual_order=page.all(:xpath, "//tr[@class='rowEnabled']/td[1]").collect(&:text)
  actual_order.should == expected_order
end

When /^I add a new text field with "([^\"]*)" and "([^\"]*)"$/ do |display_name, help_text|
  form_section_page.create_text_field(display_name, help_text)
end

Then /^I should not see the "([^\"]*)" link for the "([^\"]*)" section$/ do |link, section_name|
  form_section_page.should_not_see_the_manage_fields_link
end

def row_for(section_name)
  page.find row_xpath_for(section_name)
end

def row_xpath_for(section_name)
  "//a[@class='formSectionLink' and contains(., '#{section_name}')]/ancestor::tr"
end

def form_section_visibility_checkbox_id(section_name)
  "sections_#{section_name}"
end

Then /^I land in edit page of form (.+)$/ do  |section_name|
  id = FormSection.all.find { |f| f.name == section_name }.unique_id
  URI.parse(current_url).path.should eq "/form_section/#{id}/edit"
end

When /^I click Cancel$/ do
  click_link('Cancel')
end

Then /^the "([^"]*)" checkbox should be assignable$/ do |field|
  find(:xpath,"//input[@id='#{field}']").should be_checked
end

private

def form_section_page
  FormSectionPage.new(Capybara.current_session)
end