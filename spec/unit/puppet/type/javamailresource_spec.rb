require 'spec_helper'

describe Puppet::Type.type(:javamailresource) do

  before :each do
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :providerclass do
    described_class.provide(:fake_customresource_provider) { mk_resource_methods }
  end

  it "should have :name as it's namevar" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :mailhost, :fromaddress, :mailuser, :portbase, :asadminuser, :passwordfile, :user].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
  end
  
  describe "when validating values" do
    describe "for name" do
      it "should support an alphanumerical name" do
        described_class.new(:name => 'test', :ensure => :present)[:name].should == 'test'
      end

      it "should support underscores" do
        described_class.new(:name => 'test_name', :ensure => :present)[:name].should == 'test_name'
      end
   
      it "should support hyphens" do
        described_class.new(:name => 'test-name', :ensure => :present)[:name].should == 'test-name'
      end
      
      it "should support forward-slashes" do
        described_class.new(:name => 'mail/testMail', :ensure => :present)[:name].should == 'mail/testMail'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'test resource', :ensure => :present) }.to raise_error(Puppet::Error, /test resource is not a valid JavaMail resource name./)
      end
    end

    describe "for ensure" do
      it "should support present" do
        described_class.new(:name => 'test', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:name => 'test', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not support other values" do
        expect { described_class.new(:name => 'test', :ensure => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end

      it "should not have a default value" do
        described_class.new(:name => 'test')[:ensure].should == nil
      end
    end

    describe "for properties" do
      it "should support a value" do
        described_class.new(:name => 'test', :properties => 'port=1234',
          :ensure => 'present')[:properties].should == 'port=1234'
      end
    end

    # TODO: Add tests for mailhost, fromaddress and mailuser

    describe "for portbase" do
      it "should support a numerical value" do
        described_class.new(:name => 'test', :portbase => '8000', :ensure => 'present')[:portbase].should == 8000
      end

      it "should have a default value of 4800" do
        described_class.new(:name => 'test', :ensure => 'present')[:portbase].should == 4800
      end

      it "should not support shorter than 4 digits" do
        expect { described_class.new(:name => 'test', :portbase => '123', :ensure => 'present') }.to raise_error(Puppet::Error, /123 is not a valid portbase./)
      end

      it "should not support longer than 5 digits" do
        expect { described_class.new(:name => 'test', :portbase => '123456', :ensure => 'present') }.to raise_error(Puppet::Error, /123456 is not a valid portbase./)
      end

      it "should not support a non-numeric value" do
        expect { described_class.new(:name => 'test', :portbase => 'a', :ensure => 'present') }.to raise_error(Puppet::Error, /a is not a valid portbase./)
      end
    end

    describe "for asadminuser" do
      it "should support an alpha name" do
        described_class.new(:name => 'test', :asadminuser => 'user', :ensure => 'present')[:asadminuser].should == 'user'
      end

      it "should support underscores" do
        described_class.new(:name => 'test', :asadminuser => 'admin_user', :ensure => 'present')[:asadminuser].should == 'admin_user'
      end
   
      it "should support hyphens" do
        described_class.new(:name => 'test', :asadminuser => 'admin-user', :ensure => 'present')[:asadminuser].should == 'admin-user'
      end

      it "should have a default value of admin" do
        described_class.new(:name => 'test', :ensure => 'present')[:asadminuser].should == 'admin'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'test', :asadminuser => 'admin user') }.to raise_error(Puppet::Error, /admin user is not a valid asadmin user name/)
      end
    end
    
    describe "for user" do
      it "should support an alpha name" do
        Puppet.features.expects(:root?).returns(true).once
        described_class.new(:name => 'test', :user => 'glassfish', :ensure => 'present')[:user].should == 'glassfish'
      end

      it "should support underscores" do
        Puppet.features.expects(:root?).returns(true).once
        described_class.new(:name => 'test', :user => 'glassfish_user', :ensure => 'present')[:user].should == 'glassfish_user'
      end
   
      it "should support hyphens" do
        Puppet.features.expects(:root?).returns(true).once
        described_class.new(:name => 'test', :user => 'glassfish-user', :ensure => 'present')[:user].should == 'glassfish-user'
      end

      it "should not have a default value of admin" do
        described_class.new(:name => 'test', :ensure => 'present')[:user].should == nil
      end

      it "should not support spaces" do
        Puppet.features.expects(:root?).returns(true).once
        expect { described_class.new(:name => 'test', :user => 'glassfish user') }.to raise_error(Puppet::Error, /glassfish user is not a valid user name/)
      end
      
      it "should fail if not running as root" do
        Puppet.features.expects(:root?).returns(false).once
        expect { described_class.new(:name => 'test', :user => 'glassfish') }.to raise_error(Puppet::Error, /Only root can execute commands as other users/)
      end
    end
    
    describe "for passwordfile" do
      it "should support a valid file path" do
        File.expects(:exists?).with('/tmp/asadmin.pass').returns(true).once
        described_class.new(:name => 'test', :passwordfile => '/tmp/asadmin.pass')[:passwordfile].should == '/tmp/asadmin.pass'
      end

      it "should fail an invalid file path" do
        File.expects(:exists?).with('/tmp/nonexistent').returns(false).once
        expect { described_class.new(:name => 'test', :passwordfile => '/tmp/nonexistent') }.to raise_error(Puppet::Error, /does not exist/)
      end
    end
  end
  
  describe "when autorequiring" do     
    describe "user autorequire" do
      let :javamailresource do
        described_class.new(
          :name  => 'test',
          :user  => 'glassfish'
        )
      end
      
      # Need to stub user type and provider.
      let :userprovider do
        Puppet::Type.type(:user).provide(:fake_user_provider) { mk_resource_methods }
      end
      
      let :user do
        Puppet::Type.type(:user).new(
          :name   => 'glassfish',
          :ensure => 'present'
        )
      end
      
      let :catalog do
        Puppet::Resource::Catalog.new
      end
  
      # Stub the user type, and expect File.exists? and Puppet.features.root?
      before :each do
        Puppet::Type.type(:user).stubs(:defaultprovider).returns userprovider
        Puppet.features.expects(:root?).returns(true).once
      end
      
      it "should not autorequire a user when no matching user can be found" do
        catalog.add_resource javamailresource
        javamailresource.autorequire.should be_empty
      end
  
      it "should autorequire a matching user" do
        catalog.add_resource javamailresource
        catalog.add_resource user
        reqs = javamailresource.autorequire
        reqs.size.should == 1
        reqs[0].source.ref.should == user.ref
        reqs[0].target.ref.should == javamailresource.ref
      end
    end
    
    describe "domain autorequire" do
      let :javamailresource do
        described_class.new(
          :name  => 'test',
          :user  => 'glassfish'
        )
      end
      
      # Need to stub user type and provider.
      let :domainprovider do
        Puppet::Type.type(:domain).provide(:fake_domain_provider) { mk_resource_methods }
      end
      
      let :domain do
        Puppet::Type.type(:domain).new(
          :domainname   => 'test',
          :ensure       => 'present',
          :passwordfile => '/tmp/password.file',
          :user         => 'glassfish'
        )
      end
      
      let :catalog do
        Puppet::Resource::Catalog.new
      end
    
      # Stub the domain type, and expect File.exists? and Puppet.features.root?
      before :each do
        Puppet::Type.type(:domain).stubs(:defaultprovider).returns domainprovider
        Puppet.features.expects(:root?).returns(true).once
      end
      
      it "should not autorequire a domain when no matching domain can be found" do
        catalog.add_resource javamailresource
        javamailresource.autorequire.should be_empty
      end
    
      it "should autorequire a matching domain" do
        # Expects for domain resource
        Puppet.features.expects(:root?).returns(true).once
        # Create catalogue
        catalog.add_resource javamailresource
        catalog.add_resource domain
        reqs = javamailresource.autorequire
        reqs.size.should == 1
        reqs[0].source.ref.should == domain.ref
        reqs[0].target.ref.should == javamailresource.ref
      end
    end
  end
  
end
