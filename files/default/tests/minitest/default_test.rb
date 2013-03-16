require 'minitest/spec'
require File.expand_path('../support/helpers', __FILE__)

# https://github.com/calavera/minitest-chef-handler/blob/v0.4.0/examples/spec_examples/files/default/tests/minitest/example_test.rb
describe_recipe "asterisk::default" do
  include Helpers

  describe "packages" do
    it "should install the necessary packages" do
      asterisk_packages.each do |package_name|
        package(package_name).must_be_installed
      end

      module_dependencies.each do |package_name|
        package(package_name).must_be_installed
      end
    end

    it "should install the linux kernel headers" do
      package("linux-headers-#{kernel_version}").must_be_installed
    end
  end

  describe "users and groups" do
    it "should create an asteriskpbx user" do
      user(asterisk_user).must_exist
    end

    it "should create an asteriskpbx group" do
      group(asterisk_group).must_exist
    end
    
    it "should place the asteriskpbx user in the asteriskpbx group" do
      group(asterisk_group).must_include(asterisk_user)
    end

    it "should grant sudo privelidges to the asteriskpbx user" do
      file("/etc/sudoers.d/#{asterisk_user}").must_exist.with(:mode, '440')
      file("/etc/sudoers.d/#{asterisk_user}").must_include "%#{asterisk_user} ALL=(ALL) ALL"
    end
  end

  describe "services" do
    it "should start the proper services" do
      %w(ntp dahdi asterisk).each do |srv|
        service(srv).must_be_running
        service(srv).must_be_enabled
      end
    end
  end

  describe "cron tasks" do
  end

  describe "directories" do
    it "should clone the code repositories for asterisk and its dependencies" do
      source_directories.each do |dir|
        directory(dir).must_exist.with(:owner, asterisk_user).and(:group, asterisk_group)
      end
    end

    it "should set the asterisk directory ownership for the asterisk user/group" do
      asterisk_directories.each do |dir|
        directory(dir).must_exist.with(:owner, asterisk_user).and(:group, asterisk_group)
      end
    end
  end

  describe "files" do
    it "should install the sample files to the samples_directory" do
      file("#{samples_directory}/asterisk.conf").must_exist.with(:owner, asterisk_user).and(:group, asterisk_group)
    end

    it "should modify the udev rules to enable MeetMe and Dahdi" do
      udev_data = "SUBSYSTEM==\"dahdi\",  OWNER=\"#{asterisk_user}\", GROUP=\"#{asterisk_group}\", MODE=\"0660\""
      file('/etc/udev/rules.d/dahdi.rules').must_include udev_data
    end
  end

  describe "source installation" do
    it "should install the asterisk module dependencies" do
      file("/var/log/.asterisk-prereqs.installed").must_exist
    end
    
    it "should install libpri" do
      file("/var/log/.asterisk-libpri.installed").must_exist
    end

    it "should install dahdi" do
      file("/var/log/.asterisk-dahdi.installed").must_exist
    end
  end

  describe "security" do
    
    it "should install iptables" do
    end
  end
end
