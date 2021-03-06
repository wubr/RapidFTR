require 'spec_helper'

describe ChildrenHelper, :type => :helper do

  context 'View module' do
    it 'should have PER_PAGE constant' do
      expect(ChildrenHelper::View::PER_PAGE).to eq(20)
    end

    it 'should have MAX_PER_PAGE constant' do
      expect(ChildrenHelper::View::MAX_PER_PAGE).to eq(9999)
    end
  end

  context 'EditView module' do
    it 'should have ONETIME_PHOTOS_UPLOAD_LIMIT constant' do
      expect(ChildrenHelper::EditView::ONETIME_PHOTOS_UPLOAD_LIMIT).to eq(5)
    end
  end

  describe '#thumbnail_tag' do
    it 'should use current photo key if photo ID is not specified' do
      child = stub_model Child, :id => 1001, :current_photo_key => 'current'
      expect(helper.thumbnail_tag(child)).to eq('<img src="/child/1001/thumbnail/current" />')
    end
    it 'should use photo ID if specified' do
      child = stub_model Child, :id => 1001, :current_photo_key => 'current'
      expect(helper.thumbnail_tag(child, 'custom-id')).to eq('<img src="/child/1001/thumbnail/custom-id" />')
    end
  end

  # Delete this example and add some real ones or delete this file
  it 'is included in the helper object' do
    included_modules = (class << helper; self; end).send :included_modules
    expect(included_modules).to include(ChildrenHelper)
  end

  describe '#link_to_update_info' do
    it 'should not show link if child has not been updated' do
      child = Child.new(:age => '27', :unique_identifier => 'georgelon12345', :_id => 'id12345', :created_by => 'jsmith')
      allow(child).to receive(:has_one_interviewer?).and_return(true)
      expect(helper.link_to_update_info(child)).to be_nil
    end

    it 'should show link if child has been updated by multiple people' do
      child = Child.new(:age => '27', :unique_identifier => 'georgelon12345', :_id => 'id12345', :created_by => 'jsmith')
      child.stub :has_one_interviewer? => false, :persisted? => true
      expect(helper.link_to_update_info(child)).to match(/^<a href=.+>and others<\/a>$/)
    end
  end
  describe 'field_for_display' do
    it 'should return the string value where set' do
      expect(helper.field_value_for_display('Foo')).to eq('Foo')
    end
    it 'should return empty string if field is nil or 0 length' do
      expect(helper.field_value_for_display('')).to eq('')
      expect(helper.field_value_for_display(nil)).to eq('')
      expect(helper.field_value_for_display([])).to eq('')
    end
    it 'should comma separate values if field value is an array' do
      expect(helper.field_value_for_display(%w(A B C))).to eq('A, B, C')
    end
  end

  describe '#flag_summary_for_child' do
    it 'should show the flag summary for the child' do
      @current_user = stub_model(User)
      allow(@current_user).to receive(:localize_date).and_return '19 September 2012 at 18:39 (UTC)'

      child = Child.new(:name => 'Flagged Child',
                        :flag_message => 'Fake entity',
                        :histories => [{'datetime' => '2012-09-19 18:39:05UTC', 'changes' => {'flag' => {'to' => 'true'}}, 'user_name' => 'Admin user 1'}])

      helper.stub(:current_user => @current_user)
      expect(helper.strip_tags(helper.flag_summary_for_child(child))).to eq('Flagged By Admin user 1 on 19 September 2012 at 18:39 (UTC) Because Fake entity')
    end
  end

  describe '#order_options_array_from' do
    after :each do
      reset_couchdb!
    end

    it 'should use translated system field names' do
      system_fields = ['created_at']
      options = helper.order_options_array_from system_fields, nil
      expect(options).to include(t('children.order_by.system_fields') => [['Created at', 'created_at']])
    end

    it 'should translate all default and date field names' do
      system_fields = Child.default_child_fields + Child.build_date_fields_for_solar
      options = helper.order_options_array_from system_fields, nil
      expect(options[t('children.order_by.system_fields')].flatten).to_not include(a_string_matching(/translation_missing/))
    end

    it 'should map form fields by display name and name' do
      field = build :field, :name => 'id_name', :display_name => 'display_name'
      form = create :form_section, :name => 'Form to group', :fields => [field]
      options = helper.order_options_array_from nil, [form]
      expect(options['Form to group'].flatten).to include(a_string_matching(/id_name/))
      expect(options['Form to group'].flatten).to include(a_string_matching(/display_name/))
      expect(options['Form to group']).to include(%w(display_name id_name))
    end

    it 'should map multiple forms fields by display name and name' do
      field1 = build :field, :name => 'id_name1', :display_name => 'display_name1'
      form1 = create :form_section, :name => 'First', :fields => [field1]

      field2 = build :field, :name => 'id_name2', :display_name => 'display_name2'
      field3 = build :field, :name => 'id_name3', :display_name => 'display_name3'
      form2 = create :form_section, :name => 'Second', :fields => [field2, field3]

      options = helper.order_options_array_from nil, [form1, form2]
      expect(options['First']).to include(%w(display_name1 id_name1))
      expect(options['Second']).to include(%w(display_name2 id_name2), %w(display_name3 id_name3))

    end

    it 'should combine form fields and system fields' do
      system_fields = ['created_at']
      field = build :field, :name => 'id_name', :display_name => 'display_name'
      form = create :form_section, :name => 'First', :fields => [field]
      form_fields = [form]

      options = helper.order_options_array_from system_fields, form_fields

      expect(options).to eq(t('children.order_by.system_fields') => [['Created at', 'created_at']], 'First' => [%w(display_name id_name)])
    end
  end

  describe '#confirmed_matches_header' do
    it 'should return nil if matches is empty' do
      header = confirmed_matches_header []
      expect(header).to be_nil
    end

    it 'should separate links by commas and spaces' do
      e1 = build(:enquiry, :unique_id => 'id1')
      e2 = build(:enquiry, :unique_id => 'id2')
      m1 = PotentialMatch.new(:enquiry => e1)
      m2 = PotentialMatch.new(:enquiry => e2)
      header = confirmed_matches_header [m1, m2]
      expect(header).to eq("<div class=\"filter_bar\" id=\"match_details\"><h3>Confirmed Matches: " \
                           "<a href=\"/enquiries/#{e1.id}\">#{e1.short_id}</a>" \
                           "<a href=\"/enquiries/#{e2.id}\">, #{e2.short_id}</a></h3></div>")
    end
  end

  describe 'potential match links' do
    let!(:child) { build :child }
    let!(:enquiry) { build :enquiry }
    let!(:potential_match) { PotentialMatch.new(:child => child, :enquiry => enquiry) }

    describe '#mark_as_not_matching_link' do
      it 'should return nil if current child is a confirmed match' do
        expect(mark_as_not_matching_link(child, potential_match, enquiry)).to be_nil
      end

      it 'should return a link if confirmed_match is nil' do
        link = mark_as_not_matching_link(child, nil, enquiry)
        expect(link).to match(/<a data-method=\"delete\"/)
      end

      it 'should return a delete link beginning with |' do
        potential_match = PotentialMatch.new(:child => build(:child), :enquiry => enquiry)
        link = mark_as_not_matching_link child, potential_match, enquiry
        expect(link).to eq("<li id=\"mark_#{child.id}\"> | " \
                           "<a data-method=\"delete\" href=\"/enquiries/#{enquiry.id}/potential_matches/#{child.id}\" "\
                           "rel=\"nofollow\">Mark as not matching</a></li>")
      end

      it 'should return a delete link returning to :child' do
        potential_match = PotentialMatch.new(:child => build(:child), :enquiry => enquiry)
        link = mark_as_not_matching_link child, potential_match, enquiry, :return => :child
        expect(link).to eq("<li id=\"mark_#{child.id}\"> | " \
                           "<a data-method=\"delete\" href=\"/enquiries/#{enquiry.id}/potential_matches/#{child.id}?return=child\" "\
                           "rel=\"nofollow\">Mark as not matching</a></li>")
      end
    end

    describe '#confirm_match_link' do
      it 'should return nil if a confirmed_match exists' do
        expect(confirm_match_link child, child, enquiry).to be_nil
      end

      it 'should return appropriate message if the enquiry is reunited elsewhere' do
        enquiry = double(:reunited_elsewhere? => true)
        link = confirm_match_link child, nil, enquiry
        expect(link).to eq('<li> |  <div class="matched_message">Matched to another Child</div></li>')
      end

      it 'should return appropriate message if the enquiry is confirmed elsewhere' do
        enquiry = double(:confirmed_match => {}, :reunited_elsewhere? => false)
        link = confirm_match_link child, nil, enquiry
        expect(link).to eq('<li> |  <div class="matched_message">Matched to another Child</div></li>')
      end

      it 'should return a put link beginning with |' do
        link = confirm_match_link child, nil, enquiry
        expect(link).to eq("<li id=\"confirm_#{child.id}\"> | " \
                           "<a data-method=\"put\" href=\"/enquiries/#{enquiry.id}/potential_matches/#{child.id}?confirmed=true\" "\
                           "rel=\"nofollow\">Confirm as Match</a></li>")
      end

      it 'should return a put link with options' do
        link = confirm_match_link child, nil, enquiry, :return => :child
        expect(link).to eq("<li id=\"confirm_#{child.id}\"> | " \
                           "<a data-method=\"put\" href=\"/enquiries/#{enquiry.id}/potential_matches/#{child.id}?confirmed=true&amp;return=child\" "\
                           "rel=\"nofollow\">Confirm as Match</a></li>")
      end
    end

    describe '#unconfirm_match_link' do
      it 'should return nil if there is no confirmed match' do
        expect(unconfirm_match_link(child, nil, enquiry)).to be_nil
      end

      it 'should return nil if child isnt the confirmed match' do
        potential_match = PotentialMatch.new(:child => build(:child), :enquiry => enquiry)
        expect(unconfirm_match_link(child, potential_match, enquiry)).to be_nil
      end

      it 'should return nil if enquiry isnt the confirmed match' do
        potential_match = PotentialMatch.new(:child => child, :enquiry => build(:enquiry))
        expect(unconfirm_match_link(child, potential_match, enquiry)).to be_nil
      end

      it 'should return a put link with confirm=false for a child that is the confirmed match' do
        potential_match = PotentialMatch.new(:child => child, :enquiry => enquiry)
        link = unconfirm_match_link child, potential_match, enquiry
        expect(link).to eq("<li id=\"confirm_#{child.id}\"> | " \
                           "<a data-method=\"put\" href=\"/enquiries/#{enquiry.id}/potential_matches/#{child.id}?confirmed=false\" "\
                           "rel=\"nofollow\">Undo Confirmation</a></li>")
      end

      it 'should return a put link with options for a child that is the confirmed match' do
        potential_match = PotentialMatch.new(:child => child, :enquiry => enquiry)
        link = unconfirm_match_link child, potential_match, enquiry, :return => :child
        expect(link).to eq("<li id=\"confirm_#{child.id}\"> | " \
                           "<a data-method=\"put\" href=\"/enquiries/#{enquiry.id}/potential_matches/#{child.id}?confirmed=false&amp;return=child\" "\
                           "rel=\"nofollow\">Undo Confirmation</a></li>")
      end
    end
  end

  describe 'child_title' do
    before :each do
      reset_couchdb!
    end

    it 'should return short id and title field' do
      form = create :form, :name => Child::FORM_NAME
      field = build :field, :name => 'title_field', :title_field => true, :highlighted => true
      create :form_section, :form => form, :fields => [field]
      child = create :child, :title_field => 'Child Title'
      title = child_title child
      expect(title).to eq("Child Title (#{child.short_id})")
    end

    it 'should return short id and multiple title fields' do
      form = create :form, :name => Child::FORM_NAME
      field1 = build :field, :name => 'title_field1', :title_field => true, :highlighted => true
      field2 = build :field, :name => 'title_field2', :title_field => true, :highlighted => true
      create :form_section, :form => form, :fields => [field1, field2]
      child = create :child, :title_field1 => 'ChildTitle1', :title_field2 => 'ChildTitle2'
      title = child_title child
      expect(title).to eq("ChildTitle1 ChildTitle2 (#{child.short_id})")
    end

    it 'should return only short id if no title field' do
      form = create :form, :name => Child::FORM_NAME
      field1 = build :field, :name => 'title_field1', :title_field => true, :highlighted => true
      field2 = build :field, :name => 'title_field2', :title_field => true, :highlighted => true
      create :form_section, :form => form, :fields => [field1, field2]
      child = create :child, :title_field1 => nil, :title_field2 => nil
      title = child_title child
      expect(title).to eq(child.short_id)
    end

    it 'should not have unecessary spaces' do
      form = create :form, :name => Child::FORM_NAME
      field1 = build :field, :name => 'title_field1', :title_field => true, :highlighted => true
      field2 = build :field, :name => 'title_field2', :title_field => true, :highlighted => true
      field3 = build :field, :name => 'title_field3', :title_field => true, :highlighted => true
      create :form_section, :form => form, :fields => [field1, field2, field3]
      child = create :child,
                     :title_field1 => 'ChildTitle1',
                     :title_field2 => nil,
                     :title_field3 => 'ChildTitle3'
      title = child_title child
      expect(title).to eq("ChildTitle1 ChildTitle3 (#{child.short_id})")
    end
  end
end
